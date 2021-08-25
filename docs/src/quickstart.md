# QuickStart

!!! note
    You have to load a driver for your particular SDR in order to work
    with SoapySDR. Available modules through the Julia Package manager are listed
    on the [driver modules page.](./drivermodules.md)

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
channel = Devices()[1].tx[1]

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
