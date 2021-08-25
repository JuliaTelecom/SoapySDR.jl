# Driver Modules

Below is a list of driver modules that may be installed with the Julia package manager.

| Device | Julia Package   |
|--------|-----------------|
| xrtx   | xtrx_jll        |
|RTL-SDR | soapyrtlsdr_jll |

To activate the driver and module, simply use the package along with SoapySDR.
For example:

```
julia> using SoapySDR, xtrx_jll
```

or:

```
julia> using SoapySDR, soapyrtlsdr_jll
```
