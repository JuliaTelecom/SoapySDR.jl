"""
    get_sensor_info(::Device, ::String)

Read the sensor extracted from `list_sensors`.
Returns: the value as a string.
Note: Appropriate conversions need to be done by the user.
"""
function get_sensor_info(d::Device, name)
    SoapySDRDevice_getSensorInfo(d.ptr, name)
end
