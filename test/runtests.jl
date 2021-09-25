using SoapySDR
using Test
using Unitful
using Unitful.DefaultSymbols
const dB = u"dB"
using Intervals

const sd = SoapySDR

const hardware = "loopback"

# Load dummy test harness or hardware
if hardware == "loopback"
    # build SoapyLoopback and dlopen it
    include("setup_loopback.jl")
elseif hardware == "rtlsdr"
    using SoapyRTLSDR_jll
else
    error("unknown test hardware")
end


@testset "SoapySDR.jl" begin
@testset "Ranges/Display" begin
    intervalrange = sd.SoapySDRRange(0, 1, 0)
    steprange = sd.SoapySDRRange(0, 1, 0.1)

    intervalrangedb = sd._gainrange(intervalrange)
    steprangedb = sd._gainrange(steprange) #TODO

    intervalrangehz = sd._hzrange(intervalrange)
    steprangehz = sd._hzrange(steprange)

    hztype = typeof(1.0*Hz)

    @test typeof(intervalrangedb) == Interval{Gain{Unitful.LogInfo{:Decibel, 10, 10}, :?, Float64}, Closed, Closed}
    @test typeof(steprangedb) == Interval{Gain{Unitful.LogInfo{:Decibel, 10, 10}, :?, Float64}, Closed, Closed}
    @test typeof(intervalrangehz) == Interval{hztype, Closed, Closed}
    @test typeof(steprangehz) == StepRangeLen{hztype, Base.TwicePrecision{hztype}, Base.TwicePrecision{hztype}}

    io = IOBuffer(read=true, write=true)

    sd.print_hz_range(io, intervalrangehz)
    @test String(take!(io)) == "00..0.001 kHz"
    sd.print_hz_range(io, steprangehz)
    @test String(take!(io)) == "00 Hz:0.0001 kHz:0.001 kHz"
end
@testset "High Level API" begin

    io = IOBuffer(read=true, write=true)

    # Device constructor, show, iterator
    @test length(Devices()) == 1
    show(io, Devices())
    dev = Devices()[1]
    show(io, dev)
    for dev in Devices()
        show(io, dev)
    end
    @test typeof(dev) == sd.Device
    @test typeof(dev.info) == sd.OwnedKWArgs
    @test dev.driver == :LoopbackDriver
    @test dev.hardware == :LoopbackHardware
    @test dev.timesources == SoapySDR.TimeSource[:sw_ticks,:hw_ticks] 
    @test dev.timesource == SoapySDR.TimeSource(:sw_ticks)
    dev.timesource = "hw_ticks"
    @test dev.timesource == SoapySDR.TimeSource(:hw_ticks)

    # Channels
    rx_chan_list = dev.rx
    tx_chan_list = dev.tx
    @test typeof(rx_chan_list) == sd.ChannelList
    @test typeof(tx_chan_list) == sd.ChannelList
    show(io, rx_chan_list)
    show(io, tx_chan_list)
    rx_chan = dev.rx[1]
    tx_chan = dev.tx[1]
    @test typeof(rx_chan) == sd.Channel
    @test typeof(tx_chan) == sd.Channel
    show(io, rx_chan)
    show(io, tx_chan)
    show(io, MIME"text/plain"(), rx_chan)
    show(io, MIME"text/plain"(), tx_chan)

    #channel set/get properties
    @test rx_chan.native_stream_format == SoapySDR.ComplexInt{12} #, fullscale
    @test rx_chan.stream_formats == [Complex{Int8}, SoapySDR.ComplexInt{12}, Complex{Int16}, ComplexF32]
    @test tx_chan.native_stream_format == SoapySDR.ComplexInt{12} #, fullscale
    @test tx_chan.stream_formats == [Complex{Int8}, SoapySDR.ComplexInt{12}, Complex{Int16}, ComplexF32]

    # channel gain tests
    @test rx_chan.gain_mode == false
    rx_chan.gain_mode = true
    @test rx_chan.gain_mode == true

    @test rx_chan.gain_elements == SoapySDR.GainElement[:IF1, :IF2, :IF3, :IF4, :IF5, :IF6, :TUNER]
    if1 = rx_chan.gain_elements[1]
    @show rx_chan[if1]
    rx_chan[if1] = 0.5u"dB"
    @test rx_chan[if1] == 0.5u"dB"

    #@show rx_chan.gain_profile
    @show rx_chan.frequency_correction

    #@test tx_chan.bandwidth == 2.048e6u"Hz"
    #@test tx_chan.frequency == 1.0e8u"Hz"
    #@test tx_chan.gain == -53u"dB"
    #@test tx_chan.sample_rate == 2.048e6u"Hz"

    # setter/getter tests
    rx_chan.sample_rate = 1e5u"Hz"
    #@test rx_chan.sample_rate == 1e5u"Hz"


    rx_stream = sd.Stream(ComplexF32, [rx_chan])
    @test typeof(rx_stream) == sd.Stream{ComplexF32}
    tx_stream = sd.Stream(ComplexF32, [tx_chan])
    @test typeof(tx_stream) == sd.Stream{ComplexF32}

    rx_stream = sd.Stream([rx_chan])
    @test typeof(rx_stream) == sd.Stream{sd.ComplexInt{12}}
    tx_stream = sd.Stream([tx_chan])
    @test typeof(tx_stream) == sd.Stream{sd.ComplexInt{12}}
end
end
