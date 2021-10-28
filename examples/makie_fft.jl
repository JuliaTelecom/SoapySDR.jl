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
    rx_stream = SoapySDR.Stream(ComplexF32, [rx_chan])
    @show rx_stream.mtu
    buf = Vector{ComplexF32}(undef, rx_stream.mtu)
    @show typeof(fft)
    norms = Observable(Vector{Float32}(undef,length(buf)))

    println("Makie Setup...")
    fig = Figure(); display(fig)
    ax = Axis(fig[1,1])
    lines!(ax, norms)
    println("Starting fft loop..")
    Base.atexit(()->SoapySDR.deactivate!(rx_stream))

    SoapySDR.activate!(rx_stream)
    while true
        read!(rx_stream, (buf,))
        println("read")
        FFTW.fft!(buf)
        println("fft")
        norms[] = norm.(buf)
        println("norm")
        norms[] = norms[]
        # sanity checks?
        #nequal = 0
        #for i in eachindex(current_buff.bufs)
        #    nequal += Int(current_buff.bufs[1][i] == prev_buff.bufs[1][i])
        #end
        #@show current_buff.timens
        #@show nequal, current_buff.timens, delta_t
    end

end