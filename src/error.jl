
"""
    error_to_string(error)

Calls `SoapySDR_errToStr(error)`, returning the string.
"""
function error_to_string(error)
    ptr = SoapySDR_errToStr(error)
    ptr === C_NULL ? "" : unsafe_string(ptr) 
end

struct SoapySDRDeviceError <: Exception
    status::Int
    msg::String
end

function get_SoapySDRDeviceError()
    return SoapySDRDeviceError(
        SoapySDRDevice_lastStatus(),
        unsafe_string(SoapySDRDevice_lastError()),
    )
end

function with_error_check(f::Function)
    val = f()
    if SoapySDRDevice_lastStatus() != 0
        throw(get_SoapySDRDeviceError())
    end
    return val
end

macro soapy_checked(ex)
    return quote
        with_error_check() do
            $(esc(ex))
        end
    end
end
