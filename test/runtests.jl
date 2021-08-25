using SoapySDR
using Test

@testset "SoapySDR.jl" begin
    @test length(Devices()) == 0
end
