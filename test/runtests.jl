using SoapySDR
using Test
using Unitful
using Unitful.DefaultSymbols
using Intervals
using IOCapture

const dB = u"dB"

const sd = SoapySDR

const hardware = "loopback"

# Load dummy test harness or hardware
if hardware == "loopback"
    using SoapyLoopback_jll
elseif hardware == "rtlsdr"
    using SoapyRTLSDR_jll
else
    error("unknown test hardware")
end

# Test Log Handler registration
SoapySDR.register_log_handler()

@testset "SoapySDR.jl" begin
    @testset "Version" begin
        c = IOCapture.capture() do
            SoapySDR.versioninfo()
        end
        @test contains(c.output, "API Version")
        @test contains(c.output, "ABI Version")
        @test contains(c.output, "Library Version")
    end

    @testset "Logging" begin
        SoapySDR.register_log_handler()
        SoapySDR.set_log_level(0)
    end

    @testset "Error" begin
        @test SoapySDR.error_to_string(-1) == "TIMEOUT"
        @test SoapySDR.error_to_string(10) == "UNKNOWN"
    end

    @testset "Ranges/Display" begin
        intervalrange = sd.SoapySDRRange(0, 1, 0)
        steprange = sd.SoapySDRRange(0, 1, 0.1)

        intervalrangedb = sd._gainrange(intervalrange)
        steprangedb = @test_logs (:warn, r"Step ranges are not supported for gain elements.") begin
            sd._gainrange(steprange) #TODO
        end

        intervalrangehz = sd._hzrange(intervalrange)
        steprangehz = sd._hzrange(steprange)

        hztype = typeof(1.0 * Hz)

        @test typeof(intervalrangedb) ==
              Interval{Gain{Unitful.LogInfo{:Decibel,10,10},:?,Float64},Closed,Closed}
        @test typeof(steprangedb) ==
              Interval{Gain{Unitful.LogInfo{:Decibel,10,10},:?,Float64},Closed,Closed}
        @test typeof(intervalrangehz) == Interval{hztype,Closed,Closed}
        if VERSION >= v"1.7"
            @test typeof(steprangehz) == StepRangeLen{
                hztype,
                Base.TwicePrecision{hztype},
                Base.TwicePrecision{hztype},
                Int64,
            }
        else
            @test typeof(steprangehz) == StepRangeLen{
                hztype,
                Base.TwicePrecision{hztype},
                Base.TwicePrecision{hztype},
            }
        end

        @test sprint(sd.print_hz_range, intervalrangehz) == "00..0.001 kHz"
        @test sprint(sd.print_hz_range, steprangehz) == "00 Hz:0.0001 kHz:0.001 kHz"
    end

    @testset "Keyword Arguments" begin
        args = KWArgs()
        @test length(args) == 0

        args = parse(KWArgs, "foo=1,bar=2")
        @test length(args) == 2
        @test args["foo"] == "1"
        @test args["bar"] == "2"
        args["foo"] = "0"
        @test args["foo"] == "0"
        args["qux"] = "3"
        @test length(args) == 3
        @test args["qux"] == "3"

        str = String(args)
        @test contains(str, "foo=0")
    end

    @testset "High Level API" begin
        # Test failing to open a device due to an invalid specification
        @test_throws SoapySDR.SoapySDRDeviceError Device(parse(KWArgs, "driver=foo"))

        # Device constructor, show, iterator
        @test length(Devices()) == 1
        @test length(Devices(driver = "loopback")) == 1
        show(devnull, Devices())
        deva = Devices()[1]
        deva["refclk"] = "internal"
        dev = Device(deva)
        # XXX: exiting here already prints the error
        show(devnull, dev)
        for dev in Devices()
            show(devnull, dev)
        end
        @test typeof(dev) == sd.Device
        @test typeof(dev.info) == sd.KWArgs
        @test dev.driver == :LoopbackDriver
        @test dev.hardware == :LoopbackHardware
        @test dev.time_sources == SoapySDR.TimeSource[:sw_ticks, :hw_ticks]
        @test dev.time_source == SoapySDR.TimeSource(:sw_ticks)
        dev.time_source = "hw_ticks"
        @test dev.time_source == SoapySDR.TimeSource(:hw_ticks)
        dev.time_source = dev.time_sources[1]
        @test dev.time_source == SoapySDR.TimeSource(:sw_ticks)

        # Channels
        rx_chan_list = dev.rx
        tx_chan_list = dev.tx
        @test typeof(rx_chan_list) == sd.ChannelList
        @test typeof(tx_chan_list) == sd.ChannelList
        show(devnull, rx_chan_list)
        show(devnull, tx_chan_list)
        rx_chan = dev.rx[1]
        tx_chan = dev.tx[1]
        @test typeof(rx_chan) == sd.Channel
        @test typeof(tx_chan) == sd.Channel
        show(devnull, rx_chan)
        show(devnull, tx_chan)
        show(devnull, MIME"text/plain"(), rx_chan)
        show(devnull, MIME"text/plain"(), tx_chan)

        #channel set/get properties
        @test rx_chan.native_stream_format == SoapySDR.ComplexInt{12} #, fullscale
        @test rx_chan.stream_formats ==
              [Complex{Int8}, SoapySDR.ComplexInt{12}, Complex{Int16}, ComplexF32]
        @test tx_chan.native_stream_format == SoapySDR.ComplexInt{12} #, fullscale
        @test tx_chan.stream_formats ==
              [Complex{Int8}, SoapySDR.ComplexInt{12}, Complex{Int16}, ComplexF32]
        @test rx_chan.antennas == SoapySDR.Antenna[:RX, :TX]
        @test tx_chan.antennas == SoapySDR.Antenna[:RX, :TX]
        @test rx_chan.antenna == SoapySDR.Antenna(:RX)
        @test tx_chan.antenna == SoapySDR.Antenna(:TX)
        rx_chan.antenna = :TX
        # TODO: Add some more antennas to the loopback driver
        #@test rx_chan.antenna == SoapySDR.Antenna(:TX)
        rx_chan.antenna = :RX
        rx_chan.antenna = "RX"
        @test_throws ArgumentError rx_chan.antenna = 100
        @test rx_chan.antenna == SoapySDR.Antenna(:RX)
        # channel gain tests
        @test rx_chan.gain_mode == false
        rx_chan.gain_mode = true
        @test rx_chan.gain_mode == true

        @test rx_chan.gain_elements ==
              SoapySDR.GainElement[:IF1, :IF2, :IF3, :IF4, :IF5, :IF6, :TUNER]
        if1 = rx_chan.gain_elements[1]
        show(devnull, rx_chan[if1])
        rx_chan[if1] = 0.5u"dB"
        @test rx_chan[if1] == 0.5u"dB"

        #show(devnull, rx_chan.gain_profile)
        show(devnull, rx_chan.frequency_correction)

        #@test tx_chan.bandwidth == 2.048e6u"Hz"
        #@test tx_chan.frequency == 1.0e8u"Hz"
        #@test tx_chan.gain == -53u"dB"
        #@test tx_chan.sample_rate == 2.048e6u"Hz"

        # setter/getter tests
        rx_chan.sample_rate = 1e5u"Hz"
        #@test rx_chan.sample_rate == 1e5u"Hz"

        @test_logs (:warn, r"poorly supported") match_mode = :any begin
            rx_stream = sd.Stream([rx_chan])
            @test typeof(rx_stream) == sd.Stream{sd.ComplexInt{12}}
            tx_stream = sd.Stream([tx_chan])
            @test typeof(tx_stream) == sd.Stream{sd.ComplexInt{12}}

            @test tx_stream.nchannels == 1
            @test rx_stream.nchannels == 1
            @test tx_stream.num_direct_access_buffers == 0x000000000000000f
            @test tx_stream.mtu == 0x0000000000020000
            @test rx_stream.num_direct_access_buffers == 0x000000000000000f
            @test rx_stream.mtu == 0x0000000000020000
        end

        rx_stream = sd.Stream(ComplexF32, [rx_chan])
        @test typeof(rx_stream) == sd.Stream{ComplexF32}
        tx_stream = sd.Stream(ComplexF32, [tx_chan])
        @test typeof(tx_stream) == sd.Stream{ComplexF32}

        sd.activate!(rx_stream)
        sd.activate!(tx_stream)

        # First, try to write an invalid buffer type, ensure that that errors
        buffers = [zeros(ComplexF32, 10), zeros(ComplexF32, 11)]
        @test_throws ArgumentError write(tx_stream, buffers)

        # We (unfortunately) cannot do a write/read test, as that's not supported
        # by SoapyLoopback yet, despite the name.  ;)
        #=
        tx_buff = randn(ComplexF32, tx_stream.mtu)
        write(tx_stream, (tx_buff,))
        rx_buff = vcat(
            only(read(rx_stream, div(rx_stream.mtu,2))),
            only(read(rx_stream, div(rx_stream.mtu,2))),
        )
        @test length(rx_buff) == length(tx_buff)
        @test all(rx_buff .== tx_buff)
        =#

        # Test that reading once more causes a warning to be printed, as there's nothing to be read:
        @test_logs (:warn, r"readStream timeout!") match_mode = :any begin
            read(rx_stream, 1)
        end

        sd.deactivate!(rx_stream)
        sd.deactivate!(tx_stream)

        # do block syntax
        Device(Devices()[1]) do dev
            show(devnull, dev.info)
        end
        # and again to ensure correct GC
        Device(Devices()[1]) do dev
            sd.Stream(ComplexF32, [dev.rx[1]]) do s_rx
                show(devnull, dev.info)
                show(devnull, s_rx)

                # Activate/deactivate
                sd.activate!(s_rx) do
                end

                # Group activate/deactivate
                sd.Stream(ComplexF32, [dev.tx[1]]) do s_tx
                    sd.activate!([s_rx, s_tx]) do
                    end
                end
            end
        end
    end

    @testset "Settings" begin
        dev = Device(Devices()[1])
        arglist = SoapySDR.SettingInfo(dev)
        show(devnull, arglist)
        a1 = arglist[1]
        show(devnull, a1)
    end

    @testset "Examples" begin
        c = IOCapture.capture() do
            include("$(@__DIR__)/../examples/highlevel_dump_devices.jl")
        end
        @test contains(c.output, "driver=loopback")
    end

    @testset "Modules" begin
        @test SoapySDR.Modules.get_root_path() == "/workspace/destdir"
        @test all(
            SoapySDR.Modules.list_search_paths() .==
            ["/workspace/destdir/lib/SoapySDR/modules0.8"],
        )
        @test SoapySDR.Modules.list() == String[]
    end

    using Aqua
    # Aqua tests
    # Intervals brings a bunch of ambiquities unfortunately
    Aqua.test_all(SoapySDR; ambiguities = false)

end #SoapySDR testset

if VERSION >= v"1.8"
    @info "Running JET..."

    using JET
    display(JET.report_package(SoapySDR))
end
