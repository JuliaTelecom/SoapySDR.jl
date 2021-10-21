```@meta
CurrentModule = SoapySDR
```

# SoapySDR

Documentation for [SoapySDR](https://github.com/JuliaTelecom/SoapySDR.jl).

This package provides a Julia wrapper for the [SoapySDR](https://github.com/pothosware/SoapySDR) C++ library.

## Quick Start

### Loading a Driver Module

Below is a list of driver modules that may be installed with the Julia package manager.

| Device  | Julia Package    |
|---------|------------------|
| xrtx    | xtrx_jll         |
|RTL-SDR  | SoapyRTLSDR_jll  |
|LimeSDR  | SoapyLMS7_jll    |
| USRP    | SoapyUHD_jll     |
|Pluto SDR| SoapyPlutoSDR_jll|

If you need a driver module that is not listed, you can search [JuliaHub](https://juliahub.com)
to see if it may have been added to the package manager. If not, please file an [issue](https://github.com/JuliaTelecom/SoapySDR.jl/issues).

To activate the driver and module, simply use the package along with SoapySDR.
For example:

```
julia> using SoapySDR, xtrx_jll
```

or:

```
julia> using SoapySDR, SoapyRTLSDR_jll
```

### Transmitting and Receiving (loopback)

````@eval
using Markdown
Markdown.parse("""
```julia
$(read(joinpath(@__DIR__, "../../examples/highlevel_loopback.jl"), String))
```
""")
````
