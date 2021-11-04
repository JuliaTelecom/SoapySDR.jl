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

## Release Log

### 0.2

This changes the high level API to allow device constructor arguments.

In prior releases to construct a `Device` one would do:

```
devs = Devices()
dev = devs[1]
```

Now one has to explicitly call `open` to create the `Device`, which allows arguments to be set:

```
devs = Devices()
devs[1]["argument"] = "value"
dev = open(devs[1])
```

Similarly it is now possible to `close` a device.