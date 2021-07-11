# Interface definition for Soapy SDR devices.
 
using Base.Meta

# General design rules about the API:
# The caller must free non-const array results.

const LL_DISCLAIMER = 
    """
    NOTE: This function is part of the lowlevel libsoapysdr interface.
    For end-users in Julia, the higher-level Julia APIs are preferred
    """

# Forward declaration of device handle
mutable struct SoapySDRDevice
end

# Forward declaration of stream handle
mutable struct SoapySDRStream
end

struct SoapyDeviceError
    msg::String
end

macro check_error(expr)
    quote
        val = $(esc(expr))
        if SoapySDRDevice_lastStatus() == -1
            throw(SoapyDeviceError(unsafe_string(SoapySDRDevice_lastError())))
        end
        val
    end
end

"""
    SoapySDRDevice_lastStatus()

Get the last status code after a Device API call.
The status code is cleared on entry to each Device call.
When an device API call throws, the C bindings catch
the exception, and set a non-zero last status code.
Use lastStatus() to determine success/failure for
Device calls without integer status return codes.

$LL_DISCLAIMER
"""
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
end

# Enumerate a list of available devices on the system.
# param args device construction key/value argument filters
# param [out] length the number of elements in the result.
# return a list of arguments strings, each unique to a device
function SoapySDRDevice_enumerate()
    sz = Ref{Csize_t}()
    kwargs = @check_error ccall((:SoapySDRDevice_enumerate, lib), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, sz)
    return (kwargs, sz[])
end

# Enumerate a list of available devices on the system.
# Markup format for args: "keyA=valA, keyB=valB".
# param args a markup string of key/value argument filters
# param [out] length the number of elements in the result.
# return a list of arguments strings, each unique to a device
function SoapySDRDevice_enumerateStrArgs(args)
    sz = Ref{Csize_t}()
    kwargs = ccall((:SoapySDRDevice_enumerateStrArgs, lib), Ptr{SoapySDRKwargs}, (Cstring, Ref{Csize_t}), args, sz)
    return (kwargs, sz[])
end

"""
    SoapySDRDevice_make(args)

Make a new Device object given device construction args.
The device pointer will be stored in a table so subsequent calls
with the same arguments will produce the same device.
For every call to make, there should be a matched call to unmake.
param args device construction key/value argument map
return a pointer to a new Device object.

$LL_DISCLAIMER
"""
function SoapySDRDevice_make(args)
    return @check_error ccall((:SoapySDRDevice_make, lib), Ptr{SoapySDRDevice}, (Ref{SoapySDRKwargs},), args)
end

# Make a new Device object given device construction args.
# The device pointer will be stored in a table so subsequent calls
# with the same arguments will produce the same device.
# For every call to make, there should be a matched call to unmake.
#
# param args a markup string of key/value arguments
# return a pointer to a new Device object or null for error
function SoapySDRDevice_makeStrArgs(args) # have not checked
    ccall((:SoapySDRDevice_makeStrArgs, lib), Ptr{SoapySDRDevice}, (Cstring,), args)
end

# Unmake or release a device object handle.
# param device a pointer to a device object
# return 0 for success or error code on failure
function SoapySDRDevice_unmake(device) # have not checked
    ccall((:SoapySDRDevice_unmake, lib), Cint, (Ptr{SoapySDRDevice},), device)
end

######################
## PARALLEL SUPPORT ##      # have not checked any of these
######################

# Create a list of devices from a list of construction arguments.
# This is a convenience call to parallelize device construction,
# and is fundamentally a parallel for loop of make(Kwargs).
#
# \param argsList a list of device arguments per each device
# \param length the length of the argsList array
# \return a list of device pointers per each specified argument
function SoapySDRDevice_make_list(argsList, length::Cint) 
    ccall((:SoapySDRDevice_make_list, lib), Ptr{Ptr{SoapySDRDevice}}, (Ptr{Cint}, Cint), argsList, length)
end

# Unmake or release a list of device handles
# and free the devices array memory as well.
# This is a convenience call to parallelize device destruction,
# and is fundamentally a parallel for loop of unmake(Device *).
# param devices a list of pointers to device objects
# param length the length of the devices array
# return 0 for success or error code on failure
function SoapySDRDevice_unmake_list(devices, length::Cint)
    ccall((:SoapySDRDevice_unmake_list, lib), Cint, (Ptr{Ptr{SoapySDRDevice}}, Cint), devices, length)
end

########################
## Identification API ##    # have not checked any of these
########################

# A key that uniquely identifies the device driver.
# This key identifies the underlying implementation.
# Serveral variants of a product may share a driver.
# param device a pointer to a device instance
function SoapySDRDevice_getDriverKey(device)
    ccall((:SoapySDRDevice_getDriverKey, lib), Cstring, (Ptr{SoapySDRDevice},), device)
end

# A key that uniquely identifies the hardware.
# This key should be meaningful to the user
# to optimize for the underlying hardware.
# \param device a pointer to a device instance
function SoapySDRDevice_getHardwareKey(device)
    ccall((:SoapySDRDevice_getHardwareKey, lib), Cstring, (Ptr{SoapySDRDevice},), device)
end

# Query a dictionary of available device information.
# This dictionary can any number of values like
# vendor name, product name, revisions, serials...
# This information can be displayed to the user
# to help identify the instantiated device.
# \param device a pointer to a device instance
function SoapySDRDevice_getHardwareInfo(device)
    ccall((:SoapySDRDevice_getHardwareInfo, lib), SoapySDRKwargs, (Ptr{SoapySDRDevice},), device)
end

# Get a number of channels given the streaming direction
# param device a pointer to a device instance
# param direction the channel direction RX or TX
# return the number of channels
function SoapySDRDevice_getNumChannels(device, direction)
    num_channels = ccall((:SoapySDRDevice_getNumChannels, lib), Csize_t, (Ptr{SoapySDRDevice}, Cint), device, direction)
    return Int(num_channels)
end

const CHANNEL_ARGS = """
*  `device` a pointer to a device instance
*  `direction` the channel direction RX or TX
*  `channel` the channel number to get info for
"""

"""
    SoapySDRDevice_getChannelInfo(device, direction, channel)

Get channel info given the streaming direction
$CHANNEL_ARGS

Returns channel information

$LL_DISCLAIMER
"""
function SoapySDRDevice_getChannelInfo(device, direction, channel);
    return @check_error ccall((:SoapySDRDevice_getChannelInfo, lib), SoapySDRKwargs, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

#################
## ANTENNA API ##
#################

"""
Get a list of available antennas to select on a given chain.

$CHANNEL_ARGS

returns a list of available antenna names

$LL_DISCLAIMER
"""
function SoapySDRDevice_listAntennas(device, direction, channel)
    num_antennas = Ref{Csize_t}()
    names = @check_error ccall((:SoapySDRDevice_listAntennas, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, num_antennas)
    return (names, num_antennas[])
end

##############
## GAIN API ##
##############

# List available amplification elements.
# Elements should be in order RF to baseband.
# param device a pointer to a device instance
# param direction the channel direction RX or TX
# param channel an available channel
# param [out] length the number of gain names
# return a list of gain string names
function SoapySDRDevice_listGains(device, direction, channel)
    num_gains = Ref{Csize_t}()
    names = @check_error ccall((:SoapySDRDevice_listGains, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, num_gains)
    names, num_gains[]
end

function SoapySDRDevice_getGainElement(device, direction, channel, name)
    return @check_error ccall((:SoapySDRDevice_getGainElement, lib), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring),
        device, direction, channel, name)
end

function SoapySDRDevice_setGainElement(device, direction, channel, name, val)
    err = @check_error ccall((:SoapySDRDevice_getGainElement, lib), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring, Cdouble),
        device, direction, channel, name, val)
    @assert err == 0
    return nothing
end

#=
"""
Get the overall value of the gain elements in a chain.

$CHANNEL_ARGS

Returns the value of the gain in dB
"""
function SoapySDRDevice_getGain(device, direction, channel)
    return @check_error ccall((:SoapySDRDevice_getGain, lib), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t),
        device, direction, channel)
end
=#

"""
Get the overall range of possible gain values

$CHANNEL_ARGS

Returns the range of possible gain values for this channel in dB
"""
function SoapySDRDevice_getGainRange(device, direction, channel)
    range = @check_error ccall((:SoapySDRDevice_getGainRange, lib), SoapySDRRange, (Ptr{SoapySDRDevice}, Cint, Csize_t),
        device, direction, channel)
    return range
end

"""
    SoapySDRDevice_getGainElementRange(device, direction, channel, name)

    Get the range of possible gain values for a specific element.

$CHANNEL_ARGS
* `name` the name of an amplification element

Returns the range of possible gain values for the specified amplification element in dB

$LL_DISCLAIMER
"""
function SoapySDRDevice_getGainElementRange(device, direction, channel, name)
    range = @check_error ccall((:SoapySDRDevice_getGainElementRange, lib), SoapySDRRange, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring),
        device, direction, channel, name)
    return range
end

###################
## FREQUENCY API ##
###################

# Get the range of overall frequency values.
# param device a pointer to a device instance
# param direction the channel direction RX or TX
# param channel an available channel on the device
# param [out] length the number of ranges
# return a list of frequency ranges in Hz
function SoapySDRDevice_getFrequencyRange(device, direction, channel)
    num_ranges = Ref{Csize_t}()
    ranges = ccall((:SoapySDRDevice_getFrequencyRange, lib), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, num_ranges)
    num_ranges = Int(num_ranges[])
    ranges = unsafe_wrap(Array, ranges, num_ranges)
    return (ranges, num_ranges)
end

###################
## FREQUENCY API ##
###################

# Set the center frequency of the chain.
#  - For RX, this specifies the down-conversion frequency.
#  - For TX, this specifies the up-conversion frequency.
# The default implementation of setFrequency() will tune the "RF"
# component as close as possible to the requested center frequency.
# Tuning inaccuracies will be compensated for with the "BB" component.
# The args can be used to augment the tuning algorithm.
#  - Use "OFFSET" to specify an "RF" tuning offset,
#    usually with the intention of moving the LO out of the passband.
#    The offset will be compensated for using the "BB" component.
#  - Use the name of a component for the key and a frequency in Hz
#    as the value (any format) to enforce a specific frequency.
#    The other components will be tuned with compensation
#    to achieve the specified overall frequency.
#  - Use the name of a component for the key and the value "IGNORE"
#    so that the tuning algorithm will avoid altering the component.
#  - Vendor specific implementations can also use the same args to augment
#    tuning in other ways such as specifying fractional vs integer N tuning.
# param device a pointer to a device instance
# param direction the channel direction RX or TX
# param channel an available channel on the device
# param frequency the center frequency in Hz
# param args optional tuner arguments
# return an error code or 0 for success
function SoapySDRDevice_setFrequency(device, direction, channel, frequency)
    ccall((:SoapySDRDevice_setFrequency, lib), Int, (Ref{SoapySDRDevice}, Cint, Csize_t, Cdouble, Ptr{Nothing}), device, direction, channel, frequency, C_NULL)
end

################
## STREAM API ##
################

# Initialize a stream given a list of channels and stream arguments.
# The implementation may change switches or power-up components.
# All stream API calls should be usable with the new stream object
# after setupStream() is complete, regardless of the activity state.
#
# The API allows any number of simultaneous TX and RX streams, but many dual-channel
# devices are limited to one stream in each direction, using either one or both channels.
# This call will return an error if an unsupported combination is requested,
# or if a requested channel in this direction is already in use by another stream.
#
# When multiple channels are added to a stream, they are typically expected to have
# the same sample rate. See SoapySDRDevice_setSampleRate().
#
# param device a pointer to a device instance
# param [out] stream the opaque pointer to a stream handle.
#
# The returned stream is not required to have internal locking, and may not be used
# concurrently from multiple threads.
#
# param direction the channel direction (`SOAPY_SDR_RX` or `SOAPY_SDR_TX`)
# param format A string representing the desired buffer format in read/writeStream()
# parblock
#
# The first character selects the number type:
#   - "C" means complex
#   - "F" means floating point
#   - "S" means signed integer
#   - "U" means unsigned integer
#
# The type character is followed by the number of bits per number (complex is 2x this size per sample)
#
#  Example format strings:
#   - "CF32" -  complex float32 (8 bytes per element)
#   - "CS16" -  complex int16 (4 bytes per element)
#   - "CS12" -  complex int12 (3 bytes per element)
#   - "CS4" -  complex int4 (1 byte per element)
#   - "S32" -  int32 (4 bytes per element)
#   - "U8" -  uint8 (1 byte per element)
#
# endparblock
# param channels a list of channels or empty for automatic
# param numChans the number of elements in the channels array
# param args stream args or empty for defaults
# parblock
#
#   Recommended keys to use in the args dictionary:
#    - "WIRE" - format of the samples between device and host
# endparblock
# return 0 for success or error code on failure
function SoapySDRDevice_setupStream(device, stream, direction, format, channels, numChans)
    ccall((:SoapySDRDevice_setupStream, lib), Int, (Ref{SoapySDRDevice}, Ref{Ref{SoapySDRStream}}, Cint, Cstring, Ref{Csize_t}, Csize_t, Ptr{Nothing}), device, stream, direction, format, channels, numChans, C_NULL)
end

# Activate a stream.
# Call activate to prepare a stream before using read/write().
# The implementation control switches or stimulate data flow.
#
# The timeNs is only valid when the flags have SOAPY_SDR_HAS_TIME.
# The numElems count can be used to request a finite burst size.
# The SOAPY_SDR_END_BURST flag can signal end on the finite burst.
# Not all implementations will support the full range of options.
# In this case, the implementation returns SOAPY_SDR_NOT_SUPPORTED.
#
# param device a pointer to a device instance
# param stream the opaque pointer to a stream handle
# param flags optional flag indicators about the stream
# param timeNs optional activation time in nanoseconds
# param numElems optional element count for burst control
# return 0 for success or error code on failure
function SoapySDRDevice_activateStream(device, stream, flags, timeNs, numElems)
    ccall((:SoapySDRDevice_activateStream, lib), Cint, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}, Cint, Clonglong, Csize_t), device, stream, flags, timeNs, numElems)
end

# Read elements from a stream for reception.
# This is a multi-channel call, and buffs should be an array of void *,
# where each pointer will be filled with data from a different channel.
#
# **Client code compatibility:**
# The readStream() call should be well defined at all times,
# including prior to activation and after deactivation.
# When inactive, readStream() should implement the timeout
# specified by the caller and return SOAPY_SDR_TIMEOUT.
#
# param device a pointer to a device instance
# param stream the opaque pointer to a stream handle
# param buffs an array of void* buffers num chans in size
# param numElems the number of elements in each buffer
# param [out] flags optional flag indicators about the result
# param [out] timeNs the buffer's timestamp in nanoseconds
# param timeoutUs the timeout in microseconds
# return the number of elements read per buffer or error code
function SoapySDRDevice_readStream(device, stream, buffs, numElems, flags, timeNs, timeoutUs)
    ccall((:SoapySDRDevice_readStream, lib), Cint, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}, Ptr{Ptr{Cvoid}}, Csize_t, Ptr{Cint}, Ptr{Clonglong}, Clong), device, stream, map(pointer, buffs), numElems, flags, timeNs, timeoutUs) 
end

# Deactivate a stream.
# Call deactivate when not using using read/write().
# The implementation control switches or halt data flow.
#
# The timeNs is only valid when the flags have SOAPY_SDR_HAS_TIME.
# Not all implementations will support the full range of options.
# In this case, the implementation returns SOAPY_SDR_NOT_SUPPORTED.
#
# param device a pointer to a device instance
# param stream the opaque pointer to a stream handle
# param flags optional flag indicators about the stream
# param timeNs optional deactivation time in nanoseconds
# return 0 for success or error code on failure
function SoapySDRDevice_deactivateStream(device, stream, flags, timeNs)
    ccall((:SoapySDRDevice_deactivateStream, lib), Cint, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}, Cint, Clonglong), device, stream, flags, timeNs)
end

# Close an open stream created by setupStream
# param device a pointer to a device instance
# param stream the opaque pointer to a stream handle
# return 0 for success or error code on failure
function SoapySDRDevice_closeStream(device, stream)
    ccall((:SoapySDRDevice_closeStream, lib), Cint, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}), device, stream)
end

### Various channel queries
for (prop, T, may_be_missing, desc) in [
        (:DCOffsetMode, Bool, true, "automatic DC offset corrections mode"),
        (:IQBalanceMode, Bool, true, "automatic IQ balance corrections mode"),
        (:GainMode, Bool, true, "automatic gain control mode"),
        (:FrequencyCorrection, Cdouble, true, "frontend frequency correction"),
        (:Gain, Cdouble, false, "gain in dB"),
        (:Antenna, Cstring, false, "selected antenna"),
        (:Bandwidth, Cdouble, false, "bandwidth in Hz"),
        (:SampleRate, Cdouble, false, "sample rate in Hz"),
    ]

    has_sym = Symbol(string("SoapySDRDevice_has"), prop)
    get_sym = Symbol(string("SoapySDRDevice_get"), prop)
    set_sym = Symbol(string("SoapySDRDevice_set"), prop)

    if may_be_missing
        """
        Does the device suppport $desc

        $CHANNEL_ARGS

        $LL_DISCLAIMER
        """
        @eval function ($has_sym)(device, direction, channel)
            return ccall(($(quot(has_sym)), lib), Bool, (Ref{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
        end
    end

    """
    Get the $desc.

    $CHANNEL_ARGS

    Returns the $desc.

    $LL_DISCLAIMER
    """
    @eval function ($get_sym)(device, direction, channel)
        return ccall(($(quot(get_sym)), lib), $T, (Ref{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
    end

    """
    Set the $desc.

    $CHANNEL_ARGS
    * `value` set the $desc to this `value`

    $LL_DISCLAIMER
    """
    @eval function ($set_sym)(device, direction, channel, value)
        return ccall(($(quot(set_sym)), lib), Cint, (Ref{SoapySDRDevice}, Cint, Csize_t, $T), device, direction, channel, value)
    end
end

for (prop, desc) in [
    (:IQBalance, "frontend IQ balance correction"),
    (:DCOffset, "frontend DC offset correction")
]

    has_sym = Symbol(string("SoapySDRDevice_has"), prop)
    get_sym = Symbol(string("SoapySDRDevice_get"), prop)
    set_sym = Symbol(string("SoapySDRDevice_set"), prop)


    """
    Does the device suppport $desc?

    $CHANNEL_ARGS
    $LL_DISCLAIMER
    """
    @eval function ($has_sym)(device, direction, channel)
        return @check_error ccall(($(quot(has_sym)), lib), Bool, (Ref{SoapySDRDevice}, Cint, Csize_t),
            device, direction, channel)
    end

    """
    Get the $desc.

    $CHANNEL_ARGS
    $LL_DISCLAIMER
    """
    @eval function ($get_sym)(device, direction, channel)
        i = Ref{Cdouble}()
        q = Ref{Cdouble}()
        @check_error ccall(($(quot(get_sym)), lib), Cint, (Ref{SoapySDRDevice}, Cint, Csize_t, Ref{Cdouble}, Ref{Cdouble}),
            device, direction, channel, i, q)
        (i[], q[])
    end

    """
    Set the $desc.

    $CHANNEL_ARGS
    $LL_DISCLAIMER
    """
    @eval function ($set_sym)(device, direction, channel, i, q)
        @check_error ccall(($(quot(set_sym)), lib), Cint, (Ref{SoapySDRDevice}, Cint, Csize_t, Cdouble, Cdouble),
            device, direction, channel, i, q)
    end
end

function SoapySDRDevice_getBandwidthRange(device, direction, channel)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_getBandwidthRange, lib), Ptr{SoapySDRRange}, (Ref{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, len)
    (ptr, len[])
end