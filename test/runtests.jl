using SoapySDR
using Test
using Unitful
using Unitful.DefaultSymbols
using Intervals

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
        SoapySDR.versioninfo()
    end
    @testset "Logging" begin
        SoapySDR.register_log_handler()
        SoapySDR.set_log_level(0)
    end
    @testset "Error" begin
        SoapySDR.error_to_string(-1) == "TIMEOUT"
        SoapySDR.error_to_string(10) == "UNKNOWN"
    end
    @testset "Ranges/Display" begin
        intervalrange = sd.SoapySDRRange(0, 1, 0)
        steprange = sd.SoapySDRRange(0, 1, 0.1)

        intervalrangedb = sd._gainrange(intervalrange)
        steprangedb = sd._gainrange(steprange) #TODO

        intervalrangehz = sd._hzrange(intervalrange)
        steprangehz = sd._hzrange(steprange)

        hztype = typeof(1.0 * Hz)

        @test typeof(intervalrangedb) == Interval{Gain{Unitful.LogInfo{:Decibel,10,10},:?,Float64},Closed,Closed}
        @test typeof(steprangedb) == Interval{Gain{Unitful.LogInfo{:Decibel,10,10},:?,Float64},Closed,Closed}
        @test typeof(intervalrangehz) == Interval{hztype,Closed,Closed}
        if VERSION >= v"1.7"
            @test typeof(steprangehz) == StepRangeLen{hztype,Base.TwicePrecision{hztype},Base.TwicePrecision{hztype},Int64}
        else
            @test typeof(steprangehz) == StepRangeLen{hztype,Base.TwicePrecision{hztype},Base.TwicePrecision{hztype}}
        end

        io = IOBuffer(read=true, write=true)

        sd.print_hz_range(io, intervalrangehz)
        @test String(take!(io)) == "00..0.001 kHz"
        sd.print_hz_range(io, steprangehz)
        @test String(take!(io)) == "00 Hz:0.0001 kHz:0.001 kHz"
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
        io = IOBuffer(read=true, write=true)

        # Test failing to open a device due to an invalid specification
        @test_throws SoapySDR.SoapySDRDeviceError Device(parse(KWArgs, "driver=foo"))

        # Device constructor, show, iterator
        @test length(Devices()) == 1
        @test length(Devices(driver="Loopback")) == 1
        show(io, Devices())
        deva = Devices()[1]
        deva["refclk"] = "internal"
        dev = Device(deva)
        show(io, dev)
        for dev in Devices()
            show(io, dev)
        end
        @test typeof(dev) == sd.Device
        @test typeof(dev.info) == sd.KWArgs
        @test dev.driver == :SoapyLoopbackDriver
        @test dev.hardware == :SoapyLoopback

        #=
        @test dev.time_sources == SoapySDR.TimeSource[:sw_ticks, :hw_ticks]
        @test dev.time_source == SoapySDR.TimeSource(:sw_ticks)
        dev.time_source = "hw_ticks"
        @test dev.time_source == SoapySDR.TimeSource(:hw_ticks)
        dev.time_source = dev.time_sources[1]
        @test dev.time_source == SoapySDR.TimeSource(:sw_ticks)
        =#


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
        @test rx_chan.direction == SoapySDR.Rx
        @test tx_chan.direction == SoapySDR.Tx

        #channel set/get properties
        @test rx_chan.native_stream_format == ComplexF32
        @test rx_chan.stream_formats == [ComplexF32]
        @test tx_chan.native_stream_format == ComplexF32
        @test tx_chan.stream_formats == [ComplexF32]
        @test rx_chan.antennas == SoapySDR.Antenna[:RX0, :RX1, :RX2]
        @test tx_chan.antennas == SoapySDR.Antenna[:TX0, :TX1, :TX2]
        @test rx_chan.antenna == SoapySDR.Antenna(:RX0)
        @test tx_chan.antenna == SoapySDR.Antenna(:TX0)
        rx_chan.antenna = :RX1
        @test rx_chan.antenna == SoapySDR.Antenna(:RX1)
        rx_chan.antenna = "RX2"
        @test rx_chan.antenna == SoapySDR.Antenna(:RX2)
        @test_throws ArgumentError rx_chan.antenna = 100
        @test rx_chan.antenna == SoapySDR.Antenna(:RX2)
        native_format = rx_chan.native_stream_format


        # channel gain tests
        @test rx_chan.gain_mode == false
        rx_chan.gain_mode = true
        @test rx_chan.gain_mode == true

        @test rx_chan.gain_elements == SoapySDR.GainElement[:RX_GAIN0, :RX_GAIN1, :RX_GAIN2]
        gain0 = first(rx_chan.gain_elements)
        @show rx_chan[gain0]
        rx_chan[gain0] = 0.5u"dB"
        @test rx_chan[gain0] == 0.5u"dB"

        #@show rx_chan.gain_profile
        @show rx_chan.frequency_correction

        #@test tx_chan.bandwidth == 2.048e6u"Hz"
        #@test tx_chan.frequency == 1.0e8u"Hz"
        #@test tx_chan.gain == -53u"dB"
        #@test tx_chan.sample_rate == 2.048e6u"Hz"

        # setter/getter tests
        sample_rates = sd.list_sample_rates(rx_chan)
        @test length(sample_rates) > 2
        for fs in sample_rates
            rx_chan.sample_rate = fs
            @test rx_chan.sample_rate == fs
        end

        @test_throws SoapySDR.SoapySDRDeviceError rx_chan.sample_rate = 1e20u"Hz"

        sd.Stream([rx_chan]) do rx_stream
            @test typeof(rx_stream) == sd.Stream{native_format}
            @test sd.isopen(rx_stream)
            @test rx_stream.nchannels == 1

            sd.Stream([tx_chan]) do tx_stream
                @test typeof(tx_stream) == sd.Stream{native_format}
                @test sd.isopen(tx_stream)
                @test tx_stream.nchannels == 1

                # Disable direct access API for now
                #@test tx_stream.num_direct_access_buffers == 0x000000000000000f
                #@test rx_stream.num_direct_access_buffers == 0x000000000000000f

                @test tx_stream.mtu == 0x0000000000000400
                @test rx_stream.mtu == 0x0000000000000400

                sd.activate!([rx_stream, tx_stream]) do
                    # First, test that we error out when attempting to write two channels' worth
                    # of data:
                    buffers = (zeros(ComplexF32, 10), zeros(ComplexF32, 11))
                    @test_throws ArgumentError write(tx_stream, buffers)

                    # Next, actually write out a single MTU's worth of data
                    tx_buff = ComplexF32.((0:(tx_stream.mtu-1)), 0)
                    write(tx_stream, (tx_buff,))
                    rx_buff = vcat(
                        only(read(rx_stream, div(rx_stream.mtu,2))),
                        only(read(rx_stream, div(rx_stream.mtu,2))),
                    )
                    @test length(rx_buff) == length(tx_buff)

                    @test all(rx_buff .== tx_buff)

                    # Test that reading once more causes a warning to be printed, as there's nothing to be read:
                    @test_logs (:warn, r"readStream timeout!") match_mode = :any begin
                        read(rx_stream, 1)
                    end
                end
            end
        end

        # do block syntax
        Device(Devices()[1]) do dev
            println(dev.info)
        end
        # and again to ensure correct GC
        Device(Devices()[1]) do dev
            sd.Stream(ComplexF32, [dev.rx[1]]) do s_rx
                println(dev.info)
                println(s_rx)

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
        io = IOBuffer(read=true, write=true)
        dev = Device(Devices()[1])
        arglist = SoapySDR.ArgInfoList(SoapySDR.SoapySDRDevice_getSettingInfo(dev)...)
        println(arglist)
        a1 = arglist[1]
        println(a1)
    end


    @testset "Examples" begin
        include("../examples/highlevel_dump_devices.jl")
    end

    @testset "Modules" begin
        @test SoapySDR.Modules.get_root_path() == "/workspace/destdir"
        @test all(SoapySDR.Modules.list_search_paths() .== ["/workspace/destdir/lib/SoapySDR/modules0.8"])
        @test SoapySDR.Modules.list() == String[]
    end

    using Aqua
    # Aqua tests
    # Intervals brings a bunch of ambiquities unfortunately
    Aqua.test_all(SoapySDR; ambiguities=false)

end #SoapySDR testset

if VERSION >= v"1.8"
    @info "Running JET..."

    using JET
    display(JET.report_package(SoapySDR))
end
