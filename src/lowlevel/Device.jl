# Interface definition for Soapy SDR devices.
 
using Base.Meta

# General design rules about the API:
# The caller must free non-const array results.

const LL_DISCLAIMER = 
    """
    NOTE: This function is part of the lowlevel libsoapysdr interface.
    For end-users in Julia, the higher-level Julia APIs are preferred
    """

const CHANNEL_ARGS = 
    """
    `device` a pointer to a device instance
    `direction` the channel direction RX or TX
    `channel` the channel number to get info for
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

"""
Get the last error message after a device call fails.
When an device API call throws, the C bindings catch
the exception, store its message in thread-safe storage,
and return a non-zero status code to indicate failure.
Use lastError() to access the exception's error message.
"""
function SoapySDRDevice_lastError()
    ccall((:SoapySDRDevice_lastError, lib), Cstring, ())
end

"""
Enumerate a list of available devices on the system.
param args device construction key/value argument filters
param [out] length the number of elements in the result.
return a list of arguments strings, each unique to a device
"""
function SoapySDRDevice_enumerate()
    sz = Ref{Csize_t}()
    kwargs = @check_error ccall((:SoapySDRDevice_enumerate, lib), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, sz)
    return (kwargs, sz[])
end

"""
Enumerate a list of available devices on the system.
Markup format for args: "keyA=valA, keyB=valB".
param args a markup string of key/value argument filters
param [out] length the number of elements in the result.
return a list of arguments strings, each unique to a device
"""
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

"""
Make a new Device object given device construction args.
The device pointer will be stored in a table so subsequent calls
with the same arguments will produce the same device.
For every call to make, there should be a matched call to unmake.

param args a markup string of key/value arguments
return a pointer to a new Device object or null for error
"""
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

"""
Create a list of devices from a list of construction arguments.
This is a convenience call to parallelize device construction,
and is fundamentally a parallel for loop of make(Kwargs).
param argsList a list of device arguments per each device
param length the length of the argsList array
return a list of device pointers per each specified argument
"""
function SoapySDRDevice_make_list(argsList, length::Cint) 
    ccall((:SoapySDRDevice_make_list, lib), Ptr{Ptr{SoapySDRDevice}}, (Ptr{Cint}, Cint), argsList, length)
end

"""
Unmake or release a list of device handles
and free the devices array memory as well.
This is a convenience call to parallelize device destruction,
and is fundamentally a parallel for loop of unmake(Device *).
param devices a list of pointers to device objects
param length the length of the devices array
return 0 for success or error code on failure
"""
function SoapySDRDevice_unmake_list(devices, length::Cint)
    ccall((:SoapySDRDevice_unmake_list, lib), Cint, (Ptr{Ptr{SoapySDRDevice}}, Cint), devices, length)
end

########################
## Identification API ##
########################

"""
A key that uniquely identifies the device driver.
This key identifies the underlying implementation.
Serveral variants of a product may share a driver.
param device a pointer to a device instance
"""
function SoapySDRDevice_getDriverKey(device)
    ccall((:SoapySDRDevice_getDriverKey, lib), Cstring, (Ptr{SoapySDRDevice},), device)
end

"""
A key that uniquely identifies the hardware.
This key should be meaningful to the user
to optimize for the underlying hardware.
param device a pointer to a device instance
"""
function SoapySDRDevice_getHardwareKey(device)
    ccall((:SoapySDRDevice_getHardwareKey, lib), Cstring, (Ptr{SoapySDRDevice},), device)
end

"""
Query a dictionary of available device information.
This dictionary can any number of values like
vendor name, product name, revisions, serials...
This information can be displayed to the user
to help identify the instantiated device.

param device a pointer to a device instance
"""
function SoapySDRDevice_getHardwareInfo(device)
    ccall((:SoapySDRDevice_getHardwareInfo, lib), SoapySDRKwargs, (Ptr{SoapySDRDevice},), device)
end

##################
## Channels API ##
##################

"""
Set the frontend mapping of available DSP units to RF frontends.
This mapping controls channel mapping and channel availability.

param device a pointer to a device instance
param direction the channel direction RX or TX
param mapping a vendor-specific mapping string
return an error code or 0 for success
"""
function SoapySDRDevice_setFrontendMapping(device, direction, mapping)
    #SOAPY_SDR_API int SoapySDRDevice_setFrontendMapping(SoapySDRDevice *device, const int direction, const char *mapping);
    ccall((:SoapySDRDevice_setFrontendMapping, lib), Cint, (Ptr{SoapySDRDevice}, Cint, Cstring), device, direction, mapping)
end

"""
Get the mapping configuration string.

param device a pointer to a device instance
param direction the channel direction RX or TX
return the vendor-specific mapping string
"""
function SoapySDRDevice_getFrontendMapping(device, direction)
    #SOAPY_SDR_API char *SoapySDRDevice_getFrontendMapping(const SoapySDRDevice *device, const int direction);
    ccall((:SoapySDRDevice_getFrontendMapping, lib), Cstring, (Ptr{SoapySDRDevice}, Cint), device, direction)
end

"""
Get a number of channels given the streaming direction

param device a pointer to a device instance
param direction the channel direction RX or TX
return the number of channels
"""
function SoapySDRDevice_getNumChannels(device, direction)
    ccall((:SoapySDRDevice_getNumChannels, lib), Csize_t, (Ptr{SoapySDRDevice}, Cint), device, direction)
end


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

"""
Find out if the specified channel is full or half duplex.

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
return true for full duplex, false for half duplex
"""
function SoapySDRDevice_getFullDuplex(device, direction, channel)
    #SOAPY_SDR_API bool SoapySDRDevice_getFullDuplex(const SoapySDRDevice *device, const int direction, const size_t channel);
    ccall((:SoapySDRDevice_getFullDuplex, lib), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
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

"""
List available amplification elements.
Elements should be in order RF to baseband.
param: device a pointer to a device instance
param: direction the channel direction RX or TX
param: channel an available channel
param: [out] length the number of gain names

return a list of gain string names
"""
function SoapySDRDevice_listGains(device, direction, channel)
    num_gains = Ref{Csize_t}()
    names = @check_error ccall((:SoapySDRDevice_listGains, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, num_gains)
    names, num_gains[]
end

function SoapySDRDevice_getGainElement(device, direction, channel, name)
    return @check_error ccall((:SoapySDRDevice_getGainElement, lib), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring),
        device, direction, channel, name)
end


"""
Set the value of a amplification element in a chain.

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
param name the name of an amplification element
param value the new amplification value in dB
return an error code or 0 for success
"""
function SoapySDRDevice_setGainElement(device, direction, channel, name, val)
    # note: the C API does not match the C++ API. c++ returns void here w/o error code
    @check_error ccall((:SoapySDRDevice_getGainElement, lib), Cvoid, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring, Cdouble),
        device, direction, channel, name, val)
    return nothing
end

#=
TODO

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

"""
Set the center frequency of the chain.
 - For RX, this specifies the down-conversion frequency.
 - For TX, this specifies the up-conversion frequency.
The default implementation of setFrequency() will tune the "RF"
component as close as possible to the requested center frequency.
Tuning inaccuracies will be compensated for with the "BB" component.
The args can be used to augment the tuning algorithm.
 - Use "OFFSET" to specify an "RF" tuning offset,
   usually with the intention of moving the LO out of the passband.
   The offset will be compensated for using the "BB" component.
 - Use the name of a component for the key and a frequency in Hz
   as the value (any format) to enforce a specific frequency.
   The other components will be tuned with compensation
   to achieve the specified overall frequency.
 - Use the name of a component for the key and the value "IGNORE"
   so that the tuning algorithm will avoid altering the component.
 - Vendor specific implementations can also use the same args to augment
   tuning in other ways such as specifying fractional vs integer N tuning.
param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
param frequency the center frequency in Hz
param args optional tuner arguments
return an error code or 0 for success
"""
function SoapySDRDevice_setFrequency(device, direction, channel, frequency, kwargs)
    ccall((:SoapySDRDevice_setFrequency, lib), Int, (Ref{SoapySDRDevice}, Cint, Csize_t, Cdouble, Ptr{SoapySDRKwargs}), device, direction, channel, frequency, kwargs)
end

################
## STREAM API ##
################

"""
Query a list of the available stream formats.

$CHANNEL_ARGS

Returns a list of allowed format strings.

$LL_DISCLAIMER
"""
function SoapySDRDevice_getStreamFormats(device, direction, channel)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_getStreamFormats, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, len)
    ptr, len[]
end

"""
Get the hardware's native stream format for this channel.
This is the format used by the underlying transport layer,
and the direct buffer access API calls (when available).

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
param [out] fullScale the maximum possible value
return the native stream buffer format string
"""
function SoapySDRDevice_getNativeStreamFormat(device, direction, channel)
    #SOAPY_SDR_API char *SoapySDRDevice_getNativeStreamFormat(const SoapySDRDevice *device, const int direction, const size_t channel, double *fullScale);
    fullscale = Ref{Cdouble}()
    fmt = @check_error ccall((:SoapySDRDevice_getNativeStreamFormat, lib), Cstring, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Cdouble}), device, direction, channel, fullscale)
    return fmt, fullscale[]
end

"""
Query the argument info description for stream args.

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
param [out] length the number of argument infos
return a list of argument info structures
"""
function SoapySDRDevice_getStreamArgsInfo(device, direction, channel)
    len = Ref{Csize_t}()
    #SOAPY_SDR_API SoapySDRArgInfo *SoapySDRDevice_getStreamArgsInfo(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
    ptr = @check_error ccall((:SoapySDRDevice_getStreamArgsInfo, lib), Ptr{SoapySDRArgInfo}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, len)
    ptr, len[]
end

"""
Initialize a stream given a list of channels and stream arguments.
The implementation may change switches or power-up components.
All stream API calls should be usable with the new stream object
after setupStream() is complete, regardless of the activity state.

The API allows any number of simultaneous TX and RX streams, but many dual-channel
devices are limited to one stream in each direction, using either one or both channels.
This call will return an error if an unsupported combination is requested,
or if a requested channel in this direction is already in use by another stream.

When multiple channels are added to a stream, they are typically expected to have
the same sample rate. See SoapySDRDevice_setSampleRate().

 * `device` a pointer to a device instance
 * `direction` the channel direction (`SOAPY_SDR_RX` or `SOAPY_SDR_TX`)
 * `format` A string representing the desired buffer format in read/writeStream()

 The first character selects the number type:
   - "C" means complex
   - "F" means floating point
   - "S" means signed integer
   - "U" means unsigned integer

 The type character is followed by the number of bits per number (complex is 2x this size per sample)

  Example format strings:
   - "CF32" -  complex float32 (8 bytes per element)
   - "CS16" -  complex int16 (4 bytes per element)
   - "CS12" -  complex int12 (3 bytes per element)
   - "CS4" -  complex int4 (1 byte per element)
   - "S32" -  int32 (4 bytes per element)
   - "U8" -  uint8 (1 byte per element)

 * `channels` a list of channels or empty for automatic
 * `numChans` the number of elements in the channels array
 * `args` stream args or empty for defaults

Recommended keys to use in the args dictionary:
    - "WIRE" - format of the samples between device and host

Returns the opaque pointer to a stream handle.

# NOTE:
    The returned stream is not required to have internal locking, and may not be used
    concurrently from multiple threads.
"""
function SoapySDRDevice_setupStream(device, direction, format, channels, numChans, kwargs)
    return @check_error ccall((:SoapySDRDevice_setupStream, lib), Ptr{SoapySDRStream}, (Ptr{SoapySDRDevice}, Cint, Cstring, Ptr{Csize_t}, Csize_t, Ptr{SoapySDRKwargs}),
        device, direction, format, channels, numChans, kwargs)
end

"""
Activate a stream.
Call activate to prepare a stream before using read/write().
The implementation control switches or stimulate data flow.

The timeNs is only valid when the flags have SOAPY_SDR_HAS_TIME.
The numElems count can be used to request a finite burst size.
The SOAPY_SDR_END_BURST flag can signal end on the finite burst.
Not all implementations will support the full range of options.
In this case, the implementation returns SOAPY_SDR_NOT_SUPPORTED.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
param flags optional flag indicators about the stream
param timeNs optional activation time in nanoseconds
param numElems optional element count for burst control
return 0 for success or error code on failure
"""
function SoapySDRDevice_activateStream(device, stream, flags, timeNs, numElems)
    err = @check_error ccall((:SoapySDRDevice_activateStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Cint, Clonglong, Csize_t), device, stream, flags, timeNs, numElems)
    if err != 0
        throw(SoapySDRAPIError(err))
    end
    return nothing
end

"""
Get the stream's maximum transmission unit (MTU) in number of elements.
The MTU specifies the maximum payload transfer in a stream operation.
This value can be used as a stream buffer allocation size that can
best optimize throughput given the underlying stream implementation.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
return the MTU in number of stream elements (never zero)
"""
function SoapySDRDevice_getStreamMTU(device, stream)
    mtu = ccall((:SoapySDRDevice_getStreamMTU, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}), device, stream)
    return mtu
end



"""
Read elements from a stream for reception.
This is a multi-channel call, and buffs should be an array of void *,
where each pointer will be filled with data from a different channel.

**Client code compatibility:**
The readStream() call should be well defined at all times,
including prior to activation and after deactivation.
When inactive, readStream() should implement the timeout
specified by the caller and return SOAPY_SDR_TIMEOUT.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
param buffs an array of void* buffers num chans in size
param numElems the number of elements in each buffer
param [out] flags optional flag indicators about the result
param [out] timeNs the buffer's timestamp in nanoseconds
param timeoutUs the timeout in microseconds
return the number of elements read per buffer or error code
"""
function SoapySDRDevice_readStream(device, stream, buffs, numElems, timeoutUs)
    flags = Ref{Cint}()
    timeNs = Ref{Clonglong}()
    nelems = @check_error ccall((:SoapySDRDevice_readStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Ptr{Cvoid}, Csize_t, Ptr{Cint}, Ptr{Clonglong}, Clong),
        device, stream, buffs, numElems, flags, timeNs, timeoutUs)
    if nelems < 0
        throw(SoapySDRAPIError(nelems))
    end
    nelems, flags[], timeNs[]
end

"""
Write elements to a stream for transmission.
This is a multi-channel call, and buffs should be an array of void *,
where each pointer will be filled with data for a different channel.

**Client code compatibility:**
Client code relies on writeStream() for proper back-pressure.
The writeStream() implementation must enforce the timeout
such that the call blocks until space becomes available
or timeout expiration.

* `device` a pointer to a device instance
* `stream` the opaque pointer to a stream handle
* `buffs` an array of void* buffers num chans in size
* `numElems` the number of elements in each buffer
* `flags` optional input flags and output flags
* `timeNs` the buffer's timestamp in nanoseconds
* `timeoutUs` the timeout in microseconds

Returns the number of elements written per buffer, output flags
"""
function SoapySDRDevice_writeStream(device, stream, buffs, numElems, flags, timeNs, timeoutUs)
    flags = Ref{Cint}(flags)
    nelems = @check_error ccall((:SoapySDRDevice_writeStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Ptr{Cvoid}, Csize_t, Ptr{Cint}, Clonglong, Clong),
        device, stream, buffs, numElems, flags, timeNs, timeoutUs)
    if nelems < 0
        throw(SoapySDRAPIError(nelems))
    end
    nelems, flags[]
end

"""
Deactivate a stream.
Call deactivate when not using using read/write().
The implementation control switches or halt data flow.

The timeNs is only valid when the flags have SOAPY_SDR_HAS_TIME.
Not all implementations will support the full range of options.
In this case, the implementation returns SOAPY_SDR_NOT_SUPPORTED.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
param flags optional flag indicators about the stream
param timeNs optional deactivation time in nanoseconds
return 0 for success or error code on failure
"""
function SoapySDRDevice_deactivateStream(device, stream, flags, timeNs)
    ccall((:SoapySDRDevice_deactivateStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Cint, Clonglong), device, stream, flags, timeNs)
end

"""
Close an open stream created by setupStream
param device a pointer to a device instance
param stream the opaque pointer to a stream handle
return 0 for success or error code on failure
"""
function SoapySDRDevice_closeStream(device, stream)
    @check_error ccall((:SoapySDRDevice_closeStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}), device, stream)
end

"""
Readback status information about a stream.
This call is typically used on a transmit stream
to report time errors, underflows, and burst completion.

**Client code compatibility:**
Client code may continually poll readStreamStatus() in a loop.
Implementations of readStreamStatus() should wait in the call
for a status change event or until the timeout expiration.
When stream status is not implemented on a particular stream,
readStreamStatus() should return SOAPY_SDR_NOT_SUPPORTED.
Client code may use this indication to disable a polling loop.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
param chanMask to which channels this status applies
param flags optional input flags and output flags
param timeNs the buffer's timestamp in nanoseconds
param timeoutUs the timeout in microseconds
return 0 for success or error code like timeout
"""
function SoapySDRDevice_readStreamStatus(device, stream, channel_mask, flags, timeNs, timeoutUs)
    #SOAPY_SDR_API int SoapySDRDevice_readStreamStatus(SoapySDRDevice *device,
    #    SoapySDRStream *stream,
    #    size_t *chanMask,
    #    int *flags,
    #    long long *timeNs,
    #    const long timeoutUs);

    flags = Ref{Cint}(flags)

    # we really don't want to throw here since it is a check, so we return the "condition", really an "error code"
    # This sometime varies between implementation and so both the flag and "condition" should be checked in the 
    # high level API, though support for this call seems to vary between implementations
    condition = ccall((:SoapySDRDevice_readStreamStatus, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Csize_t, Cint, Clonglong, Clong),
                                                                       device, stream, channel_mask, flags, timeNs, timeoutUs)
    condition, flags[]
end


############################
# Direct buffer access API #
############################

"""
How many direct access buffers can the stream provide?
This is the number of times the user can call acquire()
on a stream without making subsequent calls to release().
A return value of 0 means that direct access is not supported.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
return the number of direct access buffers or 0
"""
function SoapySDRDevice_getNumDirectAccessBuffers(device, stream)
    #SOAPY_SDR_API size_t SoapySDRDevice_getNumDirectAccessBuffers(SoapySDRDevice *device, SoapySDRStream *stream);
    ccall((:SoapySDRDevice_getNumDirectAccessBuffers, lib), Csize_t, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}), device, stream)
end

"""
Get the buffer addresses for a scatter/gather table entry.
When the underlying DMA implementation uses scatter/gather
then this call provides the user addresses for that table.

Example: The caller may query the DMA memory addresses once
after stream creation to pre-allocate a re-usable ring-buffer.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
param handle an index value between 0 and num direct buffers - 1
param buffs an array of void* buffers num chans in size
return 0 for success or error code when not supported
"""
function SoapySDRDevice_getDirectAccessBufferAddrs(device, stream, handle, buffs)
    #SOAPY_SDR_API int SoapySDRDevice_getDirectAccessBufferAddrs(SoapySDRDevice *device, SoapySDRStream *stream, const size_t handle, void **buffs);
    ccall((:SoapySDRDevice_getDirectAccessBufferAddrs, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Csize_t, Ptr{Cvoid}), device, stream, handle, buffs)
end

"""
Acquire direct buffers from a receive stream.
This call is part of the direct buffer access API.

The buffs array will be filled with a stream pointer for each channel.
Each pointer can be read up to the number of return value elements.

The handle will be set by the implementation so that the caller
may later release access to the buffers with releaseReadBuffer().
Handle represents an index into the internal scatter/gather table
such that handle is between 0 and num direct buffers - 1.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
param handle an index value used in the release() call
param buffs an array of void* buffers num chans in size
param flags optional flag indicators about the result
param timeNs the buffer's timestamp in nanoseconds
param timeoutUs the timeout in microseconds
return the number of elements read per buffer or error code
"""
function SoapySDRDevice_acquireReadBuffer(device, stream, handle, buffs, flags, timeNs, timeoutUs)
    #SOAPY_SDR_API int SoapySDRDevice_acquireReadBuffer(SoapySDRDevice *device,
    #    SoapySDRStream *stream,
    #    size_t *handle,
    #    const void **buffs,
    #    int *flags,
    #    long long *timeNs,
    #    const long timeoutUs);
    handle = Ref{Csize_t}(handle)
    flags = Ref{Cint}(flags)
    ccall((:SoapySDRDevice_acquireReadBuffer, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Csize_t, Ptr{Cvoid}, Cint, Clonglong, Clong),
                                                                device, stream, handle, buffs, flags, timeNs, timeoutUs)
    handle, flags[]
end

"""
Release an acquired buffer back to the receive stream.
This call is part of the direct buffer access API.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
param handle the opaque handle from the acquire() call
"""
function SoapySDRDevice_releaseReadBuffer(device, stream, handle)
    #SOAPY_SDR_API void SoapySDRDevice_releaseReadBuffer(SoapySDRDevice *device,
    #    SoapySDRStream *stream,
    #    const size_t handle);
    ccall((:SoapySDRDevice_releaseReadBuffer, lib), Cvoid, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Csize_t), device, stream, handle)
end

"""
Acquire direct buffers from a transmit stream.
This call is part of the direct buffer access API.

The buffs array will be filled with a stream pointer for each channel.
Each pointer can be written up to the number of return value elements.

The handle will be set by the implementation so that the caller
may later release access to the buffers with releaseWriteBuffer().
Handle represents an index into the internal scatter/gather table
such that handle is between 0 and num direct buffers - 1.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
param handle an index value used in the release() call
param buffs an array of void* buffers num chans in size
param timeoutUs the timeout in microseconds
return the number of available elements per buffer or error
"""
function SoapySDRDevice_acquireWriteBuffer(device, stream, handle, buffs, timeoutUs)
    #SOAPY_SDR_API int SoapySDRDevice_acquireWriteBuffer(SoapySDRDevice *device,
    #    SoapySDRStream *stream,
    #    size_t *handle,
    #    void **buffs,
    #    const long timeoutUs);
    handle = Ref{Csize_t}(handle)
    ccall((:SoapySDRDevice_acquireWriteBuffer, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Csize_t, Ptr{Cvoid}, Clong),
                                                    device, stream, handle, buffs, timeoutUs)
end

"""
Release an acquired buffer back to the transmit stream.
This call is part of the direct buffer access API.

Stream meta-data is provided as part of the release call,
and not the acquire call so that the caller may acquire
buffers without committing to the contents of the meta-data,
which can be determined by the user as the buffers are filled.

param device a pointer to a device instance
param stream the opaque pointer to a stream handle
param handle the opaque handle from the acquire() call
param numElems the number of elements written to each buffer
param flags optional input flags and output flags
param timeNs the buffer's timestamp in nanoseconds
"""
function SoapySDRDevice_releaseWriteBuffer(device, stream, handle, numElems, flags, timeNs)
    #SOAPY_SDR_API void SoapySDRDevice_releaseWriteBuffer(SoapySDRDevice *device,
    #    SoapySDRStream *stream,
    #    const size_t handle,
    #    const size_t numElems,
    #    int *flags,
    #    const long long timeNs);
    flags = Ref{Cint}(flags)
    ccall((:SoapySDRDevice_releaseWriteBuffer, lib), Cvoid, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Csize_t, Csize_t, Cint, Clonglong),
                                                device, stream, handle, numElems, flags, timeNs)
    flags[]
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

###################
## FREQUENCY API ##
###################

"""
Get the range of overall frequency values.

$CHANNEL_ARGS

Returns a list of frequency ranges in Hz

$LL_DISCLAIMER
"""
function SoapySDRDevice_getFrequencyRange(device, direction, channel)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_getFrequencyRange, lib), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, len)
    (ptr, len[])
end

"""
Get the range of tunable values for the specified element.

$CHANNEL_ARGS

Returns a list of frequency ranges in Hz

$LL_DISCLAIMER
"""
function SoapySDRDevice_getFrequencyRangeComponent(device, direction, channel, name)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_getFrequencyRangeComponent, lib), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring, Ref{Csize_t}), device, direction, channel, name, len)
    (ptr, len[])
end

"""
Get the range of possible baseband sample rates.

$CHANNEL_ARGS

Returns a list of samples rates in samples per second

$LL_DISCLAIMER
"""
function SoapySDRDevice_getSampleRateRange(device, direction, channel)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_getSampleRateRange, lib), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, len)
    (ptr, len[])
end

"""
Get the list of possible baseband sample rates.

$CHANNEL_ARGS

Returns a list of samples rates in samples per second

$LL_DISCLAIMER
"""
function SoapySDRDevice_listSampleRates(device, direction, channel)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_listSampleRates, lib), Ptr{Float64}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, len)
    (ptr, len[])
end


"""
List available tunable elements in the chain.
Elements should be in order RF to baseband.

$CHANNEL_ARGS

Returns a list of tunable elements by name

$LL_DISCLAIMER
*/
"""
function SoapySDRDevice_listFrequencies(device, direction, channel)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_listFrequencies, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, len)
    ptr, len[]
end

function SoapySDRDevice_getFrequency(device, direction, channel)
    return @check_error ccall((:SoapySDRDevice_getFrequency, lib), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t),
        device, direction, channel)
end

function SoapySDRDevice_getFrequencyComponent(device, direction, channel, name)
    return @check_error ccall((:SoapySDRDevice_getFrequencyComponent, lib), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring),
        device, direction, channel, name)
end

function SoapySDRDevice_setFrequencyComponent(device, direction, channel, name, val)
    err = @check_error ccall((:SoapySDRDevice_setFrequencyComponent, lib), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring, Cdouble),
        device, direction, channel, name, val)
    @assert err == 0
    return nothing
end


##############
## TIME API ##
##############

"""
Get the list of available time sources.

param device a pointer to a device instance
param [out] length the number of sources
return a list of time source names
"""
function SoapySDRDevice_listTimeSources(device)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_listTimeSources, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Ref{Csize_t}), device, len)
    (ptr, len[])
end

"""
Set the time source on the device

param device a pointer to a device instance
param source the name of a time source
return an error code or 0 for success
"""
function SoapySDRDevice_setTimeSource(device, source)
    ptr = @check_error ccall((:SoapySDRDevice_setTimeSource, lib), Cstring, (Ptr{SoapySDRDevice}, Cstring), device, source)
    ptr
end

"""
Get the time source of the device

param device a pointer to a device instance
return the name of a time source
"""
function SoapySDRDevice_getTimeSource(device)
    ptr = @check_error ccall((:SoapySDRDevice_getTimeSource, lib), Cstring, (Ptr{SoapySDRDevice},), device)
    ptr
end

"""
Does this device have a hardware clock?

param device a pointer to a device instance
param what optional argument
return true if the hardware clock exists
"""
function SoapySDRDevice_hasHardwareTime(device, what)
    @check_error ccall((:SoapySDRDevice_hasHardwareTime, lib), Bool, (Ptr{SoapySDRDevice}, Cstring), device, what)
end

"""
Read the time from the hardware clock on the device.
The what argument can refer to a specific time counter.

param device a pointer to a device instance
param what optional argument
return the time in nanoseconds
"""
function SoapySDRDevice_getHardwareTime(device, what)
    @check_error ccall((:SoapySDRDevice_getHardwareTime, lib), Clonglong, (Ptr{SoapySDRDevice}, Cstring), device, what)
end

"""
Write the time to the hardware clock on the device.
The what argument can refer to a specific time counter.

param device a pointer to a device instance
param timeNs time in nanoseconds
param what optional argument
return 0 for success or error code on failure
"""
function SoapySDRDevice_setHardwareTime(device, timeNs, what)
    @check_error ccall((:SoapySDRDevice_setHardwareTime, lib), Cvoid, (Ptr{SoapySDRDevice}, Clonglong, Cstring), device, timeNs, what)
end



##################
## Clocking API ##
##################
"""
Set the master clock rate of the device.

param device a pointer to a device instance
param rate the clock rate in Hz
return an error code or 0 for success
"""
function SoapySDRDevice_setMasterClockRate(device,rate);
    @check_error ccall((:SoapySDRDevice_setMasterClockRate, lib), Cvoid, (Ptr{SoapySDRDevice}, Cdouble), device, rate)
end

"""
Get the master clock rate of the device.

param device a pointer to a device instance
return the clock rate in Hz
"""
function SoapySDRDevice_getMasterClockRate(device)
    @check_error ccall((:SoapySDRDevice_getMasterClockRate, lib), Cdouble, (Ptr{SoapySDRDevice},), device)
end

"""
Get the range of available master clock rates.

param device a pointer to a device instance
param [out] length the number of ranges
return a list of clock rate ranges in Hz
"""
function SoapySDRDevice_getMasterClockRates(device)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_getMasterClockRates, lib), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Ref{Csize_t}), device, len)
    (ptr, len[])
end

"""
Set the reference clock rate of the device.

param device a pointer to a device instance
param rate the clock rate in Hz
return an error code or 0 for success
"""
function SoapySDRDevice_setReferenceClockRate(device, rate)
    @check_error ccall((:SoapySDRDevice_setReferenceClockRate, lib), Cvoid, (Ptr{SoapySDRDevice}, Cdouble), device, rate)
end

"""
Get the reference clock rate of the device.

param device a pointer to a device instance
return the clock rate in Hz
"""
function SoapySDRDevice_getReferenceClockRate(device)
    @check_error ccall((:SoapySDRDevice_getReferenceClockRate, lib), Cdouble, (Ptr{SoapySDRDevice},), device)
end

"""
Get the range of available reference clock rates.

param device a pointer to a device instance

return a list of clock rate ranges in Hz
"""
function SoapySDRDevice_getReferenceClockRates(device)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_getReferenceClockRates, lib), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Ref{Csize_t}), device, len)
    (ptr, len[])
end

"""
Get the list of available clock sources.

param device a pointer to a device instance

return a list of clock source names
"""
function SoapySDRDevice_listClockSources(device)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_listClockSources, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Ref{Csize_t}), device, len)
    (ptr, len[])
end

"""
Set the clock source on the device

param device a pointer to a device instance
param source the name of a clock source
return an error code or 0 for success
"""
function SoapySDRDevice_setClockSource(device, source)
    @check_error ccall((:SoapySDRDevice_setClockSource, lib), Cstring, (Ptr{SoapySDRDevice}, Cstring), device, source)
end

"""
Get the clock source of the device

param device a pointer to a device instance
return the name of a clock source
"""
function SoapySDRDevice_getClockSource(device)
    ptr = @check_error ccall((:SoapySDRDevice_getClockSource, lib), Cstring, (Ptr{SoapySDRDevice},), device)
    ptr
end

################
## SENSOR API ##
################

"""
List the available global readback sensors.
A sensor can represent a reference lock, RSSI, temperature.

param device a pointer to a device instance
param [out] length the number of sensor names
return a list of available sensor string names
"""
function SoapySDRDevice_listSensors(device)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_listSensors, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Ref{Csize_t}), device, len)
    ptr, len[]
end

"""
Get meta-information about a sensor.
Example: displayable name, type, range.

param device a pointer to a device instance
param key the ID name of an available sensor
return meta-information about a sensor
"""
function SoapySDRDevice_getSensorInfo(device, key)
    @check_error ccall((:SoapySDRDevice_getSensorInfo, lib), SoapySDRArgInfo, (Ptr{SoapySDRDevice}, Cstring), device, key)
end

"""
Readback a global sensor given the name.
The value returned is a string which can represent
a boolean ("true"/"false"), an integer, or float.

param device a pointer to a device instance
param key the ID name of an available sensor
return the current value of the sensor
"""
function SoapySDRDevice_readSensor(device, key)
    @check_error ccall((:SoapySDRDevice_readSensor, lib), Cstring, (Ptr{SoapySDRDevice}, Cstring), device, key)
end

"""
List the available channel readback sensors.
A sensor can represent a reference lock, RSSI, temperature.

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device

return a list of available sensor string names
"""
function SoapySDRDevice_listChannelSensors(device, direction, channel)
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_listSensors, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, len)
    (ptr, len[])
end

"""
Get meta-information about a channel sensor.
Example: displayable name, type, range.

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
param key the ID name of an available sensor
return meta-information about a sensor
"""
function SoapySDRDevice_getChannelSensorInfo(device, direction, channel, key)
    @check_error ccall((:SoapySDRDevice_getChannelSensorInfo, lib), SoapySDRArgInfo, (Ptr{SoapySDRArgInfo}, Cint, Csize_t, Cstring), device, direction, channel, key)
end

"""
Readback a channel sensor given the name.
The value returned is a string which can represent
a boolean ("true"/"false"), an integer, or float.

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
param key the ID name of an available sensor
return the current value of the sensor
"""
function SoapySDRDevice_readChannelSensor(device, direction, channel, key)
    @check_error ccall((:SoapySDRDevice_readChannelSensor, lib), Cstring, (Ptr{SoapySDRArgInfo}, Cint, Csize_t, Cstring), device, direction, channel, key)
end

#################
## SETTINGSAPI ##
#################


"""
Describe the allowed keys and values used for settings.

param device a pointer to a device instance
param [out] length the number of sensor names
return a list of argument info structures
"""
function SoapySDRDevice_getSettingInfo(device)
    #SOAPY_SDR_API SoapySDRArgInfo *SoapySDRDevice_getSettingInfo(const SoapySDRDevice *device, size_t *length);
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_getSettingInfo, lib), Ptr{SoapySDRArgInfo}, (Ptr{SoapySDRDevice}, Ref{Csize_t}), device, len)
    (ptr, len[])
end

"""
Write an arbitrary setting on the device.
The interpretation is up the implementation.

param device a pointer to a device instance
param key the setting identifier
param value the setting value
return 0 for success or error code on failure
"""
function SoapySDRDevice_writeSetting(device, key, value)
    #SOAPY_SDR_API int SoapySDRDevice_writeSetting(SoapySDRDevice *device, const char *key, const char *value);
    @check_error ccall((:SoapySDRDevice_writeSetting, lib), Cint, (Ptr{SoapySDRDevice}, Cstring, Cstring), device, key, value)
end

"""
Read an arbitrary setting on the device.

param device a pointer to a device instance
param key the setting identifier
return the setting value
"""
function SoapySDRDevice_readSetting(device, key)
    #SOAPY_SDR_API char *SoapySDRDevice_readSetting(const SoapySDRDevice *device, const char *key);
    @check_error ccall((:SoapySDRDevice_readSetting, lib), Cstring, (Ptr{SoapySDRDevice}, Cstring), device, key)
end


"""
Describe the allowed keys and values used for channel settings.

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
param [out] length the number of sensor names
return a list of argument info structures
"""
function SoapySDRDevice_getChannelSettingInfo(device, direction, channel)
    #SOAPY_SDR_API SoapySDRArgInfo *SoapySDRDevice_getChannelSettingInfo(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_getChannelSettingInfo, lib), Ptr{SoapySDRArgInfo}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, len)
    (ptr, len[])
end

"""
Write an arbitrary channel setting on the device.
The interpretation is up the implementation.

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
param key the setting identifier
param value the setting value
return 0 for success or error code on failure
"""
function SoapySDRDevice_writeChannelSetting(device, direction, channel, key, value)
    #SOAPY_SDR_API int SoapySDRDevice_writeChannelSetting(SoapySDRDevice *device, const int direction, const size_t channel, const char *key, const char *value);
    @check_error ccall((:SoapySDRDevice_writeChannelSetting, lib), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring, Cstring), device, direction, channel, key, value)
end

"""
Read an arbitrary channel setting on the device.

param device a pointer to a device instance
param direction the channel direction RX or TX
param channel an available channel on the device
param key the setting identifier
return the setting value
"""
function SoapySDRDevice_readChannelSetting(device, direction, channel, key)
    #SOAPY_SDR_API char *SoapySDRDevice_readChannelSetting(const SoapySDRDevice *device, const int direction, const size_t channel, const char *key);
    @check_error ccall((:SoapySDRDevice_readChannelSetting, lib), Cstring, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cstring), device, direction, channel, key)
end


##############
#Register API
##############

"""
Get a list of available register interfaces by name.

param device a pointer to a device instance
param [out] length the number of interfaces
return a list of available register interfaces
"""
function SoapySDRDevice_listRegisterInterfaces(device)
    #SOAPY_SDR_API char **SoapySDRDevice_listRegisterInterfaces(const SoapySDRDevice *device, size_t *length);
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_listRegisterInterfaces, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Ref{Csize_t}), device, len)
    (ptr, len[])
end

"""
Write a register on the device given the interface name.
This can represent a register on a soft CPU, FPGA, IC;
the interpretation is up the implementation to decide.

param device a pointer to a device instance
param name the name of a available register interface
param addr the register address
param value the register value
return 0 for success or error code on failure
"""
function SoapySDRDevice_writeRegister(device, name, addr, value)
    #SOAPY_SDR_API int SoapySDRDevice_writeRegister(SoapySDRDevice *device, const char *name, const unsigned addr, const unsigned value);
    @check_error ccall((:SoapySDRDevice_writeRegister, lib), Cint, (Ptr{SoapySDRDevice}, Cstring, Csize_t, Csize_t), device, name, addr, value)
end

"""
Read a register on the device given the interface name.

param device a pointer to a device instance
param name the name of a available register interface
param addr the register address
return the register value
"""
function SoapySDRDevice_readRegister(device, name, addr)
    #SOAPY_SDR_API unsigned SoapySDRDevice_readRegister(const SoapySDRDevice *device, const char *name, const unsigned addr);
    @check_error ccall((:SoapySDRDevice_readRegister, lib), Csize_t, (Ptr{SoapySDRDevice}, Cstring, Csize_t), device, name, addr)
end

"""
Write a memory block on the device given the interface name.
This can represent a memory block on a soft CPU, FPGA, IC;
the interpretation is up the implementation to decide.

param device a pointer to a device instance
param name the name of a available memory block interface
param addr the memory block start address
param value the memory block content
param length the number of words in the block
return 0 for success or error code on failure
"""
function SoapySDRDevice_writeMemory(device, name, addr, value, length)
    #SOAPY_SDR_API int SoapySDRDevice_writeRegisters(SoapySDRDevice *device, const char *name, const unsigned addr, const unsigned *value, const size_t length);
    @check_error ccall((:SoapySDRDevice_writeMemory, lib), Cint, (Ptr{SoapySDRDevice}, Cstring, Csize_t, Csize_t, Ptr{Csize_t}), device, name, addr, value, length)
end

"""
Read a memory block on the device given the interface name.
Pass the number of words to be read in via length;
length will be set to the number of actual words read.

param device a pointer to a device instance
param name the name of a available memory block interface
param addr the memory block start address
param [in,out] length number of words to be read from memory block
return the memory block content
"""
function SoapySDRDevice_readRegisters(device, name, addr, length)
    #SOAPY_SDR_API unsigned *SoapySDRDevice_readRegisters(const SoapySDRDevice *device, const char *name, const unsigned addr, size_t *length);
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDRDevice_readRegisters, lib), Ptr{Csize_t}, (Ptr{SoapySDRDevice}, Cstring, Csize_t, Ref{Csize_t}), device, name, addr, len)
    (ptr, len[])
end

##############
# GPIO API
##############

"""
Get a list of available GPIO banks by name.

param [out] length the number of GPIO banks
param device a pointer to a device instance
"""
#SOAPY_SDR_API char **SoapySDRDevice_listGPIOBanks(const SoapySDRDevice *device, size_t *length);

"""
Write the value of a GPIO bank.

param device a pointer to a device instance
param bank the name of an available bank
param value an integer representing GPIO bits
return 0 for success or error code on failure
"""
#SOAPY_SDR_API int SoapySDRDevice_writeGPIO(SoapySDRDevice *device, const char *bank, const unsigned value);

"""
Write the value of a GPIO bank with modification mask.

param device a pointer to a device instance
param bank the name of an available bank
param value an integer representing GPIO bits
param mask a modification mask where 1 = modify
return 0 for success or error code on failure
"""
#SOAPY_SDR_API int SoapySDRDevice_writeGPIOMasked(SoapySDRDevice *device, const char *bank, const unsigned value, const unsigned mask);

"""
Readback the value of a GPIO bank.

param device a pointer to a device instance
param bank the name of an available bank
return an integer representing GPIO bits
"""
#SOAPY_SDR_API unsigned SoapySDRDevice_readGPIO(const SoapySDRDevice *device, const char *bank);

"""
Write the data direction of a GPIO bank.
1 bits represent outputs, 0 bits represent inputs.

param device a pointer to a device instance
param bank the name of an available bank
param dir an integer representing data direction bits
return 0 for success or error code on failure
"""
#SOAPY_SDR_API int SoapySDRDevice_writeGPIODir(SoapySDRDevice *device, const char *bank, const unsigned dir);

"""
Write the data direction of a GPIO bank with modification mask.
1 bits represent outputs, 0 bits represent inputs.

param device a pointer to a device instance
param bank the name of an available bank
param dir an integer representing data direction bits
param mask a modification mask where 1 = modify
return 0 for success or error code on failure
"""
#SOAPY_SDR_API int SoapySDRDevice_writeGPIODirMasked(SoapySDRDevice *device, const char *bank, const unsigned dir, const unsigned mask);

"""
Read the data direction of a GPIO bank.

param device a pointer to a device instance
1 bits represent outputs, 0 bits represent inputs.
param bank the name of an available bank
return an integer representing data direction bits
"""
#SOAPY_SDR_API unsigned SoapySDRDevice_readGPIODir(const SoapySDRDevice *device, const char *bank);

##############
# I2C API
##############

"""
Write to an available I2C slave.
If the device contains multiple I2C masters,
the address bits can encode which master.
param device a pointer to a device instance
param addr the address of the slave
param data an array of bytes write out
param numBytes the number of bytes to write
return 0 for success or error code on failure
"""
#SOAPY_SDR_API int SoapySDRDevice_writeI2C(SoapySDRDevice *device, const int addr, const char *data, const size_t numBytes);

"""
Read from an available I2C slave.
If the device contains multiple I2C masters,
the address bits can encode which master.
Pass the number of bytes to be read in via numBytes;
numBytes will be set to the number of actual bytes read.

param device a pointer to a device instance
param addr the address of the slave
param [in,out] numBytes the number of bytes to read
return an array of bytes read from the slave
"""
#SOAPY_SDR_API char *SoapySDRDevice_readI2C(SoapySDRDevice *device, const int addr, size_t *numBytes);

##############
# SPI API
##############

"""
Perform a SPI transaction and return the result.
Its up to the implementation to set the clock rate,
and read edge, and the write edge of the SPI core.
SPI slaves without a readback pin will return 0.

If the device contains multiple SPI masters,
the address bits can encode which master.

param device a pointer to a device instance
param addr an address of an available SPI slave
param data the SPI data, numBits-1 is first out
param numBits the number of bits to clock out
return the readback data, numBits-1 is first in
""" 
#SOAPY_SDR_API unsigned SoapySDRDevice_transactSPI(SoapySDRDevice *device, const int addr, const unsigned data, const size_t numBits);

##############
# UART API
##############

"""
Enumerate the available UART devices.

param device a pointer to a device instance
param [out] length the number of UART names
return a list of names of available UARTs
"""
#SOAPY_SDR_API char **SoapySDRDevice_listUARTs(const SoapySDRDevice *device, size_t *length);

"""
Write data to a UART device.
Its up to the implementation to set the baud rate,
carriage return settings, flushing on newline.

param device a pointer to a device instance
param which the name of an available UART
param data a null terminated array of bytes
return 0 for success or error code on failure
"""
#SOAPY_SDR_API int SoapySDRDevice_writeUART(SoapySDRDevice *device, const char *which, const char *data);

"""
Read bytes from a UART until timeout or newline.
Its up to the implementation to set the baud rate,
carriage return settings, flushing on newline.

param device a pointer to a device instance
param which the name of an available UART
param timeoutUs a timeout in microseconds
return a null terminated array of bytes
"""
#SOAPY_SDR_API char *SoapySDRDevice_readUART(const SoapySDRDevice *device, const char *which, const long timeoutUs);


#####################
# Native Access API
#####################

"""
A handle to the native device used by the driver.
The implementation may return a null value if it does not support
or does not wish to provide access to the native handle.

param: device a pointer to a device instance
return: a handle to the native device or null
"""
function SoapySDRDevice_getNativeDeviceHandle(device)
    #SOAPY_SDR_API void* SoapySDRDevice_getNativeDeviceHandle(const SoapySDRDevice *device);
    @check_error ccall((:SoapySDRDevice_getNativeDeviceHandle, lib), Ptr{Cvoid}, (Ptr{SoapySDRDevice}, ), device)
end