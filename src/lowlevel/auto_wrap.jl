# typedef void ( * SoapySDRConverterFunction ) ( const void * , void * , const size_t , const double )
"""
A typedef for declaring a ConverterFunction to be maintained in the ConverterRegistry.
A converter function copies and optionally converts an input buffer of one format into an
output buffer of another format.
The parameters are (input pointer, output pointer, number of elements, optional scalar)
"""
const SoapySDRConverterFunction = Ptr{Cvoid}

"""
    SoapySDRConverterFunctionPriority

Allow selection of a converter function with a given source and target format.
"""
@cenum SoapySDRConverterFunctionPriority::UInt32 begin
    SOAPY_SDR_CONVERTER_GENERIC = 0
    SOAPY_SDR_CONVERTER_VECTORIZED = 3
    SOAPY_SDR_CONVERTER_CUSTOM = 5
end

"""
    SoapySDRConverter_listTargetFormats(sourceFormat, length)

Get a list of existing target formats to which we can convert the specified source from.
\\param sourceFormat the source format markup string
\\param [out] length the number of valid target formats
\\return a list of valid target formats
"""
function SoapySDRConverter_listTargetFormats(sourceFormat, length)
    ccall((:SoapySDRConverter_listTargetFormats, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Cchar}, Ptr{Csize_t}), sourceFormat, length)
end

"""
    SoapySDRConverter_listSourceFormats(targetFormat, length)

Get a list of existing source formats to which we can convert the specified target from.
\\param targetFormat the target format markup string
\\param [out] length the number of valid source formats
\\return a list of valid source formats
"""
function SoapySDRConverter_listSourceFormats(targetFormat, length)
    ccall((:SoapySDRConverter_listSourceFormats, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Cchar}, Ptr{Csize_t}), targetFormat, length)
end

"""
    SoapySDRConverter_listPriorities(sourceFormat, targetFormat, length)

Get a list of available converter priorities for a given source and target format.
\\param sourceFormat the source format markup string
\\param targetFormat the target format markup string
\\param [out] length the number of priorities
\\return a list of priorities or nullptr if none are found
"""
function SoapySDRConverter_listPriorities(sourceFormat, targetFormat, length)
    ccall((:SoapySDRConverter_listPriorities, soapysdr), Ptr{SoapySDRConverterFunctionPriority}, (Ptr{Cchar}, Ptr{Cchar}, Ptr{Csize_t}), sourceFormat, targetFormat, length)
end

"""
    SoapySDRConverter_getFunction(sourceFormat, targetFormat)

Get a converter between a source and target format with the highest available priority.
\\param sourceFormat the source format markup string
\\param targetFormat the target format markup string
\\return a conversion function pointer or nullptr if none are found
"""
function SoapySDRConverter_getFunction(sourceFormat, targetFormat)
    ccall((:SoapySDRConverter_getFunction, soapysdr), SoapySDRConverterFunction, (Ptr{Cchar}, Ptr{Cchar}), sourceFormat, targetFormat)
end

"""
    SoapySDRConverter_getFunctionWithPriority(sourceFormat, targetFormat, priority)

Get a converter between a source and target format with a given priority.
\\param sourceFormat the source format markup string
\\param targetFormat the target format markup string
\\return a conversion function pointer or nullptr if none are found
"""
function SoapySDRConverter_getFunctionWithPriority(sourceFormat, targetFormat, priority)
    ccall((:SoapySDRConverter_getFunctionWithPriority, soapysdr), SoapySDRConverterFunction, (Ptr{Cchar}, Ptr{Cchar}, SoapySDRConverterFunctionPriority), sourceFormat, targetFormat, priority)
end

"""
    SoapySDRConverter_listAvailableSourceFormats(length)

Get a list of known source formats in the registry.
\\param [out] length the number of known source formats
\\return a list of known source formats
"""
function SoapySDRConverter_listAvailableSourceFormats(length)
    ccall((:SoapySDRConverter_listAvailableSourceFormats, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Csize_t},), length)
end

mutable struct SoapySDRDevice end

mutable struct SoapySDRStream end

"""
    SoapySDRDevice_lastStatus()

Get the last status code after a Device API call.
The status code is cleared on entry to each Device call.
When an device API call throws, the C bindings catch
the exception, and set a non-zero last status code.
Use lastStatus() to determine success/failure for
Device calls without integer status return codes.
"""
function SoapySDRDevice_lastStatus()
    ccall((:SoapySDRDevice_lastStatus, soapysdr), Cint, ())
end

"""
    SoapySDRDevice_lastError()

Get the last error message after a device call fails.
When an device API call throws, the C bindings catch
the exception, store its message in thread-safe storage,
and return a non-zero status code to indicate failure.
Use lastError() to access the exception's error message.
"""
function SoapySDRDevice_lastError()
    ccall((:SoapySDRDevice_lastError, soapysdr), Ptr{Cchar}, ())
end

"""
    SoapySDRKwargs

Definition for a key/value string map
"""
struct SoapySDRKwargs
    size::Csize_t
    keys::Ptr{Ptr{Cchar}}
    vals::Ptr{Ptr{Cchar}}
end

"""
    SoapySDRDevice_enumerate(args, length)

Enumerate a list of available devices on the system.
\\param args device construction key/value argument filters
\\param [out] length the number of elements in the result.
\\return a list of arguments strings, each unique to a device
"""
function SoapySDRDevice_enumerate(args, length)
    ccall((:SoapySDRDevice_enumerate, soapysdr), Ptr{SoapySDRKwargs}, (Ptr{SoapySDRKwargs}, Ptr{Csize_t}), args, length)
end

"""
    SoapySDRDevice_enumerateStrArgs(args, length)

Enumerate a list of available devices on the system.
Markup format for args: "keyA=valA, keyB=valB".
\\param args a markup string of key/value argument filters
\\param [out] length the number of elements in the result.
\\return a list of arguments strings, each unique to a device
"""
function SoapySDRDevice_enumerateStrArgs(args, length)
    ccall((:SoapySDRDevice_enumerateStrArgs, soapysdr), Ptr{SoapySDRKwargs}, (Ptr{Cchar}, Ptr{Csize_t}), args, length)
end

"""
    SoapySDRDevice_make(args)

Make a new Device object given device construction args.
The device pointer will be stored in a table so subsequent calls
with the same arguments will produce the same device.
For every call to make, there should be a matched call to unmake.

\\param args device construction key/value argument map
\\return a pointer to a new Device object
"""
function SoapySDRDevice_make(args)
    ccall((:SoapySDRDevice_make, soapysdr), Ptr{SoapySDRDevice}, (Ptr{SoapySDRKwargs},), args)
end

"""
    SoapySDRDevice_makeStrArgs(args)

Make a new Device object given device construction args.
The device pointer will be stored in a table so subsequent calls
with the same arguments will produce the same device.
For every call to make, there should be a matched call to unmake.

\\param args a markup string of key/value arguments
\\return a pointer to a new Device object or null for error
"""
function SoapySDRDevice_makeStrArgs(args)
    ccall((:SoapySDRDevice_makeStrArgs, soapysdr), Ptr{SoapySDRDevice}, (Ptr{Cchar},), args)
end

"""
    SoapySDRDevice_unmake(device)

Unmake or release a device object handle.

\\param device a pointer to a device object
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_unmake(device)
    ccall((:SoapySDRDevice_unmake, soapysdr), Cint, (Ptr{SoapySDRDevice},), device)
end

"""
    SoapySDRDevice_make_list(argsList, length)

Create a list of devices from a list of construction arguments.
This is a convenience call to parallelize device construction,
and is fundamentally a parallel for loop of make(Kwargs).

\\param argsList a list of device arguments per each device
\\param length the length of the argsList array
\\return a list of device pointers per each specified argument
"""
function SoapySDRDevice_make_list(argsList, length)
    ccall((:SoapySDRDevice_make_list, soapysdr), Ptr{Ptr{SoapySDRDevice}}, (Ptr{SoapySDRKwargs}, Csize_t), argsList, length)
end

"""
    SoapySDRDevice_make_listStrArgs(argsList, length)

Create a list of devices from a list of construction arguments.
This is a convenience call to parallelize device construction,
and is fundamentally a parallel for loop of makeStrArgs(args).

\\param argsList a list of device arguments per each device
\\param length the length of the argsList array
\\return a list of device pointers per each specified argument
"""
function SoapySDRDevice_make_listStrArgs(argsList, length)
    ccall((:SoapySDRDevice_make_listStrArgs, soapysdr), Ptr{Ptr{SoapySDRDevice}}, (Ptr{Ptr{Cchar}}, Csize_t), argsList, length)
end

"""
    SoapySDRDevice_unmake_list(devices, length)

Unmake or release a list of device handles
and free the devices array memory as well.
This is a convenience call to parallelize device destruction,
and is fundamentally a parallel for loop of unmake(Device *).

\\param devices a list of pointers to device objects
\\param length the length of the devices array
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_unmake_list(devices, length)
    ccall((:SoapySDRDevice_unmake_list, soapysdr), Cint, (Ptr{Ptr{SoapySDRDevice}}, Csize_t), devices, length)
end

"""
    SoapySDRDevice_getDriverKey(device)

A key that uniquely identifies the device driver.
This key identifies the underlying implementation.
Several variants of a product may share a driver.
\\param device a pointer to a device instance
"""
function SoapySDRDevice_getDriverKey(device)
    ccall((:SoapySDRDevice_getDriverKey, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice},), device)
end

"""
    SoapySDRDevice_getHardwareKey(device)

A key that uniquely identifies the hardware.
This key should be meaningful to the user
to optimize for the underlying hardware.
\\param device a pointer to a device instance
"""
function SoapySDRDevice_getHardwareKey(device)
    ccall((:SoapySDRDevice_getHardwareKey, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice},), device)
end

"""
    SoapySDRDevice_getHardwareInfo(device)

Query a dictionary of available device information.
This dictionary can any number of values like
vendor name, product name, revisions, serials...
This information can be displayed to the user
to help identify the instantiated device.
\\param device a pointer to a device instance
"""
function SoapySDRDevice_getHardwareInfo(device)
    ccall((:SoapySDRDevice_getHardwareInfo, soapysdr), SoapySDRKwargs, (Ptr{SoapySDRDevice},), device)
end

"""
    SoapySDRDevice_setFrontendMapping(device, direction, mapping)

Set the frontend mapping of available DSP units to RF frontends.
This mapping controls channel mapping and channel availability.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param mapping a vendor-specific mapping string
\\return an error code or 0 for success
"""
function SoapySDRDevice_setFrontendMapping(device, direction, mapping)
    ccall((:SoapySDRDevice_setFrontendMapping, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Ptr{Cchar}), device, direction, mapping)
end

"""
    SoapySDRDevice_getFrontendMapping(device, direction)

Get the mapping configuration string.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\return the vendor-specific mapping string
"""
function SoapySDRDevice_getFrontendMapping(device, direction)
    ccall((:SoapySDRDevice_getFrontendMapping, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice}, Cint), device, direction)
end

"""
    SoapySDRDevice_getNumChannels(device, direction)

Get a number of channels given the streaming direction
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\return the number of channels
"""
function SoapySDRDevice_getNumChannels(device, direction)
    ccall((:SoapySDRDevice_getNumChannels, soapysdr), Csize_t, (Ptr{SoapySDRDevice}, Cint), device, direction)
end

"""
    SoapySDRDevice_getChannelInfo(device, direction, channel)

Get channel info given the streaming direction
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel the channel number to get info for
\\return channel information
"""
function SoapySDRDevice_getChannelInfo(device, direction, channel)
    ccall((:SoapySDRDevice_getChannelInfo, soapysdr), SoapySDRKwargs, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_getFullDuplex(device, direction, channel)

Find out if the specified channel is full or half duplex.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true for full duplex, false for half duplex
"""
function SoapySDRDevice_getFullDuplex(device, direction, channel)
    ccall((:SoapySDRDevice_getFullDuplex, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_getStreamFormats(device, direction, channel, length)

Query a list of the available stream formats.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of format strings
\\return a list of allowed format strings.
 See SoapySDRDevice_setupStream() for the format syntax.
"""
function SoapySDRDevice_getStreamFormats(device, direction, channel, length)
    ccall((:SoapySDRDevice_getStreamFormats, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_getNativeStreamFormat(device, direction, channel, fullScale)

Get the hardware's native stream format for this channel.
This is the format used by the underlying transport layer,
and the direct buffer access API calls (when available).
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] fullScale the maximum possible value
\\return the native stream buffer format string
"""
function SoapySDRDevice_getNativeStreamFormat(device, direction, channel, fullScale)
    ccall((:SoapySDRDevice_getNativeStreamFormat, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cdouble}), device, direction, channel, fullScale)
end

"""
    SoapySDRArgInfoType

Possible data types for argument info
"""
@cenum SoapySDRArgInfoType::UInt32 begin
    SOAPY_SDR_ARG_INFO_BOOL = 0
    SOAPY_SDR_ARG_INFO_INT = 1
    SOAPY_SDR_ARG_INFO_FLOAT = 2
    SOAPY_SDR_ARG_INFO_STRING = 3
end

"""
    SoapySDRRange

Definition for a min/max numeric range
"""
struct SoapySDRRange
    minimum::Cdouble
    maximum::Cdouble
    step::Cdouble
end

"""
    SoapySDRArgInfo

Definition for argument info
"""
struct SoapySDRArgInfo
    key::Ptr{Cchar}
    value::Ptr{Cchar}
    name::Ptr{Cchar}
    description::Ptr{Cchar}
    units::Ptr{Cchar}
    type::SoapySDRArgInfoType
    range::SoapySDRRange
    numOptions::Csize_t
    options::Ptr{Ptr{Cchar}}
    optionNames::Ptr{Ptr{Cchar}}
end

"""
    SoapySDRDevice_getStreamArgsInfo(device, direction, channel, length)

Query the argument info description for stream args.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of argument infos
\\return a list of argument info structures
"""
function SoapySDRDevice_getStreamArgsInfo(device, direction, channel, length)
    ccall((:SoapySDRDevice_getStreamArgsInfo, soapysdr), Ptr{SoapySDRArgInfo}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_setupStream(device, direction, format, channels, numChans, args)

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

\\param device a pointer to a device instance
\\return the opaque pointer to a stream handle.
\\parblock

The returned stream is not required to have internal locking, and may not be used
concurrently from multiple threads.
\\endparblock

\\param direction the channel direction (`SOAPY_SDR_RX` or `SOAPY_SDR_TX`)
\\param format A string representing the desired buffer format in read/writeStream()
\\parblock

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

\\endparblock
\\param channels a list of channels or empty for automatic
\\param numChans the number of elements in the channels array
\\param args stream args or empty for defaults
\\parblock

  Recommended keys to use in the args dictionary:
   - "WIRE" - format of the samples between device and host
\\endparblock
\\return the stream pointer or nullptr for failure
"""
function SoapySDRDevice_setupStream(device, direction, format, channels, numChans, args)
    ccall((:SoapySDRDevice_setupStream, soapysdr), Ptr{SoapySDRStream}, (Ptr{SoapySDRDevice}, Cint, Ptr{Cchar}, Ptr{Csize_t}, Csize_t, Ptr{SoapySDRKwargs}), device, direction, format, channels, numChans, args)
end

"""
    SoapySDRDevice_closeStream(device, stream)

Close an open stream created by setupStream
\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_closeStream(device, stream)
    ccall((:SoapySDRDevice_closeStream, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}), device, stream)
end

"""
    SoapySDRDevice_getStreamMTU(device, stream)

Get the stream's maximum transmission unit (MTU) in number of elements.
The MTU specifies the maximum payload transfer in a stream operation.
This value can be used as a stream buffer allocation size that can
best optimize throughput given the underlying stream implementation.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\return the MTU in number of stream elements (never zero)
"""
function SoapySDRDevice_getStreamMTU(device, stream)
    ccall((:SoapySDRDevice_getStreamMTU, soapysdr), Csize_t, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}), device, stream)
end

"""
    SoapySDRDevice_activateStream(device, stream, flags, timeNs, numElems)

Activate a stream.
Call activate to prepare a stream before using read/write().
The implementation control switches or stimulate data flow.

The timeNs is only valid when the flags have SOAPY_SDR_HAS_TIME.
The numElems count can be used to request a finite burst size.
The SOAPY_SDR_END_BURST flag can signal end on the finite burst.
Not all implementations will support the full range of options.
In this case, the implementation returns SOAPY_SDR_NOT_SUPPORTED.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param flags optional flag indicators about the stream
\\param timeNs optional activation time in nanoseconds
\\param numElems optional element count for burst control
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_activateStream(device, stream, flags, timeNs, numElems)
    ccall((:SoapySDRDevice_activateStream, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Cint, Clonglong, Csize_t), device, stream, flags, timeNs, numElems)
end

"""
    SoapySDRDevice_deactivateStream(device, stream, flags, timeNs)

Deactivate a stream.
Call deactivate when not using using read/write().
The implementation control switches or halt data flow.

The timeNs is only valid when the flags have SOAPY_SDR_HAS_TIME.
Not all implementations will support the full range of options.
In this case, the implementation returns SOAPY_SDR_NOT_SUPPORTED.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param flags optional flag indicators about the stream
\\param timeNs optional deactivation time in nanoseconds
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_deactivateStream(device, stream, flags, timeNs)
    ccall((:SoapySDRDevice_deactivateStream, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Cint, Clonglong), device, stream, flags, timeNs)
end

"""
    SoapySDRDevice_readStream(device, stream, buffs, numElems, flags, timeNs, timeoutUs)

Read elements from a stream for reception.
This is a multi-channel call, and buffs should be an array of void *,
where each pointer will be filled with data from a different channel.

**Client code compatibility:**
The readStream() call should be well defined at all times,
including prior to activation and after deactivation.
When inactive, readStream() should implement the timeout
specified by the caller and return SOAPY_SDR_TIMEOUT.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param buffs an array of void* buffers num chans in size
\\param numElems the number of elements in each buffer
\\param [out] flags optional flag indicators about the result
\\param [out] timeNs the buffer's timestamp in nanoseconds
\\param timeoutUs the timeout in microseconds
\\return the number of elements read per buffer or error code
"""
function SoapySDRDevice_readStream(device, stream, buffs, numElems, flags, timeNs, timeoutUs)
    ccall((:SoapySDRDevice_readStream, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Ptr{Ptr{Cvoid}}, Csize_t, Ptr{Cint}, Ptr{Clonglong}, Clong), device, stream, buffs, numElems, flags, timeNs, timeoutUs)
end

"""
    SoapySDRDevice_writeStream(device, stream, buffs, numElems, flags, timeNs, timeoutUs)

Write elements to a stream for transmission.
This is a multi-channel call, and buffs should be an array of void *,
where each pointer will be filled with data for a different channel.

**Client code compatibility:**
Client code relies on writeStream() for proper back-pressure.
The writeStream() implementation must enforce the timeout
such that the call blocks until space becomes available
or timeout expiration.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param buffs an array of void* buffers num chans in size
\\param numElems the number of elements in each buffer
\\param [in,out] flags optional input flags and output flags
\\param timeNs the buffer's timestamp in nanoseconds
\\param timeoutUs the timeout in microseconds
\\return the number of elements written per buffer or error
"""
function SoapySDRDevice_writeStream(device, stream, buffs, numElems, flags, timeNs, timeoutUs)
    ccall((:SoapySDRDevice_writeStream, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Ptr{Ptr{Cvoid}}, Csize_t, Ptr{Cint}, Clonglong, Clong), device, stream, buffs, numElems, flags, timeNs, timeoutUs)
end

"""
    SoapySDRDevice_readStreamStatus(device, stream, chanMask, flags, timeNs, timeoutUs)

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

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param chanMask to which channels this status applies
\\param flags optional input flags and output flags
\\param timeNs the buffer's timestamp in nanoseconds
\\param timeoutUs the timeout in microseconds
\\return 0 for success or error code like timeout
"""
function SoapySDRDevice_readStreamStatus(device, stream, chanMask, flags, timeNs, timeoutUs)
    ccall((:SoapySDRDevice_readStreamStatus, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Ptr{Csize_t}, Ptr{Cint}, Ptr{Clonglong}, Clong), device, stream, chanMask, flags, timeNs, timeoutUs)
end

"""
    SoapySDRDevice_getNumDirectAccessBuffers(device, stream)

How many direct access buffers can the stream provide?
This is the number of times the user can call acquire()
on a stream without making subsequent calls to release().
A return value of 0 means that direct access is not supported.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\return the number of direct access buffers or 0
"""
function SoapySDRDevice_getNumDirectAccessBuffers(device, stream)
    ccall((:SoapySDRDevice_getNumDirectAccessBuffers, soapysdr), Csize_t, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}), device, stream)
end

"""
    SoapySDRDevice_getDirectAccessBufferAddrs(device, stream, handle, buffs)

Get the buffer addresses for a scatter/gather table entry.
When the underlying DMA implementation uses scatter/gather
then this call provides the user addresses for that table.

Example: The caller may query the DMA memory addresses once
after stream creation to pre-allocate a re-usable ring-buffer.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param handle an index value between 0 and num direct buffers - 1
\\param buffs an array of void* buffers num chans in size
\\return 0 for success or error code when not supported
"""
function SoapySDRDevice_getDirectAccessBufferAddrs(device, stream, handle, buffs)
    ccall((:SoapySDRDevice_getDirectAccessBufferAddrs, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Csize_t, Ptr{Ptr{Cvoid}}), device, stream, handle, buffs)
end

"""
    SoapySDRDevice_acquireReadBuffer(device, stream, handle, buffs, flags, timeNs, timeoutUs)

Acquire direct buffers from a receive stream.
This call is part of the direct buffer access API.

The buffs array will be filled with a stream pointer for each channel.
Each pointer can be read up to the number of return value elements.

The handle will be set by the implementation so that the caller
may later release access to the buffers with releaseReadBuffer().
Handle represents an index into the internal scatter/gather table
such that handle is between 0 and num direct buffers - 1.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param handle an index value used in the release() call
\\param buffs an array of void* buffers num chans in size
\\param flags optional flag indicators about the result
\\param timeNs the buffer's timestamp in nanoseconds
\\param timeoutUs the timeout in microseconds
\\return the number of elements read per buffer or error code
"""
function SoapySDRDevice_acquireReadBuffer(device, stream, handle, buffs, flags, timeNs, timeoutUs)
    ccall((:SoapySDRDevice_acquireReadBuffer, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Ptr{Csize_t}, Ptr{Ptr{Cvoid}}, Ptr{Cint}, Ptr{Clonglong}, Clong), device, stream, handle, buffs, flags, timeNs, timeoutUs)
end

"""
    SoapySDRDevice_releaseReadBuffer(device, stream, handle)

Release an acquired buffer back to the receive stream.
This call is part of the direct buffer access API.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param handle the opaque handle from the acquire() call
"""
function SoapySDRDevice_releaseReadBuffer(device, stream, handle)
    ccall((:SoapySDRDevice_releaseReadBuffer, soapysdr), Cvoid, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Csize_t), device, stream, handle)
end

"""
    SoapySDRDevice_acquireWriteBuffer(device, stream, handle, buffs, timeoutUs)

Acquire direct buffers from a transmit stream.
This call is part of the direct buffer access API.

The buffs array will be filled with a stream pointer for each channel.
Each pointer can be written up to the number of return value elements.

The handle will be set by the implementation so that the caller
may later release access to the buffers with releaseWriteBuffer().
Handle represents an index into the internal scatter/gather table
such that handle is between 0 and num direct buffers - 1.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param handle an index value used in the release() call
\\param buffs an array of void* buffers num chans in size
\\param timeoutUs the timeout in microseconds
\\return the number of available elements per buffer or error
"""
function SoapySDRDevice_acquireWriteBuffer(device, stream, handle, buffs, timeoutUs)
    ccall((:SoapySDRDevice_acquireWriteBuffer, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Ptr{Csize_t}, Ptr{Ptr{Cvoid}}, Clong), device, stream, handle, buffs, timeoutUs)
end

"""
    SoapySDRDevice_releaseWriteBuffer(device, stream, handle, numElems, flags, timeNs)

Release an acquired buffer back to the transmit stream.
This call is part of the direct buffer access API.

Stream meta-data is provided as part of the release call,
and not the acquire call so that the caller may acquire
buffers without committing to the contents of the meta-data,
which can be determined by the user as the buffers are filled.

\\param device a pointer to a device instance
\\param stream the opaque pointer to a stream handle
\\param handle the opaque handle from the acquire() call
\\param numElems the number of elements written to each buffer
\\param flags optional input flags and output flags
\\param timeNs the buffer's timestamp in nanoseconds
"""
function SoapySDRDevice_releaseWriteBuffer(device, stream, handle, numElems, flags, timeNs)
    ccall((:SoapySDRDevice_releaseWriteBuffer, soapysdr), Cvoid, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Csize_t, Csize_t, Ptr{Cint}, Clonglong), device, stream, handle, numElems, flags, timeNs)
end

"""
    SoapySDRDevice_listAntennas(device, direction, channel, length)

Get a list of available antennas to select on a given chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of antenna names
\\return a list of available antenna names
"""
function SoapySDRDevice_listAntennas(device, direction, channel, length)
    ccall((:SoapySDRDevice_listAntennas, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_setAntenna(device, direction, channel, name)

Set the selected antenna on a chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param name the name of an available antenna
\\return an error code or 0 for success
"""
function SoapySDRDevice_setAntenna(device, direction, channel, name)
    ccall((:SoapySDRDevice_setAntenna, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}), device, direction, channel, name)
end

"""
    SoapySDRDevice_getAntenna(device, direction, channel)

Get the selected antenna on a chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return the name of an available antenna
"""
function SoapySDRDevice_getAntenna(device, direction, channel)
    ccall((:SoapySDRDevice_getAntenna, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_hasDCOffsetMode(device, direction, channel)

Does the device support automatic DC offset corrections?
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true if automatic corrections are supported
"""
function SoapySDRDevice_hasDCOffsetMode(device, direction, channel)
    ccall((:SoapySDRDevice_hasDCOffsetMode, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_setDCOffsetMode(device, direction, channel, automatic)

Set the automatic DC offset corrections mode.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param automatic true for automatic offset correction
\\return an error code or 0 for success
"""
function SoapySDRDevice_setDCOffsetMode(device, direction, channel, automatic)
    ccall((:SoapySDRDevice_setDCOffsetMode, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Bool), device, direction, channel, automatic)
end

"""
    SoapySDRDevice_getDCOffsetMode(device, direction, channel)

Get the automatic DC offset corrections mode.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true for automatic offset correction
"""
function SoapySDRDevice_getDCOffsetMode(device, direction, channel)
    ccall((:SoapySDRDevice_getDCOffsetMode, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_hasDCOffset(device, direction, channel)

Does the device support frontend DC offset correction?
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true if DC offset corrections are supported
"""
function SoapySDRDevice_hasDCOffset(device, direction, channel)
    ccall((:SoapySDRDevice_hasDCOffset, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_setDCOffset(device, direction, channel, offsetI, offsetQ)

Set the frontend DC offset correction.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param offsetI the relative correction (1.0 max)
\\param offsetQ the relative correction (1.0 max)
\\return an error code or 0 for success
"""
function SoapySDRDevice_setDCOffset(device, direction, channel, offsetI, offsetQ)
    ccall((:SoapySDRDevice_setDCOffset, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cdouble, Cdouble), device, direction, channel, offsetI, offsetQ)
end

"""
    SoapySDRDevice_getDCOffset(device, direction, channel, offsetI, offsetQ)

Get the frontend DC offset correction.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] offsetI the relative correction (1.0 max)
\\param [out] offsetQ the relative correction (1.0 max)
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_getDCOffset(device, direction, channel, offsetI, offsetQ)
    ccall((:SoapySDRDevice_getDCOffset, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cdouble}, Ptr{Cdouble}), device, direction, channel, offsetI, offsetQ)
end

"""
    SoapySDRDevice_hasIQBalance(device, direction, channel)

Does the device support frontend IQ balance correction?
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true if IQ balance corrections are supported
"""
function SoapySDRDevice_hasIQBalance(device, direction, channel)
    ccall((:SoapySDRDevice_hasIQBalance, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_setIQBalance(device, direction, channel, balanceI, balanceQ)

Set the frontend IQ balance correction.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param balanceI the relative correction (1.0 max)
\\param balanceQ the relative correction (1.0 max)
\\return an error code or 0 for success
"""
function SoapySDRDevice_setIQBalance(device, direction, channel, balanceI, balanceQ)
    ccall((:SoapySDRDevice_setIQBalance, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cdouble, Cdouble), device, direction, channel, balanceI, balanceQ)
end

"""
    SoapySDRDevice_getIQBalance(device, direction, channel, balanceI, balanceQ)

Get the frontend IQ balance correction.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] balanceI the relative correction (1.0 max)
\\param [out] balanceQ the relative correction (1.0 max)
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_getIQBalance(device, direction, channel, balanceI, balanceQ)
    ccall((:SoapySDRDevice_getIQBalance, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cdouble}, Ptr{Cdouble}), device, direction, channel, balanceI, balanceQ)
end

"""
    SoapySDRDevice_hasIQBalanceMode(device, direction, channel)

Does the device support automatic frontend IQ balance correction?
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true if automatic IQ balance corrections are supported
"""
function SoapySDRDevice_hasIQBalanceMode(device, direction, channel)
    ccall((:SoapySDRDevice_hasIQBalanceMode, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_setIQBalanceMode(device, direction, channel, automatic)

Set the automatic frontend IQ balance correction.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param automatic true for automatic correction
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_setIQBalanceMode(device, direction, channel, automatic)
    ccall((:SoapySDRDevice_setIQBalanceMode, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Bool), device, direction, channel, automatic)
end

"""
    SoapySDRDevice_getIQBalanceMode(device, direction, channel)

Get the automatic frontend IQ balance corrections mode.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true for automatic correction
"""
function SoapySDRDevice_getIQBalanceMode(device, direction, channel)
    ccall((:SoapySDRDevice_getIQBalanceMode, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_hasFrequencyCorrection(device, direction, channel)

Does the device support frontend frequency correction?
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true if frequency corrections are supported
"""
function SoapySDRDevice_hasFrequencyCorrection(device, direction, channel)
    ccall((:SoapySDRDevice_hasFrequencyCorrection, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_setFrequencyCorrection(device, direction, channel, value)

Fine tune the frontend frequency correction.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param value the correction in PPM
\\return an error code or 0 for success
"""
function SoapySDRDevice_setFrequencyCorrection(device, direction, channel, value)
    ccall((:SoapySDRDevice_setFrequencyCorrection, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cdouble), device, direction, channel, value)
end

"""
    SoapySDRDevice_getFrequencyCorrection(device, direction, channel)

Get the frontend frequency correction value.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return the correction value in PPM
"""
function SoapySDRDevice_getFrequencyCorrection(device, direction, channel)
    ccall((:SoapySDRDevice_getFrequencyCorrection, soapysdr), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_listGains(device, direction, channel, length)

List available amplification elements.
Elements should be in order RF to baseband.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel
\\param [out] length the number of gain names
\\return a list of gain string names
"""
function SoapySDRDevice_listGains(device, direction, channel, length)
    ccall((:SoapySDRDevice_listGains, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_hasGainMode(device, direction, channel)

Does the device support automatic gain control?
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true for automatic gain control
"""
function SoapySDRDevice_hasGainMode(device, direction, channel)
    ccall((:SoapySDRDevice_hasGainMode, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_setGainMode(device, direction, channel, automatic)

Set the automatic gain mode on the chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param automatic true for automatic gain setting
\\return an error code or 0 for success
"""
function SoapySDRDevice_setGainMode(device, direction, channel, automatic)
    ccall((:SoapySDRDevice_setGainMode, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Bool), device, direction, channel, automatic)
end

"""
    SoapySDRDevice_getGainMode(device, direction, channel)

Get the automatic gain mode on the chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return true for automatic gain setting
"""
function SoapySDRDevice_getGainMode(device, direction, channel)
    ccall((:SoapySDRDevice_getGainMode, soapysdr), Bool, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_setGain(device, direction, channel, value)

Set the overall amplification in a chain.
The gain will be distributed automatically across available element.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param value the new amplification value in dB
\\return an error code or 0 for success
"""
function SoapySDRDevice_setGain(device, direction, channel, value)
    ccall((:SoapySDRDevice_setGain, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cdouble), device, direction, channel, value)
end

"""
    SoapySDRDevice_setGainElement(device, direction, channel, name, value)

Set the value of a amplification element in a chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param name the name of an amplification element
\\param value the new amplification value in dB
\\return an error code or 0 for success
"""
function SoapySDRDevice_setGainElement(device, direction, channel, name, value)
    ccall((:SoapySDRDevice_setGainElement, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}, Cdouble), device, direction, channel, name, value)
end

"""
    SoapySDRDevice_getGain(device, direction, channel)

Get the overall value of the gain elements in a chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return the value of the gain in dB
"""
function SoapySDRDevice_getGain(device, direction, channel)
    ccall((:SoapySDRDevice_getGain, soapysdr), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_getGainElement(device, direction, channel, name)

Get the value of an individual amplification element in a chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param name the name of an amplification element
\\return the value of the gain in dB
"""
function SoapySDRDevice_getGainElement(device, direction, channel, name)
    ccall((:SoapySDRDevice_getGainElement, soapysdr), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}), device, direction, channel, name)
end

"""
    SoapySDRDevice_getGainRange(device, direction, channel)

Get the overall range of possible gain values.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return the range of possible gain values for this channel in dB
"""
function SoapySDRDevice_getGainRange(device, direction, channel)
    ccall((:SoapySDRDevice_getGainRange, soapysdr), SoapySDRRange, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_getGainElementRange(device, direction, channel, name)

Get the range of possible gain values for a specific element.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param name the name of an amplification element
\\return the range of possible gain values for the specified amplification element in dB
"""
function SoapySDRDevice_getGainElementRange(device, direction, channel, name)
    ccall((:SoapySDRDevice_getGainElementRange, soapysdr), SoapySDRRange, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}), device, direction, channel, name)
end

"""
    SoapySDRDevice_setFrequency(device, direction, channel, frequency, args)

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

\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param frequency the center frequency in Hz
\\param args optional tuner arguments
\\return an error code or 0 for success
"""
function SoapySDRDevice_setFrequency(device, direction, channel, frequency, args)
    ccall((:SoapySDRDevice_setFrequency, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cdouble, Ptr{SoapySDRKwargs}), device, direction, channel, frequency, args)
end

"""
    SoapySDRDevice_setFrequencyComponent(device, direction, channel, name, frequency, args)

Tune the center frequency of the specified element.
 - For RX, this specifies the down-conversion frequency.
 - For TX, this specifies the up-conversion frequency.

Recommended names used to represent tunable components:
 - "CORR" - freq error correction in PPM
 - "RF" - frequency of the RF frontend
 - "BB" - frequency of the baseband DSP

\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param name the name of a tunable element
\\param frequency the center frequency in Hz
\\param args optional tuner arguments
\\return an error code or 0 for success
"""
function SoapySDRDevice_setFrequencyComponent(device, direction, channel, name, frequency, args)
    ccall((:SoapySDRDevice_setFrequencyComponent, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}, Cdouble, Ptr{SoapySDRKwargs}), device, direction, channel, name, frequency, args)
end

"""
    SoapySDRDevice_getFrequency(device, direction, channel)

Get the overall center frequency of the chain.
 - For RX, this specifies the down-conversion frequency.
 - For TX, this specifies the up-conversion frequency.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return the center frequency in Hz
"""
function SoapySDRDevice_getFrequency(device, direction, channel)
    ccall((:SoapySDRDevice_getFrequency, soapysdr), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_getFrequencyComponent(device, direction, channel, name)

Get the frequency of a tunable element in the chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param name the name of a tunable element
\\return the tunable element's frequency in Hz
"""
function SoapySDRDevice_getFrequencyComponent(device, direction, channel, name)
    ccall((:SoapySDRDevice_getFrequencyComponent, soapysdr), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}), device, direction, channel, name)
end

"""
    SoapySDRDevice_listFrequencies(device, direction, channel, length)

List available tunable elements in the chain.
Elements should be in order RF to baseband.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel
\\param [out] length the number names
\\return a list of tunable elements by name
"""
function SoapySDRDevice_listFrequencies(device, direction, channel, length)
    ccall((:SoapySDRDevice_listFrequencies, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_getFrequencyRange(device, direction, channel, length)

Get the range of overall frequency values.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of ranges
\\return a list of frequency ranges in Hz
"""
function SoapySDRDevice_getFrequencyRange(device, direction, channel, length)
    ccall((:SoapySDRDevice_getFrequencyRange, soapysdr), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_getFrequencyRangeComponent(device, direction, channel, name, length)

Get the range of tunable values for the specified element.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param name the name of a tunable element
\\param [out] length the number of ranges
\\return a list of frequency ranges in Hz
"""
function SoapySDRDevice_getFrequencyRangeComponent(device, direction, channel, name, length)
    ccall((:SoapySDRDevice_getFrequencyRangeComponent, soapysdr), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}, Ptr{Csize_t}), device, direction, channel, name, length)
end

"""
    SoapySDRDevice_getFrequencyArgsInfo(device, direction, channel, length)

Query the argument info description for tune args.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of argument infos
\\return a list of argument info structures
"""
function SoapySDRDevice_getFrequencyArgsInfo(device, direction, channel, length)
    ccall((:SoapySDRDevice_getFrequencyArgsInfo, soapysdr), Ptr{SoapySDRArgInfo}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_setSampleRate(device, direction, channel, rate)

Set the baseband sample rate of the chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param rate the sample rate in samples per second
\\return an error code or 0 for success
"""
function SoapySDRDevice_setSampleRate(device, direction, channel, rate)
    ccall((:SoapySDRDevice_setSampleRate, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cdouble), device, direction, channel, rate)
end

"""
    SoapySDRDevice_getSampleRate(device, direction, channel)

Get the baseband sample rate of the chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return the sample rate in samples per second
"""
function SoapySDRDevice_getSampleRate(device, direction, channel)
    ccall((:SoapySDRDevice_getSampleRate, soapysdr), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_listSampleRates(device, direction, channel, length)

Get the range of possible baseband sample rates.
\\deprecated replaced by getSampleRateRange()
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of sample rates
\\return a list of possible rates in samples per second
"""
function SoapySDRDevice_listSampleRates(device, direction, channel, length)
    ccall((:SoapySDRDevice_listSampleRates, soapysdr), Ptr{Cdouble}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_getSampleRateRange(device, direction, channel, length)

Get the range of possible baseband sample rates.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of sample rates
\\return a list of sample rate ranges in samples per second
"""
function SoapySDRDevice_getSampleRateRange(device, direction, channel, length)
    ccall((:SoapySDRDevice_getSampleRateRange, soapysdr), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_setBandwidth(device, direction, channel, bw)

Set the baseband filter width of the chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param bw the baseband filter width in Hz
\\return an error code or 0 for success
"""
function SoapySDRDevice_setBandwidth(device, direction, channel, bw)
    ccall((:SoapySDRDevice_setBandwidth, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Cdouble), device, direction, channel, bw)
end

"""
    SoapySDRDevice_getBandwidth(device, direction, channel)

Get the baseband filter width of the chain.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\return the baseband filter width in Hz
"""
function SoapySDRDevice_getBandwidth(device, direction, channel)
    ccall((:SoapySDRDevice_getBandwidth, soapysdr), Cdouble, (Ptr{SoapySDRDevice}, Cint, Csize_t), device, direction, channel)
end

"""
    SoapySDRDevice_listBandwidths(device, direction, channel, length)

Get the range of possible baseband filter widths.
\\deprecated replaced by getBandwidthRange()
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of bandwidths
\\return a list of possible bandwidths in Hz
"""
function SoapySDRDevice_listBandwidths(device, direction, channel, length)
    ccall((:SoapySDRDevice_listBandwidths, soapysdr), Ptr{Cdouble}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_getBandwidthRange(device, direction, channel, length)

Get the range of possible baseband filter widths.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of ranges
\\return a list of bandwidth ranges in Hz
"""
function SoapySDRDevice_getBandwidthRange(device, direction, channel, length)
    ccall((:SoapySDRDevice_getBandwidthRange, soapysdr), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_setMasterClockRate(device, rate)

Set the master clock rate of the device.
\\param device a pointer to a device instance
\\param rate the clock rate in Hz
\\return an error code or 0 for success
"""
function SoapySDRDevice_setMasterClockRate(device, rate)
    ccall((:SoapySDRDevice_setMasterClockRate, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cdouble), device, rate)
end

"""
    SoapySDRDevice_getMasterClockRate(device)

Get the master clock rate of the device.
\\param device a pointer to a device instance
\\return the clock rate in Hz
"""
function SoapySDRDevice_getMasterClockRate(device)
    ccall((:SoapySDRDevice_getMasterClockRate, soapysdr), Cdouble, (Ptr{SoapySDRDevice},), device)
end

"""
    SoapySDRDevice_getMasterClockRates(device, length)

Get the range of available master clock rates.
\\param device a pointer to a device instance
\\param [out] length the number of ranges
\\return a list of clock rate ranges in Hz
"""
function SoapySDRDevice_getMasterClockRates(device, length)
    ccall((:SoapySDRDevice_getMasterClockRates, soapysdr), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Ptr{Csize_t}), device, length)
end

"""
    SoapySDRDevice_setReferenceClockRate(device, rate)

Set the reference clock rate of the device.
\\param device a pointer to a device instance
\\param rate the clock rate in Hz
\\return an error code or 0 for success
"""
function SoapySDRDevice_setReferenceClockRate(device, rate)
    ccall((:SoapySDRDevice_setReferenceClockRate, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cdouble), device, rate)
end

"""
    SoapySDRDevice_getReferenceClockRate(device)

Get the reference clock rate of the device.
\\param device a pointer to a device instance
\\return the clock rate in Hz
"""
function SoapySDRDevice_getReferenceClockRate(device)
    ccall((:SoapySDRDevice_getReferenceClockRate, soapysdr), Cdouble, (Ptr{SoapySDRDevice},), device)
end

"""
    SoapySDRDevice_getReferenceClockRates(device, length)

Get the range of available reference clock rates.
\\param device a pointer to a device instance
\\param [out] length the number of sources
\\return a list of clock rate ranges in Hz
"""
function SoapySDRDevice_getReferenceClockRates(device, length)
    ccall((:SoapySDRDevice_getReferenceClockRates, soapysdr), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Ptr{Csize_t}), device, length)
end

"""
    SoapySDRDevice_listClockSources(device, length)

Get the list of available clock sources.
\\param device a pointer to a device instance
\\param [out] length the number of sources
\\return a list of clock source names
"""
function SoapySDRDevice_listClockSources(device, length)
    ccall((:SoapySDRDevice_listClockSources, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Ptr{Csize_t}), device, length)
end

"""
    SoapySDRDevice_setClockSource(device, source)

Set the clock source on the device
\\param device a pointer to a device instance
\\param source the name of a clock source
\\return an error code or 0 for success
"""
function SoapySDRDevice_setClockSource(device, source)
    ccall((:SoapySDRDevice_setClockSource, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}), device, source)
end

"""
    SoapySDRDevice_getClockSource(device)

Get the clock source of the device
\\param device a pointer to a device instance
\\return the name of a clock source
"""
function SoapySDRDevice_getClockSource(device)
    ccall((:SoapySDRDevice_getClockSource, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice},), device)
end

"""
    SoapySDRDevice_listTimeSources(device, length)

Get the list of available time sources.
\\param device a pointer to a device instance
\\param [out] length the number of sources
\\return a list of time source names
"""
function SoapySDRDevice_listTimeSources(device, length)
    ccall((:SoapySDRDevice_listTimeSources, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Ptr{Csize_t}), device, length)
end

"""
    SoapySDRDevice_setTimeSource(device, source)

Set the time source on the device
\\param device a pointer to a device instance
\\param source the name of a time source
\\return an error code or 0 for success
"""
function SoapySDRDevice_setTimeSource(device, source)
    ccall((:SoapySDRDevice_setTimeSource, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}), device, source)
end

"""
    SoapySDRDevice_getTimeSource(device)

Get the time source of the device
\\param device a pointer to a device instance
\\return the name of a time source
"""
function SoapySDRDevice_getTimeSource(device)
    ccall((:SoapySDRDevice_getTimeSource, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice},), device)
end

"""
    SoapySDRDevice_hasHardwareTime(device, what)

Does this device have a hardware clock?
\\param device a pointer to a device instance
\\param what optional argument
\\return true if the hardware clock exists
"""
function SoapySDRDevice_hasHardwareTime(device, what)
    ccall((:SoapySDRDevice_hasHardwareTime, soapysdr), Bool, (Ptr{SoapySDRDevice}, Ptr{Cchar}), device, what)
end

"""
    SoapySDRDevice_getHardwareTime(device, what)

Read the time from the hardware clock on the device.
The what argument can refer to a specific time counter.
\\param device a pointer to a device instance
\\param what optional argument
\\return the time in nanoseconds
"""
function SoapySDRDevice_getHardwareTime(device, what)
    ccall((:SoapySDRDevice_getHardwareTime, soapysdr), Clonglong, (Ptr{SoapySDRDevice}, Ptr{Cchar}), device, what)
end

"""
    SoapySDRDevice_setHardwareTime(device, timeNs, what)

Write the time to the hardware clock on the device.
The what argument can refer to a specific time counter.
\\param device a pointer to a device instance
\\param timeNs time in nanoseconds
\\param what optional argument
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_setHardwareTime(device, timeNs, what)
    ccall((:SoapySDRDevice_setHardwareTime, soapysdr), Cint, (Ptr{SoapySDRDevice}, Clonglong, Ptr{Cchar}), device, timeNs, what)
end

"""
    SoapySDRDevice_setCommandTime(device, timeNs, what)

Set the time of subsequent configuration calls.
The what argument can refer to a specific command queue.
Implementations may use a time of 0 to clear.
\\deprecated replaced by setHardwareTime()
\\param device a pointer to a device instance
\\param timeNs time in nanoseconds
\\param what optional argument
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_setCommandTime(device, timeNs, what)
    ccall((:SoapySDRDevice_setCommandTime, soapysdr), Cint, (Ptr{SoapySDRDevice}, Clonglong, Ptr{Cchar}), device, timeNs, what)
end

"""
    SoapySDRDevice_listSensors(device, length)

List the available global readback sensors.
A sensor can represent a reference lock, RSSI, temperature.
\\param device a pointer to a device instance
\\param [out] length the number of sensor names
\\return a list of available sensor string names
"""
function SoapySDRDevice_listSensors(device, length)
    ccall((:SoapySDRDevice_listSensors, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Ptr{Csize_t}), device, length)
end

"""
    SoapySDRDevice_getSensorInfo(device, key)

Get meta-information about a sensor.
Example: displayable name, type, range.
\\param device a pointer to a device instance
\\param key the ID name of an available sensor
\\return meta-information about a sensor
"""
function SoapySDRDevice_getSensorInfo(device, key)
    ccall((:SoapySDRDevice_getSensorInfo, soapysdr), SoapySDRArgInfo, (Ptr{SoapySDRDevice}, Ptr{Cchar}), device, key)
end

"""
    SoapySDRDevice_readSensor(device, key)

Readback a global sensor given the name.
The value returned is a string which can represent
a boolean ("true"/"false"), an integer, or float.
\\param device a pointer to a device instance
\\param key the ID name of an available sensor
\\return the current value of the sensor
"""
function SoapySDRDevice_readSensor(device, key)
    ccall((:SoapySDRDevice_readSensor, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice}, Ptr{Cchar}), device, key)
end

"""
    SoapySDRDevice_listChannelSensors(device, direction, channel, length)

List the available channel readback sensors.
A sensor can represent a reference lock, RSSI, temperature.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of sensor names
\\return a list of available sensor string names
"""
function SoapySDRDevice_listChannelSensors(device, direction, channel, length)
    ccall((:SoapySDRDevice_listChannelSensors, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_getChannelSensorInfo(device, direction, channel, key)

Get meta-information about a channel sensor.
Example: displayable name, type, range.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param key the ID name of an available sensor
\\return meta-information about a sensor
"""
function SoapySDRDevice_getChannelSensorInfo(device, direction, channel, key)
    ccall((:SoapySDRDevice_getChannelSensorInfo, soapysdr), SoapySDRArgInfo, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}), device, direction, channel, key)
end

"""
    SoapySDRDevice_readChannelSensor(device, direction, channel, key)

Readback a channel sensor given the name.
The value returned is a string which can represent
a boolean ("true"/"false"), an integer, or float.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param key the ID name of an available sensor
\\return the current value of the sensor
"""
function SoapySDRDevice_readChannelSensor(device, direction, channel, key)
    ccall((:SoapySDRDevice_readChannelSensor, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}), device, direction, channel, key)
end

"""
    SoapySDRDevice_listRegisterInterfaces(device, length)

Get a list of available register interfaces by name.
\\param device a pointer to a device instance
\\param [out] length the number of interfaces
\\return a list of available register interfaces
"""
function SoapySDRDevice_listRegisterInterfaces(device, length)
    ccall((:SoapySDRDevice_listRegisterInterfaces, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Ptr{Csize_t}), device, length)
end

"""
    SoapySDRDevice_writeRegister(device, name, addr, value)

Write a register on the device given the interface name.
This can represent a register on a soft CPU, FPGA, IC;
the interpretation is up the implementation to decide.
\\param device a pointer to a device instance
\\param name the name of a available register interface
\\param addr the register address
\\param value the register value
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeRegister(device, name, addr, value)
    ccall((:SoapySDRDevice_writeRegister, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Cuint, Cuint), device, name, addr, value)
end

"""
    SoapySDRDevice_readRegister(device, name, addr)

Read a register on the device given the interface name.
\\param device a pointer to a device instance
\\param name the name of a available register interface
\\param addr the register address
\\return the register value
"""
function SoapySDRDevice_readRegister(device, name, addr)
    ccall((:SoapySDRDevice_readRegister, soapysdr), Cuint, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Cuint), device, name, addr)
end

"""
    SoapySDRDevice_writeRegisters(device, name, addr, value, length)

Write a memory block on the device given the interface name.
This can represent a memory block on a soft CPU, FPGA, IC;
the interpretation is up the implementation to decide.
\\param device a pointer to a device instance
\\param name the name of a available memory block interface
\\param addr the memory block start address
\\param value the memory block content
\\param length the number of words in the block
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeRegisters(device, name, addr, value, length)
    ccall((:SoapySDRDevice_writeRegisters, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Cuint, Ptr{Cuint}, Csize_t), device, name, addr, value, length)
end

"""
    SoapySDRDevice_readRegisters(device, name, addr, length)

Read a memory block on the device given the interface name.
Pass the number of words to be read in via length;
length will be set to the number of actual words read.
\\param device a pointer to a device instance
\\param name the name of a available memory block interface
\\param addr the memory block start address
\\param [inout] length number of words to be read from memory block
\\return the memory block content
"""
function SoapySDRDevice_readRegisters(device, name, addr, length)
    ccall((:SoapySDRDevice_readRegisters, soapysdr), Ptr{Cuint}, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Cuint, Ptr{Csize_t}), device, name, addr, length)
end

"""
    SoapySDRDevice_getSettingInfo(device, length)

Describe the allowed keys and values used for settings.
\\param device a pointer to a device instance
\\param [out] length the number of sensor names
\\return a list of argument info structures
"""
function SoapySDRDevice_getSettingInfo(device, length)
    ccall((:SoapySDRDevice_getSettingInfo, soapysdr), Ptr{SoapySDRArgInfo}, (Ptr{SoapySDRDevice}, Ptr{Csize_t}), device, length)
end

"""
    SoapySDRDevice_writeSetting(device, key, value)

Write an arbitrary setting on the device.
The interpretation is up the implementation.
\\param device a pointer to a device instance
\\param key the setting identifier
\\param value the setting value
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeSetting(device, key, value)
    ccall((:SoapySDRDevice_writeSetting, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Ptr{Cchar}), device, key, value)
end

"""
    SoapySDRDevice_readSetting(device, key)

Read an arbitrary setting on the device.
\\param device a pointer to a device instance
\\param key the setting identifier
\\return the setting value
"""
function SoapySDRDevice_readSetting(device, key)
    ccall((:SoapySDRDevice_readSetting, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice}, Ptr{Cchar}), device, key)
end

"""
    SoapySDRDevice_getChannelSettingInfo(device, direction, channel, length)

Describe the allowed keys and values used for channel settings.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param [out] length the number of sensor names
\\return a list of argument info structures
"""
function SoapySDRDevice_getChannelSettingInfo(device, direction, channel, length)
    ccall((:SoapySDRDevice_getChannelSettingInfo, soapysdr), Ptr{SoapySDRArgInfo}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Csize_t}), device, direction, channel, length)
end

"""
    SoapySDRDevice_writeChannelSetting(device, direction, channel, key, value)

Write an arbitrary channel setting on the device.
The interpretation is up the implementation.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param key the setting identifier
\\param value the setting value
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeChannelSetting(device, direction, channel, key, value)
    ccall((:SoapySDRDevice_writeChannelSetting, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}, Ptr{Cchar}), device, direction, channel, key, value)
end

"""
    SoapySDRDevice_readChannelSetting(device, direction, channel, key)

Read an arbitrary channel setting on the device.
\\param device a pointer to a device instance
\\param direction the channel direction RX or TX
\\param channel an available channel on the device
\\param key the setting identifier
\\return the setting value
"""
function SoapySDRDevice_readChannelSetting(device, direction, channel, key)
    ccall((:SoapySDRDevice_readChannelSetting, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ptr{Cchar}), device, direction, channel, key)
end

"""
    SoapySDRDevice_listGPIOBanks(device, length)

Get a list of available GPIO banks by name.
\\param [out] length the number of GPIO banks
\\param device a pointer to a device instance
"""
function SoapySDRDevice_listGPIOBanks(device, length)
    ccall((:SoapySDRDevice_listGPIOBanks, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Ptr{Csize_t}), device, length)
end

"""
    SoapySDRDevice_writeGPIO(device, bank, value)

Write the value of a GPIO bank.
\\param device a pointer to a device instance
\\param bank the name of an available bank
\\param value an integer representing GPIO bits
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeGPIO(device, bank, value)
    ccall((:SoapySDRDevice_writeGPIO, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Cuint), device, bank, value)
end

"""
    SoapySDRDevice_writeGPIOMasked(device, bank, value, mask)

Write the value of a GPIO bank with modification mask.
\\param device a pointer to a device instance
\\param bank the name of an available bank
\\param value an integer representing GPIO bits
\\param mask a modification mask where 1 = modify
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeGPIOMasked(device, bank, value, mask)
    ccall((:SoapySDRDevice_writeGPIOMasked, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Cuint, Cuint), device, bank, value, mask)
end

"""
    SoapySDRDevice_readGPIO(device, bank)

Readback the value of a GPIO bank.
\\param device a pointer to a device instance
\\param bank the name of an available bank
\\return an integer representing GPIO bits
"""
function SoapySDRDevice_readGPIO(device, bank)
    ccall((:SoapySDRDevice_readGPIO, soapysdr), Cuint, (Ptr{SoapySDRDevice}, Ptr{Cchar}), device, bank)
end

"""
    SoapySDRDevice_writeGPIODir(device, bank, dir)

Write the data direction of a GPIO bank.
1 bits represent outputs, 0 bits represent inputs.
\\param device a pointer to a device instance
\\param bank the name of an available bank
\\param dir an integer representing data direction bits
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeGPIODir(device, bank, dir)
    ccall((:SoapySDRDevice_writeGPIODir, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Cuint), device, bank, dir)
end

"""
    SoapySDRDevice_writeGPIODirMasked(device, bank, dir, mask)

Write the data direction of a GPIO bank with modification mask.
1 bits represent outputs, 0 bits represent inputs.
\\param device a pointer to a device instance
\\param bank the name of an available bank
\\param dir an integer representing data direction bits
\\param mask a modification mask where 1 = modify
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeGPIODirMasked(device, bank, dir, mask)
    ccall((:SoapySDRDevice_writeGPIODirMasked, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Cuint, Cuint), device, bank, dir, mask)
end

"""
    SoapySDRDevice_readGPIODir(device, bank)

Read the data direction of a GPIO bank.
\\param device a pointer to a device instance
1 bits represent outputs, 0 bits represent inputs.
\\param bank the name of an available bank
\\return an integer representing data direction bits
"""
function SoapySDRDevice_readGPIODir(device, bank)
    ccall((:SoapySDRDevice_readGPIODir, soapysdr), Cuint, (Ptr{SoapySDRDevice}, Ptr{Cchar}), device, bank)
end

"""
    SoapySDRDevice_writeI2C(device, addr, data, numBytes)

Write to an available I2C slave.
If the device contains multiple I2C masters,
the address bits can encode which master.
\\param device a pointer to a device instance
\\param addr the address of the slave
\\param data an array of bytes write out
\\param numBytes the number of bytes to write
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeI2C(device, addr, data, numBytes)
    ccall((:SoapySDRDevice_writeI2C, soapysdr), Cint, (Ptr{SoapySDRDevice}, Cint, Ptr{Cchar}, Csize_t), device, addr, data, numBytes)
end

"""
    SoapySDRDevice_readI2C(device, addr, numBytes)

Read from an available I2C slave.
If the device contains multiple I2C masters,
the address bits can encode which master.
Pass the number of bytes to be read in via numBytes;
numBytes will be set to the number of actual bytes read.
\\param device a pointer to a device instance
\\param addr the address of the slave
\\param [inout] numBytes the number of bytes to read
\\return an array of bytes read from the slave
"""
function SoapySDRDevice_readI2C(device, addr, numBytes)
    ccall((:SoapySDRDevice_readI2C, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice}, Cint, Ptr{Csize_t}), device, addr, numBytes)
end

"""
    SoapySDRDevice_transactSPI(device, addr, data, numBits)

Perform a SPI transaction and return the result.
Its up to the implementation to set the clock rate,
and read edge, and the write edge of the SPI core.
SPI slaves without a readback pin will return 0.

If the device contains multiple SPI masters,
the address bits can encode which master.

\\param device a pointer to a device instance
\\param addr an address of an available SPI slave
\\param data the SPI data, numBits-1 is first out
\\param numBits the number of bits to clock out
\\return the readback data, numBits-1 is first in
"""
function SoapySDRDevice_transactSPI(device, addr, data, numBits)
    ccall((:SoapySDRDevice_transactSPI, soapysdr), Cuint, (Ptr{SoapySDRDevice}, Cint, Cuint, Csize_t), device, addr, data, numBits)
end

"""
    SoapySDRDevice_listUARTs(device, length)

Enumerate the available UART devices.
\\param device a pointer to a device instance
\\param [out] length the number of UART names
\\return a list of names of available UARTs
"""
function SoapySDRDevice_listUARTs(device, length)
    ccall((:SoapySDRDevice_listUARTs, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{SoapySDRDevice}, Ptr{Csize_t}), device, length)
end

"""
    SoapySDRDevice_writeUART(device, which, data)

Write data to a UART device.
Its up to the implementation to set the baud rate,
carriage return settings, flushing on newline.
\\param device a pointer to a device instance
\\param which the name of an available UART
\\param data a null terminated array of bytes
\\return 0 for success or error code on failure
"""
function SoapySDRDevice_writeUART(device, which, data)
    ccall((:SoapySDRDevice_writeUART, soapysdr), Cint, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Ptr{Cchar}), device, which, data)
end

"""
    SoapySDRDevice_readUART(device, which, timeoutUs)

Read bytes from a UART until timeout or newline.
Its up to the implementation to set the baud rate,
carriage return settings, flushing on newline.
\\param device a pointer to a device instance
\\param which the name of an available UART
\\param timeoutUs a timeout in microseconds
\\return a null terminated array of bytes
"""
function SoapySDRDevice_readUART(device, which, timeoutUs)
    ccall((:SoapySDRDevice_readUART, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRDevice}, Ptr{Cchar}, Clong), device, which, timeoutUs)
end

"""
    SoapySDRDevice_getNativeDeviceHandle(device)

A handle to the native device used by the driver.
The implementation may return a null value if it does not support
or does not wish to provide access to the native handle.
\\param device a pointer to a device instance
\\return a handle to the native device or null
"""
function SoapySDRDevice_getNativeDeviceHandle(device)
    ccall((:SoapySDRDevice_getNativeDeviceHandle, soapysdr), Ptr{Cvoid}, (Ptr{SoapySDRDevice},), device)
end

"""
    SoapySDR_errToStr(errorCode)

Convert a error code to a string for printing purposes.
If the error code is unrecognized, errToStr returns "UNKNOWN".
\\param errorCode a negative integer return code
\\return a pointer to a string representing the error
"""
function SoapySDR_errToStr(errorCode)
    ccall((:SoapySDR_errToStr, soapysdr), Ptr{Cchar}, (Cint,), errorCode)
end

"""
    SoapySDR_formatToSize(format)

Get the size of a single element in the specified format.
\\param format a supported format string
\\return the size of an element in bytes
"""
function SoapySDR_formatToSize(format)
    ccall((:SoapySDR_formatToSize, soapysdr), Csize_t, (Ptr{Cchar},), format)
end

"""
    SoapySDRLogLevel

The available priority levels for log messages.

The default log level threshold is SOAPY_SDR_INFO.
Log messages with lower priorities are dropped.

The default threshold can be set via the
SOAPY_SDR_LOG_LEVEL environment variable.
Set SOAPY_SDR_LOG_LEVEL to the string value:
"WARNING", "ERROR", "DEBUG", etc...
or set it to the equivalent integer value.
"""
@cenum SoapySDRLogLevel::UInt32 begin
    SOAPY_SDR_FATAL = 1
    SOAPY_SDR_CRITICAL = 2
    SOAPY_SDR_ERROR = 3
    SOAPY_SDR_WARNING = 4
    SOAPY_SDR_NOTICE = 5
    SOAPY_SDR_INFO = 6
    SOAPY_SDR_DEBUG = 7
    SOAPY_SDR_TRACE = 8
    SOAPY_SDR_SSI = 9
end

"""
    SoapySDR_log(logLevel, message)

Send a message to the registered logger.
\\param logLevel a possible logging level
\\param message a logger message string
"""
function SoapySDR_log(logLevel, message)
    ccall((:SoapySDR_log, soapysdr), Cvoid, (SoapySDRLogLevel, Ptr{Cchar}), logLevel, message)
end

# typedef void ( * SoapySDRLogHandler ) ( const SoapySDRLogLevel logLevel , const char * message )
"""
Typedef for the registered log handler function.
"""
const SoapySDRLogHandler = Ptr{Cvoid}

"""
    SoapySDR_registerLogHandler(handler)

Register a new system log handler.
Platforms should call this to replace the default stdio handler.
Passing `NULL` restores the default.
"""
function SoapySDR_registerLogHandler(handler)
    ccall((:SoapySDR_registerLogHandler, soapysdr), Cvoid, (SoapySDRLogHandler,), handler)
end

"""
    SoapySDR_setLogLevel(logLevel)

Set the log level threshold.
Log messages with lower priority are dropped.
"""
function SoapySDR_setLogLevel(logLevel)
    ccall((:SoapySDR_setLogLevel, soapysdr), Cvoid, (SoapySDRLogLevel,), logLevel)
end

"""
    SoapySDR_getRootPath()

Query the root installation path
"""
function SoapySDR_getRootPath()
    ccall((:SoapySDR_getRootPath, soapysdr), Ptr{Cchar}, ())
end

"""
    SoapySDR_listSearchPaths(length)

The list of paths automatically searched by loadModules().
\\param [out] length the number of elements in the result.
\\return a list of automatically searched file paths
"""
function SoapySDR_listSearchPaths(length)
    ccall((:SoapySDR_listSearchPaths, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Csize_t},), length)
end

"""
    SoapySDR_listModules(length)

List all modules found in default path.
The result is an array of strings owned by the caller.
\\param [out] length the number of elements in the result.
\\return a list of file paths to loadable modules
"""
function SoapySDR_listModules(length)
    ccall((:SoapySDR_listModules, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Csize_t},), length)
end

"""
    SoapySDR_listModulesPath(path, length)

List all modules found in the given path.
The result is an array of strings owned by the caller.
\\param path a directory on the system
\\param [out] length the number of elements in the result.
\\return a list of file paths to loadable modules
"""
function SoapySDR_listModulesPath(path, length)
    ccall((:SoapySDR_listModulesPath, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Cchar}, Ptr{Csize_t}), path, length)
end

"""
    SoapySDR_loadModule(path)

Load a single module given its file system path.
The caller must free the result error string.
\\param path the path to a specific module file
\\return an error message, empty on success
"""
function SoapySDR_loadModule(path)
    ccall((:SoapySDR_loadModule, soapysdr), Ptr{Cchar}, (Ptr{Cchar},), path)
end

"""
    SoapySDR_getLoaderResult(path)

List all registration loader errors for a given module path.
The resulting dictionary contains all registry entry names
provided by the specified module. The value of each entry
is an error message string or empty on successful load.
\\param path the path to a specific module file
\\return a dictionary of registry names to error messages
"""
function SoapySDR_getLoaderResult(path)
    ccall((:SoapySDR_getLoaderResult, soapysdr), SoapySDRKwargs, (Ptr{Cchar},), path)
end

"""
    SoapySDR_getModuleVersion(path)

Get a version string for the specified module.
Modules may optionally provide version strings.
\\param path the path to a specific module file
\\return a version string or empty if no version provided
"""
function SoapySDR_getModuleVersion(path)
    ccall((:SoapySDR_getModuleVersion, soapysdr), Ptr{Cchar}, (Ptr{Cchar},), path)
end

"""
    SoapySDR_unloadModule(path)

Unload a module that was loaded with loadModule().
The caller must free the result error string.
\\param path the path to a specific module file
\\return an error message, empty on success
"""
function SoapySDR_unloadModule(path)
    ccall((:SoapySDR_unloadModule, soapysdr), Ptr{Cchar}, (Ptr{Cchar},), path)
end

"""
    SoapySDR_loadModules()

Load the support modules installed on this system.
This call will only actually perform the load once.
Subsequent calls are a NOP.
"""
function SoapySDR_loadModules()
    ccall((:SoapySDR_loadModules, soapysdr), Cvoid, ())
end

"""
    SoapySDR_unloadModules()

Unload all currently loaded support modules.
"""
function SoapySDR_unloadModules()
    ccall((:SoapySDR_unloadModules, soapysdr), Cvoid, ())
end

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

"""
    SoapySDRKwargs_fromString(markup)

Convert a markup string to a key-value map.
The markup format is: "key0=value0, key1=value1"
"""
function SoapySDRKwargs_fromString(markup)
    ccall((:SoapySDRKwargs_fromString, soapysdr), SoapySDRKwargs, (Ptr{Cchar},), markup)
end

"""
    SoapySDRKwargs_toString(args)

Convert a key-value map to a markup string.
The markup format is: "key0=value0, key1=value1"
"""
function SoapySDRKwargs_toString(args)
    ccall((:SoapySDRKwargs_toString, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRKwargs},), args)
end

"""
    SoapySDR_free(ptr)

Free a pointer allocated by SoapySDR.
For most platforms this is a simple call around free()
"""
function SoapySDR_free(ptr)
    ccall((:SoapySDR_free, soapysdr), Cvoid, (Ptr{Cvoid},), ptr)
end

"""
    SoapySDRStrings_clear(elems, length)

Clear the contents of a list of string
Convenience call to deal with results that return a string list.
"""
function SoapySDRStrings_clear(elems, length)
    ccall((:SoapySDRStrings_clear, soapysdr), Cvoid, (Ptr{Ptr{Ptr{Cchar}}}, Csize_t), elems, length)
end

"""
    SoapySDRKwargs_set(args, key, val)

Set a key/value pair in a kwargs structure.
\\post
If the key exists, the existing entry will be modified;
otherwise a new entry will be appended to args.
On error, the elements of args will not be modified,
and args is guaranteed to be in a good state.
\\return 0 for success, otherwise allocation error
"""
function SoapySDRKwargs_set(args, key, val)
    ccall((:SoapySDRKwargs_set, soapysdr), Cint, (Ptr{SoapySDRKwargs}, Ptr{Cchar}, Ptr{Cchar}), args, key, val)
end

"""
    SoapySDRKwargs_get(args, key)

Get a value given a key in a kwargs structure.
\\return the string or NULL if not found
"""
function SoapySDRKwargs_get(args, key)
    ccall((:SoapySDRKwargs_get, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRKwargs}, Ptr{Cchar}), args, key)
end

"""
    SoapySDRKwargs_clear(args)

Clear the contents of a kwargs structure.
This frees all the underlying memory and clears the members.
"""
function SoapySDRKwargs_clear(args)
    ccall((:SoapySDRKwargs_clear, soapysdr), Cvoid, (Ptr{SoapySDRKwargs},), args)
end

"""
    SoapySDRKwargsList_clear(args, length)

Clear a list of kwargs structures.
This frees all the underlying memory and clears the members.
"""
function SoapySDRKwargsList_clear(args, length)
    ccall((:SoapySDRKwargsList_clear, soapysdr), Cvoid, (Ptr{SoapySDRKwargs}, Csize_t), args, length)
end

"""
    SoapySDRArgInfo_clear(info)

Clear the contents of a argument info structure.
This frees all the underlying memory and clears the members.
"""
function SoapySDRArgInfo_clear(info)
    ccall((:SoapySDRArgInfo_clear, soapysdr), Cvoid, (Ptr{SoapySDRArgInfo},), info)
end

"""
    SoapySDRArgInfoList_clear(info, length)

Clear a list of argument info structures.
This frees all the underlying memory and clears the members.
"""
function SoapySDRArgInfoList_clear(info, length)
    ccall((:SoapySDRArgInfoList_clear, soapysdr), Cvoid, (Ptr{SoapySDRArgInfo}, Csize_t), info, length)
end

"""
    SoapySDR_getAPIVersion()

Get the SoapySDR library API version as a string.
The format of the version string is <b>major.minor.increment</b>,
where the digits are taken directly from <b>SOAPY_SDR_API_VERSION</b>.
"""
function SoapySDR_getAPIVersion()
    ccall((:SoapySDR_getAPIVersion, soapysdr), Ptr{Cchar}, ())
end

"""
    SoapySDR_getABIVersion()

Get the ABI version string that the library was built against.
A client can compare <b>SOAPY_SDR_ABI_VERSION</b> to getABIVersion()
to check for ABI incompatibility before using the library.
If the values are not equal then the client code was
compiled against a different ABI than the library.
"""
function SoapySDR_getABIVersion()
    ccall((:SoapySDR_getABIVersion, soapysdr), Ptr{Cchar}, ())
end

"""
    SoapySDR_getLibVersion()

Get the library version and build information string.
The format of the version string is <b>major.minor.patch-buildInfo</b>.
This function is commonly used to identify the software back-end
to the user for command-line utilities and graphical applications.
"""
function SoapySDR_getLibVersion()
    ccall((:SoapySDR_getLibVersion, soapysdr), Ptr{Cchar}, ())
end

# Skipping MacroDefinition: SOAPY_SDR_HELPER_DLL_IMPORT __attribute__ ( ( visibility ( "default" ) ) )

# Skipping MacroDefinition: SOAPY_SDR_HELPER_DLL_EXPORT __attribute__ ( ( visibility ( "default" ) ) )

# Skipping MacroDefinition: SOAPY_SDR_HELPER_DLL_LOCAL __attribute__ ( ( visibility ( "hidden" ) ) )

# Skipping MacroDefinition: SOAPY_SDR_EXTERN extern

const SOAPY_SDR_TX = 0

const SOAPY_SDR_RX = 1

const SOAPY_SDR_END_BURST = 1 << 1

const SOAPY_SDR_HAS_TIME = 1 << 2

const SOAPY_SDR_END_ABRUPT = 1 << 3

const SOAPY_SDR_ONE_PACKET = 1 << 4

const SOAPY_SDR_MORE_FRAGMENTS = 1 << 5

const SOAPY_SDR_WAIT_TRIGGER = 1 << 6

const SOAPY_SDR_TIMEOUT = -1

const SOAPY_SDR_STREAM_ERROR = -2

const SOAPY_SDR_CORRUPTION = -3

const SOAPY_SDR_OVERFLOW = -4

const SOAPY_SDR_NOT_SUPPORTED = -5

const SOAPY_SDR_TIME_ERROR = -6

const SOAPY_SDR_UNDERFLOW = -7

const SOAPY_SDR_CF64 = "CF64"

const SOAPY_SDR_CF32 = "CF32"

const SOAPY_SDR_CS32 = "CS32"

const SOAPY_SDR_CU32 = "CU32"

const SOAPY_SDR_CS16 = "CS16"

const SOAPY_SDR_CU16 = "CU16"

const SOAPY_SDR_CS12 = "CS12"

const SOAPY_SDR_CU12 = "CU12"

const SOAPY_SDR_CS8 = "CS8"

const SOAPY_SDR_CU8 = "CU8"

const SOAPY_SDR_CS4 = "CS4"

const SOAPY_SDR_CU4 = "CU4"

const SOAPY_SDR_F64 = "F64"

const SOAPY_SDR_F32 = "F32"

const SOAPY_SDR_S32 = "S32"

const SOAPY_SDR_U32 = "U32"

const SOAPY_SDR_S16 = "S16"

const SOAPY_SDR_U16 = "U16"

const SOAPY_SDR_S8 = "S8"

const SOAPY_SDR_U8 = "U8"

const SOAPY_SDR_SSI = SOAPY_SDR_SSI

const SOAPY_SDR_TRUE = "true"

const SOAPY_SDR_FALSE = "false"

const SOAPY_SDR_API_VERSION = 0x00080000

const SOAPY_SDR_ABI_VERSION = "0.8"

