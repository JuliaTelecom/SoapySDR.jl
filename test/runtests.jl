using SoapySDR
using Test

const sd = SoapySDR

const hardware = "loopback"

# build SoapyLoopback and dlopen it
if hardware == "loopback"
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

    # Should throw
    @test_throws ErrorException sd.StreamFormat(sd.SOAPY_SDR_CS12)
    @test_throws ErrorException sd.StreamFormat(sd.SOAPY_SDR_CU12)
    @test_throws ErrorException sd.StreamFormat(sd.SOAPY_SDR_CS4)
    @test_throws ErrorException sd.StreamFormat(sd.SOAPY_SDR_CU4)
    @test_throws ErrorException sd.StreamFormat("nonsense")
end
@testset "High Level API" begin
    @test length(Devices()) == 1
    dev = Devices()[1]

    @show dev.info
    @show dev.driver
    @show dev.hardware
    @show dev.tx
    @show dev.rx
end
end
