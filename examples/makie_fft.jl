using Revise
using SoapySDR, SoapyPlutoSDR_jll
using GLMakie
using LinearAlgebra
using FFTW
# Here we want to test the behavior in a loop, to ensure
# that we can block on buffer overflow conditions, and
# handle partial reads, measure latnecy, etc

freq = 104.3e6u"Hz"

function rapid_read(freq=freq)
    dev = Devices()[1]
    rx_chan = dev.rx[1]
    @show rx_chan
    rx_chan.gain_mode = true
    rx_chan.frequency = freq
    rx_stream = SoapySDR.Stream([rx_chan])
    @show rx_stream.mtu
    buf = SoapySDR.SampleBuffer(rx_stream, 10^6)

    fft = Vector{Complex{Float64}}(undef, length(buf[1]))
    @show typeof(fft)
    norms = Vector{Float64}(undef,length(fft))
    while true

        read!(rx_stream, buf, activate=false, deactivate=false)
        for i in eachindex(buf[1])
            fft[i] = convert(Complex{Float64}, buf[1][i])
        end
        FFTW.fft!(fft)
        for i in eachindex(fft)
            norms[i] = norm(fft[i])
        end
        fig, ax = lines(norms)
        display(fig)
        # sanity checks?
        #nequal = 0
        #for i in eachindex(current_buff.bufs)
        #    nequal += Int(current_buff.bufs[1][i] == prev_buff.bufs[1][i])
        #end
        #@show current_buff.timens
        #@show nequal, current_buff.timens, delta_t
    end

end