"""
    SoapySDR_errToStr(errorCode)

Convert a error code to a string for printing purposes.
If the error code is unrecognized, errToStr returns "UNKNOWN".
\\param errorCode a negative integer return code
\\return a pointer to a string representing the error
"""
function SoapySDR_errToStr(errorCode)
    ccall((:SoapySDR_errToStr, soapysdr), Ptr{Cchar}, (Cint,), errorCode)
end

const SOAPY_SDR_TIMEOUT = -1

const SOAPY_SDR_STREAM_ERROR = -2

const SOAPY_SDR_CORRUPTION = -3

const SOAPY_SDR_OVERFLOW = -4

const SOAPY_SDR_NOT_SUPPORTED = -5

const SOAPY_SDR_TIME_ERROR = -6

const SOAPY_SDR_UNDERFLOW = -7

