
"""
    error_to_string(error)
"""
function error_to_string(error)
    ptr = SoapySDR_errToStr(error)
    ptr === C_NULL ? "" : unsafe_string(ptr) 
end