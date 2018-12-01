# Interface definition for Soapy SDR devices.
# 
# General design rules about the API:
# The caller must free non-const array results.

# Forward declaration of device handle
mutable struct SoapySDRDevice
end

# Forward declaration of stream handle
mutable struct SoapySDRStream
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
    sz = Ref{Csize_t}()
    kwargs = ccall((:SoapySDRDevice_enumerate, lib), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, sz)
    return (kwargs, sz)
end

# Enumerate a list of available devices on the system.
# Markup format for args: "keyA=valA, keyB=valB".
# param args a markup string of key/value argument filters
# param [out] length the number of elements in the result.
# return a list of arguments strings, each unique to a device
function SoapySDRDevice_enumerateStrArgs(args)
    sz = Ref{Csize_t}()
    kwargs = ccall((:SoapySDRDevice_enumerateStrArgs, lib), Ptr{SoapySDRKwargs}, (Cstring, Ref{Csize_t}), args, sz)
    return (kwargs, sz)
end

# Make a new Device object given device construction args.
# The device pointer will be stored in a table so subsequent calls
# with the same arguments will produce the same device.
# For every call to make, there should be a matched call to unmake.
# param args device construction key/value argument map
# return a pointer to a new Device object
function SoapySDRDevice_make(args) # have not checked
    #ccall((:SoapySDRDevice_make, lib), Ptr{SoapySDRDevice}, (,), args)
    r = ccall((:SoapySDRDevice_make, lib), Ptr{SoapySDRDevice}, (Ref{SoapySDRKwargs},), args)
    @show r
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
## Identificatoin API ##    # have not checked any of these
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
function SoapySDRDevice_getHardwareInfo()
    ccall((:SoapySDRDevice_getHardwareInfo, lib), Cint, ())
end

#################
## ANTENNA API ##
#################

# Get a list of available antennas to select on a given chain.
# param device a pointer to a device instance
# param direction the channel direction RX or TX
# param channel an available channel on the device
# param [out] length the number of antenna names
# return a list of available antenna names
function SoapySDRDevice_listAntennas(device, direction, channel)
    #ccall((:SoapySDRDevice_listAntennas, Device), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Cint, Ptr{Cint}), device, direction, channel, length)
    leng = Ref{Csize_t}()
    names = ccall((:SoapySDRDevice_listAntennas, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, leng)
    return (names, leng)
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
#function SoapySDRDevice_listGains(device, direction, channel, length)
function SoapySDRDevice_listGains(device, direction, channel)
    #ccall((:SoapySDRDevice_listGains, lib), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Cint, Ptr{Cint}), device, direction, channel, length)
    leng = Ref{Csize_t}()
    names = ccall((:SoapySDRDevice_listGains, "libSoapySDR.so"), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, leng)
    #names3 = unsafe_string(unsafe_load(names))
    return (names, leng)
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
    #ccall((:SoapySDRDevice_getFrequencyRange, Device), Ptr{Cint}, ())
    leng = Ref{Csize_t}()
    ranges = ccall((:SoapySDRDevice_getFrequencyRange, lib), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), device, direction, channel, leng)
    return (ranges, leng)
end

#####################
## SAMPLE RATE API ##
#####################

# Set the baseband sample rate of the chain.
# param device a pointer to a device instance
# param direction the channel direction RX or TX
# param channel an available channel on the device
# param rate the sample rate in samples per
function SoapySDRDevice_setSampleRate(device, direction, channel, rate)
    #ccall((:SoapySDRDevice_setSampleRate, lib), Cint, (Ptr{SoapySDRDevice}, Cint, Cint, Cdouble), device, direction, channel, rate)
    ccall((:SoapySDRDevice_setSampleRate, lib), Cint, (Ref{SoapySDRDevice}, Cint, Csize_t, Cdouble), device, direction, channel, rate)
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
#function SoapySDRDevice_setFrequency(device, direction::Cint, channel::Cint, frequency::Cdouble, args)
#function SoapySDRDevice_setFrequency(device, direction, channel, frequency, args)
function SoapySDRDevice_setFrequency(device, direction, channel, frequency)
    #ccall((:SoapySDRDevice_setFrequency, lib), Cint, (Ptr{SoapySDRDevice}, Cint, Cint, Cdouble, Ptr{Cint}), device, direction, channel, frequency, args)
    #args = Ref{SoapySDRKwargs}()
    #ccall((:SoapySDRDevice_setFrequency, lib), Int, (Ref{SoapySDRDevice}, Cint, Csize_t, Cdouble, Ref{SoapySDRKwargs}), device, direction, channel, frequency, args)
    #ccall((:SoapySDRDevice_setFrequency, lib), Int, (Ref{SoapySDRDevice}, Cint, Csize_t, Cdouble, Ref{SoapySDRKwargs}), device, direction, channel, frequency, C_NULL)
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
    #ccall((:SoapySDRDevice_setupStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{Ptr{SoapySDRStream}}, Cint, Cstring, Ptr{Cint}, Cint, Ptr{Cint}), device, stream, direction, format, channels, numChans, args)
    #ccall((:SoapySDRDevice_setupStream, lib), Int, (Ref{SoapySDRDevice}, Ref{Ref{SoapySDRStream}}, Cint, Cstring, Ref{Csize_t}, Csize_t, Ref{SoapySDRKwargs}), device, stream, direction, format, channels, numChans, args)
    ccall((:SoapySDRDevice_setupStream, lib), Int, (Ref{SoapySDRDevice}, Ref{Ref{SoapySDRStream}}, Cint, Cstring, Ref{Csize_t}, Csize_t, Ptr{Nothing}), device, stream, direction, format, channels, numChans, C_NULL)
    #ccall((:SoapySDRDevice_setupStream, lib), Int, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}, Cint, Cstring, Ref{Csize_t}, Csize_t, Ptr{Nothing}), device, stream, direction, format, channels, numChans, C_NULL)
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
    #ccall((:SoapySDRDevice_activateStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Cint, Clonglong, Csize_t), device, stream, flags, timeNs, numElems)
    #ccall((:SoapySDRDevice_activateStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Cint, Clonglong, Csize_t), device, stream, flags, timeNs, numElems)
    ccall((:SoapySDRDevice_activateStream, lib), Cint, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}, Cint, Clonglong, Csize_t), device, stream, flags, timeNs, numElems)
    #ccall((:SoapySDRDevice_activateStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Cint, Clonglong, Cint), device, stream, flags, timeNs, numElems)
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
    #ccall((:SoapySDRDevice_readStream, lib), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Ptr{Ptr{Cvoid}}, Cint, Ptr{Cint}, Ptr{Clonglong}, Clong), device, stream, buffs, numElems, flags, timeNs, timeoutUs)
    #ccall((:SoapySDRDevice_readStream, lib), Cint, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}, Ptr{Ptr{Cvoid}}, Csize_t, Ptr{Cint}, Ptr{Clonglong}, Clong), device, stream, buffs, numElems, flags, timeNs, timeoutUs)
    #ccall((:SoapySDRDevice_readStream, lib), Cint, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}, Ref{Ref{Cvoid}}, Csize_t, Ptr{Cint}, Ptr{Clonglong}, Clong), device, stream, buffs, numElems, flags, timeNs, timeoutUs)
    ccall((:SoapySDRDevice_readStream, lib), Cint, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}, Ptr{Ptr{Cvoid}}, Csize_t, Ptr{Cint}, Ptr{Clonglong}, Clong), device, stream, map(pointer, buffs), numElems, flags, timeNs, timeoutUs) # THIS SOMEWHAT WORKS

#Ref{ComplexF32}
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
