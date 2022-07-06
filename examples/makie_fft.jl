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
# using SoapyRTLSDR_jll
# using SoapyPlutoSDR_jll
# using SoapyUHD_jll

include("highlevel_dump_devices.jl")

get_time_ms() = trunc(Int, time() * 1000)

function makie_fft()
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

    # Enable ther stream
    @info "streaming..."
    SoapySDR.activate!(rxStream)
    while true
        @timeit to "Reading stream" read!(rxStream, (buff, ))
        @timeit to "Copying FFT data" storeFft[][2:end, :] .= storeFft[][1:end-1, :]
        @timeit to "FFT" storeFft[][1,:] = 20 .*log10.(abs.(fftshift(fft_plan_a*buff)))[1:decimator_factor:end]
        @timeit to "Plotting" begin 
            if get_time_ms() - last_plot > 100 # 10 fps
                storeFft[] = storeFft[]
                last_plot = get_time_ms()
            end
        end
        @timeit to "Timer Display" begin
            if get_time_ms() - last_timeoutput > 3000
                show(to)
                last_timeoutput = get_time_ms()
            end
        end
        @timeit to "GC" begin
            GC.gc(false)
        end
        sleep(0.01) # give some time for Makie event handlers
    end
end

makie_fft()