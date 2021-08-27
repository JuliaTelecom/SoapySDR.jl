using SoapySDR
using Test

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
@testset "StreamFormat" begin

    # Should not throw
    sd.StreamFormat(sd.SOAPY_SDR_CF64)
    sd.StreamFormat(sd.SOAPY_SDR_CF32)
    sd.StreamFormat(sd.SOAPY_SDR_CS32)
    sd.StreamFormat(sd.SOAPY_SDR_CU32)
    sd.StreamFormat(sd.SOAPY_SDR_CS16)
    sd.StreamFormat(sd.SOAPY_SDR_CU16)
    sd.StreamFormat(sd.SOAPY_SDR_F64)
    sd.StreamFormat(sd.SOAPY_SDR_F32)
    sd.StreamFormat(sd.SOAPY_SDR_S32)
    sd.StreamFormat(sd.SOAPY_SDR_U32)
    sd.StreamFormat(sd.SOAPY_SDR_S16)
    sd.StreamFormat(sd.SOAPY_SDR_U16)
    sd.StreamFormat(sd.SOAPY_SDR_S8)
    sd.StreamFormat(sd.SOAPY_SDR_U8)
    sd.StreamFormat(sd.SOAPY_SDR_CS8)
    sd.StreamFormat(sd.SOAPY_SDR_CU8)
    sd.StreamFormat(sd.SOAPY_SDR_CS12)
    sd.StreamFormat(sd.SOAPY_SDR_CU12)
    sd.StreamFormat(sd.SOAPY_SDR_CS4)
    sd.StreamFormat(sd.SOAPY_SDR_CU4)

    # Should throw
    @test_throws ErrorException sd.StreamFormat("nonsense")
end
@testset "High Level API" begin
    @test length(Devices()) == 1
    dev = Devices()[1]

    @test typeof(dev.info) == sd.OwnedKWArgs
    @test dev.driver == :LoopbackDriver
    @test dev.hardware == :LoopbackHardware
    dev.hardwareinfo #TODO

    rx_chan = dev.rx[1]
    tx_chan = dev.tx[1]

    @show rx_chan.bandwidth
    @show rx_chan.frequency
    @show rx_chan.gain
    @show rx_chan.sample_rate


    rx_stream = sd.Stream(ComplexF32, [rx_chan])

    tx_stream = sd.Stream(ComplexF32, [tx_chan])

    #@test dev.tx == [Channel(Loopback, Tx, 0)]
    #@test dev.rx == [Channel(Loopback, Rx, 0)]
end
end
