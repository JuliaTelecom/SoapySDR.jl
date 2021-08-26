using SoapySDR
using Test
using Libdl

const sd = SoapySDR
const build_loopback = false

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
@testset "High Level API" begin
    @test length(Devices()) == 1
    dev = Devices()[1]
    
end
end
