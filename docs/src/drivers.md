# Loading Drivers

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
Alternatively, you can see the instructions below about using operating system provided modules with SoapySDR.jl.

To activate the driver and module, simply use the package along with SoapySDR.
For example:

```
julia> using SoapySDR, xtrx_jll
```

or:

```
julia> using SoapySDR, SoapyRTLSDR_jll
```

## Loading System-Provided Driver Modules

The `SOAPY_SDR_PLUGIN_PATH` environmental variable is read by SoapySDR to load local driver modules.
For example, on Ubuntu one may use the Ubuntu package manager to install all SoapySDR driver modules:

```
sudo apt install soapysdr0.8-module-all 
```

These can then be used from SoapySDR.jl by exporting the environmental variable with the module directory:

```
export SOAPY_SDR_PLUGIN_PATH=/usr/lib/x86_64-linux-gnu/SoapySDR/modules0.8/
```

This can add support for more devices than is provided by the Julia package manager, however compatibility
is not guaranteed.