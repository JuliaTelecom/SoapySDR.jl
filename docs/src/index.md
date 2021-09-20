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
| USRP   | SoapyUHD_jll    |

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

```
# Open all TX-capable channels on first device
tx_channels = Devices()[1].tx

# Open all RX-capable channels on first device
rx_channels = Devices()[1].rx

# Configure a TX channel with appropriate parameters
# configure the RX channel with similar for e.g. a loopback test
# Be sure to check your local regulations before transmitting!
tx_channels[1].bandwidth = 800u"kHz"
tx_channels[1].frequency = 30u"MHz"
tx_channels[1].gain = 42u"dB"
tx_channels[1].sample_rate = 2.1u"MHz"

# Open a (potentially multichannel) stream on the channels
tx_stream = SoapySDR.Stream(tx_channels)
rx_stream = SoapySDR.Stream(rx_channels)

# Setup a sample buffer optimized for the device
# The data can be access with e.g. tx_buf.bufs
# Note: we ask for 10,000 samples, but the API will re-size correctly for the device
tx_buf = SoapySDR.SampleBuffer(tx_stream, 10_000)
rx_buf = SoapySDR.SampleBuffer(rx_stream, 10_000)

# Setup some data to transmit on each channel
for i in eachindex(tx_buf)
    tx_buf[i] .= rand(SoapySDR.streamtype(tx_stream), length(tx_buf))
end

# Spawn two tasks for full duplex operation
# The tasks will run in parallel and for best resuslts run julia with --threads=auto
read_task = Threads.@spawn read!(rx_stream, rx_buf)
write_task = Threads.@spawn write(tx_stream, tx_buf)

# Wait for the tasks to complete
wait(read_task)
wait(write_task)

@show rx_buf[1][1:100] # show the first 100 samples of the first buffer
```
