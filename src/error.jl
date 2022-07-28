
"""
    error_to_string(error)

Calls `SoapySDR_errToStr(error)`, returning the string.
"""
function error_to_string(error)
    ptr = SoapySDR_errToStr(error)
    ptr === C_NULL ? "" : unsafe_string(ptr) 
end

const SoapyStreamFlags = Dict(
    "END_BURST" => SOAPY_SDR_END_BURST,
    "HAS_TIME" => SOAPY_SDR_HAS_TIME,
    "END_ABRUPT" => SOAPY_SDR_END_ABRUPT,
    "ONE_PACKET" => SOAPY_SDR_ONE_PACKET,
    "MORE_FRAGMENTS" => SOAPY_SDR_MORE_FRAGMENTS,
    "WAIT_TRIGGER" => SOAPY_SDR_WAIT_TRIGGER,
)

function flags_to_set(flags)
    s = Set{String}()
    for (name, val) in SoapyStreamFlags
        if val & flags != 0
            push!(s, name)
        end
    end
    return s
end
