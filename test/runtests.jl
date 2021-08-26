using SoapySDR
using Test
using Libdl

const sd = SoapySDR
const build_loopback = true

# Build SoapyLoopback
# TODO: Yggdrasil once stable
if build_loopback
    include("build_tarballs.jl")
end
cd("products")
loopback_tar = readdir()[1]
loopback = splitext(loopback_tar)[1]
run(`tar -xzf $(loopback_tar)`) # BB without tar output?
dlopen("lib/SoapySDR/modules0.8/libsoapyloopback.so")


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

    @show dev

end
end
