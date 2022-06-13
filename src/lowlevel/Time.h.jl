"""
    SoapySDR_ticksToTimeNs(ticks, rate)

Convert a tick count into a time in nanoseconds using the tick rate.
\\param ticks a integer tick count
\\param rate the ticks per second
\\return the time in nanoseconds
"""
function SoapySDR_ticksToTimeNs(ticks, rate)
    ccall((:SoapySDR_ticksToTimeNs, soapysdr), Clonglong, (Clonglong, Cdouble), ticks, rate)
end

"""
    SoapySDR_timeNsToTicks(timeNs, rate)

Convert a time in nanoseconds into a tick count using the tick rate.
\\param timeNs time in nanoseconds
\\param rate the ticks per second
\\return the integer tick count
"""
function SoapySDR_timeNsToTicks(timeNs, rate)
    ccall((:SoapySDR_timeNsToTicks, soapysdr), Clonglong, (Clonglong, Cdouble), timeNs, rate)
end

