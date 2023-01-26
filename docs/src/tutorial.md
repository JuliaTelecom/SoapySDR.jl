# Tutorial

!!! note
    You have to load a driver for your particular SDR in order to work
    with SoapySDR. Available modules through the Julia Package manager are listed
    on the [index.](./index.md)

The entry point of this package is the `Devices()` object, which will list
all devices known to SoapySDR on the current system. 

Here we will use XTRX:

```
julia> using SoapySDR, xtrx_jll

julia> Devices()
[1] :addr => "pcie:///dev/xtrx0", :dev => "pcie:///dev/xtrx0", :driver => "xtrx", :label => "XTRX: pcie:///dev/xtrx0 (10Gbit)", :media => "PCIe", :module => "SoapyXTRX", :name => "XTRX", :serial => "", :type => "xtrx"
```

Devices may be selected just by indexing and constructing the `Device`:
```
julia> device = SoapySDR.Device(Devices()[1])
SoapySDR xtrxdev device (driver: xtrxsoapy) w/ 2 TX channels and 2 RX channels
```

The channels on the device are then available on the resulting object
```
julia> device.tx
2-element SoapySDR.ChannelList:
 Channel(xtrxdev, Tx, 0)
 Channel(xtrxdev, Tx, 1)

julia> device.rx
2-element SoapySDR.ChannelList:
 Channel(xtrxdev, Rx, 0)
 Channel(xtrxdev, Rx, 1)

julia> device.tx[1]
TX Channel #1 on xtrxdev
  Selected Antenna [TXH, TXW]: TXW
  Bandwidth [ 800 kHz .. 16 MHz, 28..60 MHz ]: 0.0 Hz
  Frequency [ 30 MHz .. 3.8 GHz ]: 0.0 Hz
    RF [ 30 MHz .. 3.8 GHz ]: 0.0 Hz
    BB [ -00..00 Hz ]: 0.0 Hz
  Gain [0.0 dB .. 52.0 dB]: 0.0 dB
    PAD [0.0 dB .. 52.0 dB]: 0.0 dB
  Sample Rate [ 2.1..56.2 MHz, 61.4..80 MHz ]: 0.0 Hz
  DC offset correction: (0.0, 0.0)
  IQ balance correction: (0.0, 0.0)
```

To send or receive data, start a stream on a particular channel:
```
julia> stream = SDRStream(ComplexF32, [device.rx[1]])
Stream on xtrxdev
```

These may then be accessed using standard IO functions:
```
julia> SoapySDR.activate!(stream)

julia> Base.read(stream, 10_000)
```
