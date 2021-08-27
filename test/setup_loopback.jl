using Libdl

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
