# Troubleshooting

Below are some common issues and how to resolve them. If you don't find the issue listed here, please [file an issue](). We are always looking to help identify and fix bugs.

## No Devices Found

You may see:

```
julia> Devices()
No devices available! Make sure a supported SDR module is included.
```

Make sure you have included a module driver from the [module list](./index.md#Loading-a-Driver-Module).

If this doesn't work, and you are on Linux, please see the [udev section](./#Udev-Rules) below.


## Linux Troubleshooting

### Udev Rules

Udev rules should be copied into `/etc/udev/rules.d/`.

Udev rules for some common devices are linked below:

- [RTL-SDR](https://github.com/osmocom/rtl-sdr/blob/d770add42e87a40e59a0185521373f516778384b/rtl-sdr.rules)
- [USRP](https://github.com/EttusResearch/uhd/blob/919043f305efdd29fbdf586e9cde95d9507150e8/host/utils/uhd-usrp.rules)
- [LimeSDR](https://github.com/myriadrf/LimeSuite/blob/a45e482dad28508d8787e0fdc5168d45ac877ab5/udev-rules/64-limesuite.rules)
- [ADALM-Pluto](https://github.com/analogdevicesinc/plutosdr-fw/blob/cbe7306055828ce0a12a9da35efc6685c86f811f/scripts/53-adi-plutosdr-usb.rules)

### Blacklisting Kernel Modules

For some devices such as the RTL-SDR, a kernel module may need to be blacklisted in order to use
the user space driver. Typically the library will warn is this is required. Please check you distribution
instructions for how to do this.

RTL-SDR module name: `dvb_usb_rtl28xxu`