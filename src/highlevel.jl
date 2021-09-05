# High level API exports

export Devices, dB, gainrange

## KWArgs

abstract type KWArgs <: AbstractDict{Symbol, String}; end

mutable struct OwnedKWArgs <: KWArgs
    ptr::SoapySDRKwargs
    function OwnedKWArgs(kw::SoapySDRKwargs)
        this = new(kw)
        finalizer(SoapySDRKwargs_clear, this)
        this
    end
end
Base.unsafe_load(o::OwnedKWArgs) = o.ptr
function ptr(kw::OwnedKWArgs)
    return pointer_from_objref(kw)
end

mutable struct KWArgsList <: AbstractVector{KWArgs}
    ptr::Ptr{SoapySDRKwargs}
    length::Csize_t
    function KWArgsList(ptr::Ptr{SoapySDRKwargs}, length::Csize_t)
        this = new(ptr, length)
        finalizer(SoapySDRKwargsList_clear, this)
        this
    end
end
Base.size(kwl::KWArgsList) = (kwl.length,)

struct KWArgsListRef <: KWArgs
    list::KWArgsList
    idx::Int
    function Base.getindex(kwl::KWArgsList, i::Integer)
        checkbounds(kwl, i)
        new(kwl, i)
    end
end

function ptr(kwl::KWArgsListRef)
    @assert kwl.list.ptr !== C_NULL
    kwl.list.ptr + (kwl.idx-1)*sizeof(SoapySDRKwargs)
end

Base.unsafe_load(kw::KWArgs) = unsafe_load(ptr(kw))
Base.length(kw::KWArgs) = unsafe_load(kw).size
function _getindex(kw::KWArgs, i::Integer)
    1 <= i <= length(kw) || throw(BoundsError(kw, i))
    @GC.preserve kw begin
        return Symbol(unsafe_string(unsafe_load(unsafe_load(kw).keys, i))) =>
               unsafe_string(unsafe_load(unsafe_load(kw).vals, i))
    end
end

Base.iterate(kw::KWArgs, i=1) = i > length(kw) ? nothing : (_getindex(kw, i), i+1)

function SoapySDRKwargs_clear(kw::OwnedKWArgs)
    SoapySDRKwargs_clear(pointer(kw))
end

function SoapySDRKwargsList_clear(list::KWArgsList)
    SoapySDRKwargsList_clear(list.ptr, list.length)
    list.ptr = C_NULL
end

##

mutable struct StringList <: AbstractVector{String}
    strs::Ptr{Cstring}
    length::Csize_t
    function StringList(strs::Ptr{Cstring}, length::Integer)
        this = new(strs, Csize_t(length))
        finalizer(SoapySDRStrings_clear, this)
        this
    end
end
Base.size(s::StringList) = (s.length,)
function Base.getindex(s::StringList, i::Integer)
    checkbounds(s, i)
    unsafe_string(unsafe_load(s.strs, i))
end

SoapySDRStrings_clear(s::StringList) = @GC.preserve s SoapySDRStrings_clear(pointer_from_objref(s), s.length)

"""
    Devices()

Enumerates all detectable SDR devices on the system.
Indexing into this list return a `Device` struct.
"""
struct Devices
    kwargslist::KWArgsList
    Devices() = new(KWArgsList(SoapySDRDevice_enumerate()...))
end
Base.length(d::Devices) = length(d.kwargslist)

function Base.show(io::IO, d::Devices)
    if length(d) == 0
        println(io, "No devices available! Make sure a supported SDR module is included.")
    end
    for (i, dev) in enumerate(d.kwargslist)
        print(io, "[$i] ")
        join(io, dev, ", ")
        println(io)
    end
end

"""
    Device

A device is a collection of SDR channels, obtained from the `Devices()` list.

Fields:
- `info`
- `driver`
- `hardware`
- `hardwareinfo`
- `tx`
- `rx`
"""
mutable struct Device
    ptr::Ptr{SoapySDRDevice}
    function Device(ptr::Ptr{SoapySDRDevice})
        this = new(ptr)
        finalizer(SoapySDRDevice_unmake, this)
        return this
    end
end
SoapySDRDevice_unmake(d::Device) = SoapySDRDevice_unmake(d.ptr)
Base.cconvert(::Type{<:Ptr{SoapySDRDevice}}, d::Device) = d
Base.unsafe_convert(::Type{<:Ptr{SoapySDRDevice}}, d::Device) = d.ptr

function Base.show(io::IO, d::Device)
    print(io, "SoapySDR ", d.hardware, " device (driver: ", d.driver, ") w/ ", length(d.tx), " TX channels and ", length(d.rx), " RX channels")
end

function Base.getindex(d::Devices, i::Integer)
    Device(SoapySDRDevice_make(ptr(d.kwargslist[i])))
end
Base.iterate(d::Devices, state=1) = state > length(d) ? nothing : (d[state], state+1)

function Base.getproperty(d::Device, s::Symbol)
    if s === :info
        OwnedKWArgs(SoapySDRDevice_getHardwareInfo(d))
    elseif s === :driver
        Symbol(unsafe_string(SoapySDRDevice_getDriverKey(d)))
    elseif s === :hardware
        Symbol(unsafe_string(SoapySDRDevice_getHardwareKey(d)))
    elseif s === :hardwareinfo #TODO
        SoapySDRDevice_getHardwareInfo(d) # TODO wrap
    elseif s === :tx
        ChannelList(d, Tx)
    elseif s === :rx
        ChannelList(d, Rx)
    else
        getfield(d, s)
    end
end

##

struct Channel
    device::Device
    direction::Direction
    idx::Int
end
Base.show(io::IO, c::Channel) =
    print(io, "Channel(", c.device.hardware, ", ", c.direction, ", ", c.idx, ")")

# Express everything in (kHz, MHz, GHz)
function pick_freq_unit(val::Quantity)
    iszero(val.val) && return val
    abs(val) >= 1.0u"GHz" ? uconvert(u"GHz", val) :
    abs(val) >= 1.0u"MHz" ? uconvert(u"MHz", val) :
                            uconvert(u"kHz", val)
end

# Print to 3 digits of precision, no decimal point
print_3_digit(io::IO, val::Quantity) =  print(io, Base.Ryu.writeshortest(round(val.val, sigdigits=3),
    #= plus =# false,
    #= space =# false,
    #= hash =# false,
    ))

function print_unit(io::IO, val::Quantity)
    print_3_digit(io, val)
    print(io, " ", unit(val))
end

function print_unit_interval(io::IO, min, max)
    if unit(min) == unit(max) || iszero(min.val)
        print_3_digit(io, min)
        print(io, "..")
        print_3_digit(io, max)
        print(io, " ", unit(max))
    else
        print_unit(io, min)
        print(io, " .. ")
        print_unit(io, max)
    end
end
print_unit_interval(io::IO, x::Interval{<:Any, Closed, Closed}) =
    print_unit_interval(io, minimum(x), maximum(x))

using Intervals: Closed
function print_hz_range(io::IO, x::Interval{<:Any, Closed, Closed})
    min, max = pick_freq_unit(minimum(x)), pick_freq_unit(maximum(x))
    print_unit_interval(io, min, max)
end

function Base.show(io::IO, ::MIME"text/plain", c::Channel)
    println(io, c.direction == Tx ? "TX" : "RX", " Channel #", c.idx + 1, " on ", c.device.hardware)
    if !get(io, :compact, false)
        print(io, "  Selected Antenna [")
            join(io, AntennaList(c), ", ")
            println(io, "]: ", c.antenna)
        print(io, "  Bandwidth [ ")
            join(io, map(x->sprint(print_hz_range, x), bandwidth_ranges(c)), ", ")
            println(io, " ]: ", pick_freq_unit(c.bandwidth))
        print(io, "  Frequency [ ")
                join(io, map(x->sprint(print_hz_range, x), frequency_ranges(c)), ", ")
                println(io, " ]: ", pick_freq_unit(c.frequency))
            for element in FrequencyComponentList(c)
                print(io, "    ", element, " [ ")
                join(io, map(x->sprint(print_hz_range, x), frequency_ranges(c, element)), ", ")
                println(io, " ]: ", pick_freq_unit(c[element]))
            end  
        println(io, "  Gain ", gainrange(c), ": ", c.gain)
            for element in GainElementList(c)
                println(io, "    ", element, " ", gainrange(c,element), ": ", c[element])
            end
        print(io, "  Sample Rate [ ", )
            join(io, map(x->sprint(print_hz_range, x), sample_rate_ranges(c)), ", ")
            println(io, " ]: ", pick_freq_unit(c.sample_rate))
        c.dc_offset_mode !== missing && println(io, "  Automatic DC offset correction: ", c.dc_offset_mode ? "ON" : "OFF")
        c.dc_offset !== missing && println(io, "  DC offset correction: ", c.dc_offset)
        c.iq_balance_mode !== missing && println(io, "  Automatic IQ balance correction: ", c.iq_balance_mode ? "ON" : "OFF")
        c.iq_balance !== missing && println(io, "  IQ balance correction: ", c.iq_balance)
        c.frequency_correction !== missing && println(io, "  Frequency correction: ", c.frequency_correction, " ppm")
    end
end

"""
    native_stream_format(c::Channel)

Returns the format type and fullscale resolution of the native stream.
"""
function native_stream_format(c::Channel)
    fmt, fullscale = SoapySDRDevice_getNativeStreamFormat(c.device.ptr, c.direction, c.idx)
    _stream_type_soapy2jl[unsafe_string(fmt)], fullscale
end

struct ChannelList <: AbstractVector{Channel}
    device::Device
    direction::Direction
end

function Base.size(cl::ChannelList)
    (SoapySDRDevice_getNumChannels(cl.device, cl.direction),)
end

function Base.getindex(cl::ChannelList, i::Integer)
    checkbounds(cl, i)
    Channel(cl.device, cl.direction, i-1)
end    

function Base.getproperty(c::Channel, s::Symbol)
    if s === :info
        return OwnedKWArgs(SoapySDRDevice_getChannelInfo(c.device.ptr, c.direction, c.idx))
    elseif s === :antenna
        return Antenna(Symbol(unsafe_string(SoapySDRDevice_getAntenna(c.device.ptr, c.direction, c.idx))))
    elseif s === :gain
        return SoapySDRDevice_getGain(c.device.ptr, c.direction, c.idx)*dB
    elseif s === :dc_offset_mode
        if !SoapySDRDevice_hasDCOffsetMode(c.device.ptr, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getDCOffsetMode(c.device.ptr, c.direction, c.idx)
    elseif s === :dc_offset
        if !SoapySDRDevice_hasDCOffset(c.device.ptr, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getDCOffset(c.device.ptr, c.direction, c.idx)
    elseif s === :iq_balance_mode
        if !SoapySDRDevice_hasIQBalanceMode(c.device.ptr, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getIQBalanceMode(c.device.ptr, c.direction, c.idx)
    elseif s === :iq_balance
        if !SoapySDRDevice_hasIQBalance(c.device.ptr, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getIQBalance(c.device.ptr, c.direction, c.idx)
    elseif s === :gain_mode
        if !SoapySDRDevice_hasGainMode(c.device.ptr, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getGainMode(c.device.ptr, c.direction, c.idx)
    elseif s === :frequency_correction
        if !SoapySDRDevice_hasFrequencyCorrection(c.device.ptr, c.direction, c.idx)
            return missing
        end
        # TODO: ppm unit?
        return SoapySDRDevice_getFrequencyCorrection(c.device.ptr, c.direction, c.idx)
    elseif s === :sample_rate
        return SoapySDRDevice_getSampleRate(c.device.ptr, c.direction, c.idx) * Hz
    elseif s === :bandwidth
        return SoapySDRDevice_getBandwidth(c.device.ptr, c.direction, c.idx) * Hz
    elseif s === :frequency
        return SoapySDRDevice_getFrequency(c.device.ptr, c.direction, c.idx) * Hz
    else
        return getfield(c, s)
    end
end

function Base.setproperty!(c::Channel, s::Symbol, v)
    if s === :frequency
        if isa(v, Quantity)
            SoapySDRDevice_setFrequency(c.device.ptr, c.direction, c.idx, uconvert(u"Hz", v).val, C_NULL)
        elseif isa(v, FreqSpec)
            error("TODO")
        else
            error("Frequency must be specified as either a Quantity or a FreqSpec!")
        end
    elseif s === :bandwidth
        SoapySDRDevice_setBandwidth(c.device.ptr, c.direction, c.idx, uconvert(u"Hz", v).val)
    elseif s === :gain
        SoapySDRDevice_setGain(c.device.ptr, c.direction, c.idx, uconvert(u"dB", v).val)
    elseif s === :sample_rate
        SoapySDRDevice_setSampleRate(c.device.ptr, c.direction, c.idx, uconvert(u"Hz", v).val)
    else
        return setfield!(c, s, v)
    end
end

## Antenna/GainElement/FrequencyComponent

abstract type Component; end
Base.print(io::IO, c::Component) = print(io, c.name)

struct ComponentList{T<:Component} <: AbstractVector{T}
    s::StringList
end
Base.size(l::ComponentList) = (length(l.s),)
Base.getindex(l::ComponentList{T}, i::Integer) where {T} = T(Symbol(l.s[i]))
    
for (e, f) in zip((:Antenna, :GainElement, :FrequencyComponent),
               (:SoapySDRDevice_listAntennas, :SoapySDRDevice_listGains, :SoapySDRDevice_listFrequencies))
    @eval begin
        struct $e <: Component; name::Symbol; end
        $f(channel::Channel) =
            $f(channel.device, channel.direction, channel.idx)
        $(Symbol(string(e, "List")))(channel::Channel) = ComponentList{$e}(StringList($f(channel)...))
    end
end

using Base: unsafe_convert
function Base.getindex(c::Channel, ge::GainElement)
    SoapySDRDevice_getGainElement(c.device, c.direction, c.idx, Cstring(unsafe_convert(Ptr{UInt8}, ge.name))) * dB
end

function Base.getindex(c::Channel, fe::FrequencyComponent)
    SoapySDRDevice_getFrequencyComponent(c.device, c.direction, c.idx, Cstring(unsafe_convert(Ptr{UInt8}, fe.name))) * Hz
end

## GainElement

function _gainrange(soapyr::SoapySDRRange)
    if soapyr.step == 0.0
        # Represents an interval rather than a range
        return (soapyr.minimum*dB)..(soapyr.maximum*dB)
    end
    return range(soapyr.minimum*dB; stop=soapyr.maximum*dB, step=soapyr.step*dB)
end

function gainrange(c::Channel)
    return _gainrange(SoapySDRDevice_getGainRange(c.device, c.direction, c.idx))
end

gainrange(c::Channel, ge::GainElement) =
    return _gainrange(SoapySDRDevice_getGainElementRange(c.device, c.direction, c.idx, Cstring(unsafe_convert(Ptr{UInt8}, ge.name))))

function Base.setindex!(c::Channel, gain::typeof(1.0dB), ge::GainElement)
    SoapySDRDevice_setGainElement(c.device, c.direction, c.idx, Cstring(unsafe_convert(Ptr{UInt8}, ge.name, gain.val)))
    return gain
end

function _hzrange(soapyr::SoapySDRRange)
    if soapyr.step == 0.0
        # Represents an interval rather than a range
        return (soapyr.minimum*Hz)..(soapyr.maximum*Hz)
    end
    return range(soapyr.minimum*Hz; stop=soapyr.maximum*Hz, step=soapyr.step*Hz)
end

function bandwidth_ranges(c::Channel)
    (ptr, len) = SoapySDRDevice_getBandwidthRange(c.device.ptr, c.direction, c.idx)
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len,)))
    SoapySDR_free(ptr)
    arr
end

function frequency_ranges(c::Channel)
    (ptr, len) = SoapySDRDevice_getFrequencyRange(c.device.ptr, c.direction, c.idx)
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len,)))
    SoapySDR_free(ptr)
    arr
end

function frequency_ranges(c::Channel, fe::FrequencyComponent)
    (ptr, len) = SoapySDRDevice_getFrequencyRangeComponent(c.device.ptr, c.direction, c.idx, Cstring(unsafe_convert(Ptr{UInt8}, fe.name)))
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len,)))
    SoapySDR_free(ptr)
    arr
end

function sample_rate_ranges(c::Channel)
    (ptr, len) = SoapySDRDevice_getSampleRateRange(c.device.ptr, c.direction, c.idx)
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len,)))
    SoapySDR_free(ptr)
    arr
end

"""
    list_sample_rates(::Channel)

List the natively supported sample rates for a given channel.
"""
function list_sample_rates(c::Channel)
    (ptr, len) = SoapySDRDevice_listSampleRates(c.device.ptr, c.direction, c.idx)
    arr = unsafe_wrap(Array, Ptr{Float64}(ptr), (len,)) * Hz
    SoapySDR_free(ptr)
    arr
end

### Frequency Setting
struct FreqSpec{T}
    val::T
    kwargs::Dict{Any, String}
end

### Streams

#TODO {T} ?
struct StreamFormat
    T
end
function Base.print(io::IO, sf::StreamFormat)
    T = sf.T
    if T <: Complex
        print(io, 'C')
        T = real(T)
    end
    if T <: AbstractFloat
        print(io, 'F')
    elseif T <: Signed
        print(io, 'S')
    elseif T <: Unsigned
        print(io, 'U')
    else
        error("Unknown format")
    end
    print(io, 8*sizeof(T))
end

function StreamFormat(s::String)
    if haskey(_stream_type_soapy2jl, s)
        T = _stream_type_soapy2jl[s]
        return StreamFormat(T)
    else
        error("Unknown format")
    end
end

function stream_formats(c::Channel)
    slist = StringList(SoapySDRDevice_getStreamFormats(c.device.ptr, c.direction, c.idx)...)
    map(StreamFormat, slist)
end

## Stream

mutable struct Stream{T}
    d::Device
    nchannels::Int
    ptr::Ptr{SoapySDRStream}
    function Stream{T}(d::Device, nchannels::Int, ptr::Ptr{SoapySDRStream}) where {T}
        this = new{T}(d, nchannels, ptr)
        finalizer(SoapySDRDevice_closeStream, this)
        return this
    end
end
Base.cconvert(::Type{<:Ptr{SoapySDRStream}}, s::Stream) = s
Base.unsafe_convert(::Type{<:Ptr{SoapySDRStream}}, s::Stream) = s.ptr
SoapySDRDevice_closeStream(s::Stream) = SoapySDRDevice_closeStream(s.d, s)

function Base.show(io::IO, s::Stream)
    print(io, "Stream on ", s.d.hardware)
end

function Stream(format::Union{StreamFormat, Type}, device::Device, direction::Direction; kwargs...)
    format = StreamFormat(format) # TODO isa(format, StreamFormat) ? format : StreamFormat(format)?
    isempty(kwargs) || error("TODO")
    Stream{T}(device, 1, SoapySDRDevice_setupStream(device, direction, string(format), C_NULL, 0, C_NULL))
end

function Stream(format::Union{StreamFormat, Type}, channels::Vector{Channel}; kwargs...)
    format = StreamFormat(format) # TODO isa(format, StreamFormat) ? format : StreamFormat(format)?
    isempty(kwargs) || error("TODO")
    isempty(channels) && error("Must specify at least one channel or use the device/direction constructor for automatic.")
    device = first(channels).device
    direction = first(channels).direction
    if !all(channels) do channel
                channel.device == device && channel.direction == direction
            end
        throw(ArgumentError("Channels must agree on device and direction"))
    end
    Stream{format.T}(device, length(channels), SoapySDRDevice_setupStream(device, direction, string(format), map(x->x.idx, channels), length(channels), C_NULL))
end

function _read!(s::Stream{T}, buffers::NTuple{N, Vector{T}}; timeout=nothing) where {N, T}
    timeout === nothing && (timeout = 0.1u"s") # Default from SoapySDR upstream
    buflen = length(first(buffers))
    @assert all(buffer->length(buffer) == buflen, buffers)
    @assert N == s.nchannels
    n, flags, timens = SoapySDRDevice_readStream(s.d, s, Ref(map(pointer, buffers)), buflen, uconvert(u"μs", timeout).val)
    timens = timens * u"ns"
    n, flags, timens
end

function Base.read!(s, buffers; kwargs...)
    _read!(s, buffers; kwargs...)[1]
end

struct SampleBuffer{N, T}
    bufs::NTuple{N, Vector{T}}
    flags::Cint
    timens::typeof(1u"ns")
end
Base.length(sb::SampleBuffer) = length(sb.bufs[1])

function Base.read(s::Stream{T}, n::Int; kwargs...) where {T}
    bufs = ntuple(_->Vector{T}(undef, n), s.nchannels)
    nread, flags, timens = _read!(s, bufs; kwargs...)
    if nread != n
        @info("assertion debugging", nread, n)
        @assert nread == n
    end
    SampleBuffer(bufs, flags, timens)
end

function activate!(s::Stream; flags = 0, timens = nothing, numElems=0)
    SoapySDRDevice_activateStream(s.d, s, flags, timens === nothing ? 0 : uconvert(u"ns", timens).val, numElems)
    nothing
end

function deactivate!(s::Stream; flags = 0, timens = nothing)
    SoapySDRDevice_deactivateStream(s.d, s, flags, timens === nothing ? 0 : uconvert(u"ns", timens).val)
    nothing
end

function Base.write(s::Stream{T}, buffers::NTuple{N, Vector{T}}; timeout = nothing) where {N, T}
    timeout === nothing && (timeout = 0.1u"s") # Default from SoapySDR upstream
    buflen = length(first(buffers))
    @assert all(buffer->length(buffer) == buflen, buffers)
    @assert N == s.nchannels
    SoapySDRDevice_writeStream(s.d, s, Ref(map(pointer, buffers)), buflen, 0, 0, uconvert(u"μs", timeout).val)
end



## sensors

"""
    list_sensors(::Device)

List the available sensors on a device.
Returns: an array of sensor names.
"""
function list_sensors(d::Device)
    StringList(SoapySDRDevice_listSensors(d.ptr)...)
end


"""
    read_sensor(::Device, ::String)

Read the sensor extracted from `list_sensors`. 
Returns: the value as a string.
Note: Appropriate conversions need to be done by the user.
"""
function read_sensor(d::Device, name)
    unsafe_string(SoapySDRDevice_readSensor(d.ptr, name))
end

"""
    get_sensor_info(::Device, ::String)

Read the sensor extracted from `list_sensors`. 
Returns: the value as a string.
Note: Appropriate conversions need to be done by the user.
"""
function get_sensor_info(d::Device, name)
    SoapySDRDevice_getSensorInfo(d.ptr, name)
end



## Time API


"""
    list_time_sources(::Device)

List time sources available on the device
"""
function list_time_sources(d::Device)
    StringList(SoapySDRDevice_listTimeSources(d.ptr)...)
end

"""
    set_time_source!(::Device, source::String)

List the current time source used by the Device.
"""
function set_time_source!(d::Device, s::String)
    SoapySDRDevice_setTimeSource(d.ptr, s)
end

"""
    get_time_source(::Device)

Set the time source used by the Device.
"""
function get_time_source(d::Device)
    unsafe_string(SoapySDRDevice_getTimeSource(d.ptr))
end

"""
    has_hardware_time(::Device, what::String)

Query if the Device has hardware time for the given source.
"""
function has_hardware_time(d::Device, what::String)
    SoapySDRDevice_hasHardwareTime(d.ptr, what)
end

"""
    get_hardware_time(::Device, what::String)

Get hardware time for the given source.
"""
function get_hardware_time(d::Device, what::String)
    SoapySDRDevice_getHardwareTime(d.ptr, what)
end

"""
    has_hardware_time(::Device, timeNs::Int64 what::String)

Set hardware time for the given source.
"""
function set_hardware_time(d::Device, timeNs::Int64, what::String)
    SoapySDRDevice_setHardwareTime(d.ptr, timeNs, what)
end
