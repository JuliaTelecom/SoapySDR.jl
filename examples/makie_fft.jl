using Printf
using FFTW
using GLMakie
using DSP
using SoapySDR
using Unitful
using TimerOutputs
using Observables

# Don't forget to add/import a device-specific plugin package!
# using xtrx_jll
# using SoapyLMS7_jll
using SoapyRTLSDR_jll
# using SoapyPlutoSDR_jll
# using SoapyUHD_jll

include("highlevel_dump_devices.jl")

get_time_ms() = trunc(Int, time() * 1000)

function makie_fft(direct_buffer_access=true, timer_display=false)
    devs = Devices()

    sdr = Device(devs[1])

    rx1 = sdr.rx[1]

    sampRate = 2.048e6

    rx1.sample_rate = sampRate*u"Hz"

    # Enable automatic Gain Control
    rx1.gain_mode = true

    to = TimerOutput()

    f0 = 104.1e6

    rx1.frequency = f0*u"Hz"

    # set up a stream (complex floats)
    format = rx1.native_stream_format
    rxStream = SoapySDR.Stream(format, [rx1])

    # create a re-usable buffer for rx samples
    buffsz = rxStream.mtu
    buff = Array{format}(undef, buffsz)
    buffs = Ptr{format}[C_NULL] # pointer for direct buffer API

    # receive some samples
    timeS = 10
    timeSamp = Int(floor(timeS * sampRate / buffsz))
    decimator_factor = 16

    storeFft = Observable(zeros(timeSamp, div(buffsz, decimator_factor)))

    @info "initializing plot..."
    fig = heatmap(storeFft)

    display(fig)

    @info "planning fft..."
    fft_plan_a = plan_fft(buff)
    last_plot = get_time_ms()
    last_timeoutput = get_time_ms()


    # If there is timing slack, we can sleep a bit to run event handlers
    have_slack = true

    # Enable ther stream
    @info "streaming..."
    SoapySDR.activate!(rxStream)
    while true
        @timeit to "Reading stream" begin
            if !direct_buffer_access
                read!(rxStream, (buff, ))
            else
                err, handle, flags, timeNs = SoapySDR.SoapySDRDevice_acquireReadBuffer(sdr, rxStream, buffs, 0)
                if err == SoapySDR.SOAPY_SDR_TIMEOUT
                    sleep(0.001)
                    have_slack = true
                    continue # we don't have any data available yet, so loop
                elseif err == SoapySDR.SOAPY_SDR_OVERFLOW
                    have_slack = false
                    err = buffsz # nothing to do, should be the MTU
                end
                @assert err > 0
                buff = unsafe_wrap(Array{format}, buffs[1], (buffsz,))
                SoapySDR.SoapySDRDevice_releaseReadBuffer(sdr, rxStream, handle)
            end
        end
        @timeit to "Copying FFT data" storeFft[][2:end, :] .= storeFft[][1:end-1, :]
        @timeit to "FFT" storeFft[][1,:] = 20 .*log10.(abs.(fftshift(fft_plan_a*buff)))[1:decimator_factor:end]
        @timeit to "Plotting" begin 
            if have_slack && get_time_ms() - last_plot > 100 # 10 fps
                storeFft[] = storeFft[]
                last_plot = get_time_ms()
            end
        end
        if have_slack && timer_display
            @timeit to "Timer Display" begin
                if get_time_ms() - last_timeoutput > 3000
                    show(to)
                    last_timeoutput = get_time_ms()
                end
            end
        end
        @timeit to "GC" begin
            have_slack && GC.gc(false)
        end
        have_slack && sleep(0.01) # give some time for Makie event handlers
    end
end

makie_fft()