# SoapySDR.jl

This is a Julia wrapper for [SoapySDR](https://github.com/pothosware/SoapySDR/wiki) to enable SDR processing in Julia.
It features a high level interface to interact with underlying SDR radios.

# QuickStart

These examples assume that the SDR is an xtrx and that it is the only
device attached. Subsitute the driver for your SDR and check settings
as appropriate.

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

# API Guide

The entry point of this package is the Devices() object, which will list
all devices known to SoapySDR on the current system. Note that you may
also have to load a driver for your particular SDR in order to register
it with SoapySDR. Here we will use XTRX:

```
julia> using SoapySDR, xtrx_jll

julia> Devices()
[1] :addr => "pcie:///dev/xtrx0", :dev => "pcie:///dev/xtrx0", :driver => "xtrx", :label => "XTRX: pcie:///dev/xtrx0 (10Gbit)", :media => "PCIe", :module => "SoapyXTRX", :name => "XTRX", :serial => "", :type => "xtrx"
```

Devices may be selected ust by indexing:
```
julia> device = Devices()[1]
21:11:54.675118 DEBUG:  xtrxllpciev0_discovery:264 [PCIE] pcie: Found `pcie:///dev/xtrx0`
21:11:54.688916 DEBUG:  xtrxllpciev0_discovery:264 [PCIE] pcie: Found `pcie:///dev/xtrx0`
[INFO] Make connection: 'pcie:///dev/xtrx0'
21:11:54.688990 INFO:   [XTRX] xtrx_open(): dev[0]='pcie:///dev/xtrx0'
21:11:54.689031 INFO:   [CTRL] PCI:/dev/xtrx0: RFIC_GPIO 0x000300
21:11:54.706207 INFO:   [CTRL] PCI:/dev/xtrx0: XTRX Rev4 (04000113)
21:11:54.706246 INFO:   [BPCI] PCI:/dev/xtrx0: RX DMA STOP MIMO (BLK:0 TS:0); TX DMA STOP MIMO @0.0
21:11:54.706251 INFO:   [PCIE] PCI:/dev/xtrx0: Device `pcie:///dev/xtrx0` has been opened successfully
CPU Features: SSE2+ SSE4.1+ AVX+ FMA+
21:11:54.820272 INFO:   [CTRL] PCI:/dev/xtrx0: RFIC_GPIO 0x000304
21:11:54.920458 INFO:   [CTRL] PCI:/dev/xtrx0: FPGA V_GPIO set to 3280mV
21:11:54.920509 INFO:   [CTRL] PCI:/dev/xtrx0: LMS PMIC DCDC out set to VA18=1880mV VA14=1480mV VA12=1340mV
21:11:54.924038 INFO:   [CTRL] PCI:/dev/xtrx0: FPGA V_IO set to 1800mV
21:11:54.934544 INFO:   [CTRL] PCI:/dev/xtrx0: RFIC_GPIO 0x000306
21:11:54.945459 INFO:   [LSM7] PCI:/dev/xtrx0: LMS VER:7 REV:1 MASK:1 (3841)
21:11:54.945515 INFO:   [CTRL] PCI:/dev/xtrx0: RFIC_GPIO 0x00031e
[INFO] Created: `pcie:///dev/xtrx0`
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
21:15:44.166249 INFO:   [BPCI] PCI:/dev/xtrx0: RX DMA STOP MIMO (BLK:0 TS:0); TX DMA SKIP MIMO @0.0
21:15:44.166307 INFO:   [LSM7] PCI:/dev/xtrx0: 0x0124[00, 00]
21:15:44.166759 INFO:   [BPCI] PCI:/dev/xtrx0: RX DMA STOP MIMO (BLK:0 TS:0); TX DMA SKIP MIMO @0.0
21:15:44.166769 INFO:   [LMSF] PCI:/dev/xtrx0: Auto RX band selection: LNAL
21:15:44.166772 INFO:   [LMSF] PCI:/dev/xtrx0: Set RX band to 2 (L)
21:15:44.166971 INFO:   [CTRL] PCI:/dev/xtrx0: RX_ANT: 1 TX_ANT: 0
21:15:44.166973 INFO:   [LMSF] PCI:/dev/xtrx0: DC START
21:15:44.167022 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167039 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167056 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167099 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167116 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167147 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167187 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167206 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167236 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167268 INFO:   [LSM7] PCI:/dev/xtrx0:  5c1=0000
21:15:44.167335 INFO:   [LSM7] PCI:/dev/xtrx0:  TX[0]=0000
21:15:44.167416 INFO:   [LSM7] PCI:/dev/xtrx0:  TX[1]=0000
21:15:44.167506 INFO:   [LSM7] PCI:/dev/xtrx0:  TX[2]=0000
21:15:44.167573 INFO:   [LSM7] PCI:/dev/xtrx0:  TX[3]=0000
21:15:44.167621 INFO:   [LSM7] PCI:/dev/xtrx0:  RX[0]=0000
21:15:44.167671 INFO:   [LSM7] PCI:/dev/xtrx0:  RX[1]=0000
21:15:44.167719 INFO:   [LSM7] PCI:/dev/xtrx0:  RX[2]=0000
21:15:44.167777 INFO:   [LSM7] PCI:/dev/xtrx0:  RX[3]=0000
Stream on xtrxdev
```

These may then be accessed using standard IO functions:
```
julia> SoapySDR.activate!(stream)

julia> Base.read(stream, 10_000)
```