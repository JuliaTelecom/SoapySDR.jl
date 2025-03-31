"""
    has_hardware_time(::Device, what::String)

Query if the Device has hardware time for the given source.
"""
function has_hardware_time(d::Device, what::String)
    SoapySDRDevice_hasHardwareTime(d, what)
end

"""
    get_hardware_time(::Device, what::String)

Get hardware time for the given source.
"""
function get_hardware_time(d::Device, what::String)
    SoapySDRDevice_getHardwareTime(d, what)
end

"""
    set_hardware_time(::Device, timeNs::Int64 what::String)

Set hardware time for the given source.
"""
function set_hardware_time(d::Device, timeNs::Int64, what::String)
    SoapySDRDevice_setHardwareTime(d, timeNs, what)
end
