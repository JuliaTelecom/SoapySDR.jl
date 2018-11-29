# Error codes used in the device API.

# Convert a error code to a string for printing purposes.
# If the error code is unrecognized, errToStr returns "UNKNOWN".
# param errorCode a negative integer return code
# return a pointer to a string representing the error
function SoapySDR_errToStr(errorCode)
    ccall((:SoapySDR_errToStr, lib), Cstring, (Cint,), errorCode)
end

# Returned when read has a timeout.
const SOAPY_SDR_TIMEOUT = -1

# Returned for non-specific stream errors.
const SOAPY_SDR_STREAM_ERROR = -2

# Returned when read has data corruption.
# For example, the driver saw a malformed packet.
const SOAPY_SDR_CORRUPTION = -3

# Returned when read has an overflow condition.
# For example, and internal buffer has filled.
const SOAPY_SDR_OVERFLOW = -4

# Returned when a requested operation or flag setting
# is not supported by the underlying implementation.
const SOAPY_SDR_NOT_SUPPORTED = -5

# Returned when a the device encountered a stream time
# which was expired (late) or too early to process.
const SOAPY_SDR_TIME_ERROR = -6

# Returned when write caused an underflow condition.
# For example, a continuous stream was interrupted.
const SOAPY_SDR_UNDERFLOW = -7
