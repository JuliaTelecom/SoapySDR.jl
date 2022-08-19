```@meta
CurrentModule = SoapySDR
```

# SoapySDR

Documentation for [SoapySDR](https://github.com/JuliaTelecom/SoapySDR.jl).

This package provides a Julia wrapper for the [SoapySDR](https://github.com/pothosware/SoapySDR) C++ library.

## Quick Start

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
