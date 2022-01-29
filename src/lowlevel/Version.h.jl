"""
    SoapySDR_getAPIVersion()

Get the SoapySDR library API version as a string.
The format of the version string is <b>major.minor.increment</b>,
where the digits are taken directly from <b>SOAPY_SDR_API_VERSION</b>.
"""
function SoapySDR_getAPIVersion()
    ccall((:SoapySDR_getAPIVersion, soapysdr), Ptr{Cchar}, ())
end

"""
    SoapySDR_getABIVersion()

Get the ABI version string that the library was built against.
A client can compare <b>SOAPY_SDR_ABI_VERSION</b> to getABIVersion()
to check for ABI incompatibility before using the library.
If the values are not equal then the client code was
compiled against a different ABI than the library.
"""
function SoapySDR_getABIVersion()
    ccall((:SoapySDR_getABIVersion, soapysdr), Ptr{Cchar}, ())
end

"""
    SoapySDR_getLibVersion()

Get the library version and build information string.
The format of the version string is <b>major.minor.patch-buildInfo</b>.
This function is commonly used to identify the software back-end
to the user for command-line utilities and graphical applications.
"""
function SoapySDR_getLibVersion()
    ccall((:SoapySDR_getLibVersion, soapysdr), Ptr{Cchar}, ())
end

const SOAPY_SDR_API_VERSION = 0x00080000

const SOAPY_SDR_ABI_VERSION = "0.8"

