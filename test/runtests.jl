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

    #channel set/get properties
    @test rx_chan.native_stream_format == SoapySDR.ComplexInt{12} #, fullscale
    @test rx_chan.stream_formats == [Complex{Int8}, SoapySDR.ComplexInt{12}, Complex{Int16}, ComplexF32]
    @test tx_chan.native_stream_format == SoapySDR.ComplexInt{12} #, fullscale
    @test tx_chan.stream_formats == [Complex{Int8}, SoapySDR.ComplexInt{12}, Complex{Int16}, ComplexF32]

    rx_chan.info
    rx_chan.antenna
    rx_chan.gain
    rx_chan.dc_offset_mode
    rx_chan.dc_offset
    rx_chan.iq_balance_mode
    rx_chan.iq_balance
    rx_chan.gain_mode
    rx_chan.frequency_correction
    rx_chan.sample_rate
    rx_chan.bandwidth
    rx_chan.frequency

    tx_chan.info
    tx_chan.antenna
    tx_chan.gain
    tx_chan.dc_offset_mode
    tx_chan.dc_offset
    tx_chan.iq_balance_mode
    tx_chan.iq_balance
    tx_chan.gain_mode
    tx_chan.frequency_correction
    tx_chan.sample_rate
    tx_chan.bandwidth
    tx_chan.frequency


    #@test gainrange(rx_chan) == 0u"dB"..53u"dB"
    #@test gainrange(tx_chan) == 0u"dB"..53u"dB"
    @show sd.frequency_ranges(rx_chan)
    @show sd.frequency_ranges(tx_chan)
    @show sd.bandwidth_ranges(rx_chan)
    @show sd.bandwidth_ranges(tx_chan)
    @show sd.sample_rate_ranges(rx_chan)
    @show sd.sample_rate_ranges(tx_chan)

    #@show sd.GainElement(rx_chan)
    #@show sd.GainElement(tx_chan)

    # Loopback initialized defaults
    #@test rx_chan.bandwidth == 2.048e6u"Hz"
    #@test rx_chan.frequency == 1.0e8u"Hz"
    #@test rx_chan.gain == -53u"dB"
    #@test rx_chan.sample_rate == 2.048e6u"Hz"
    @show rx_chan.info
    @show rx_chan.antenna
    @show rx_chan.dc_offset_mode
    @show rx_chan.dc_offset
    @show rx_chan.iq_balance_mode
    @show rx_chan.iq_balance
    @show rx_chan.gain_mode
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
