# Interface definition for Soapy SDR devices.
# 
# General design rules about the API:
# The caller must free non-const array results.

# Forward declaration of device handle
struct SoapySDRDevice
end

# Forward declaration of stream handle
struct SoapySDRStream
end

# Get the last status code after a Device API call.
# The status code is cleared on entry to each Device call.
# When an device API call throws, the C bindings catch
# the exception, and set a non-zero last status code.
# Use lastStatus() to determine success/failure for
# Device calls without integer status return codes.
function SoapySDRDevice_lastStatus()
    ccall((:SoapySDRDevice_lastStatus, lib), Cint, ())
end

# Get the last error message after a device call fails.
# When an device API call throws, the C bindings catch
# the exception, store its message in thread-safe storage,
# and return a non-zero status code to indicate failure.
# Use lastError() to access the exception's error message.
function SoapySDRDevice_lastError()
    ccall((:SoapySDRDevice_lastError, lib), Cstring, ())
    # unsafe_string(ret)
end

# Enumerate a list of available devices on the system.
# param args device construction key/value argument filters
# param [out] length the number of elements in the result.
# return a list of arguments strings, each unique to a device
function SoapySDRDevice_enumerate()
    size = Ref{Csize_t}()
    kwargs = ccall((:SoapySDRDevice_enumerate, lib), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, size)
    return (kwargs, size)
end

