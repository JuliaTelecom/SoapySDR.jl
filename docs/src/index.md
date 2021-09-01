```@meta
CurrentModule = SoapySDR
```

# SoapySDR

Documentation for [SoapySDR](https://github.com/JuliaTelecom/SoapySDR.jl).

This package provides a Julia wrapper for the [SoapySDR](https://github.com/pothosware/SoapySDR) C++ library.

## Quick Start

### Loading a Driver Module

Below is a list of driver modules that may be installed with the Julia package manager.

| Device | Julia Package   |
|--------|-----------------|
| xrtx   | xtrx_jll        |
|RTL-SDR | SoapyRTLSDR_jll |
|LimeSDR | SoapyLMS7_jll   |

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

### Transmitting and Receiving

TX:
```
# Open first TX-capable channel on first device
channel = Devices()[1].tx[1]

# Configure channel with appropriate parameters
channel.bandwidth = 800u"kHz"
channel.frequency = 30u"MHz"
channel.gain = 42u"dB"
channel.sample_rate = 2.1u"MHz"

# Open a (potentially multichannel) stream on this channel
stream = SoapySDR.Stream(ComplexF32, [channel])
SoapySDR.activate!(stream)

# Write out random noise
Base.write(stream, (randn(ComplexF32, 10000),))
```

RX:
```
# Open first RX-capable channel on first device
channel = Devices()[1].rx[1]

# Configure channel with appropriate parameters
channel.bandwidth = 800u"kHz"
channel.frequency = 30u"MHz"
channel.gain = 42u"dB"
channel.sample_rate = 2.1u"MHz"

# Open a (potentially multichannel) stream on this channel
stream = SoapySDR.Stream(ComplexF32, [channel])
SoapySDR.activate!(stream)

# Collect data
Base.read(stream, 10000)
```
