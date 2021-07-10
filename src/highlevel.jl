# High level API exports

export Devices, dB

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
## 

struct Devices
    kwargslist::KWArgsList
    Devices() = new(KWArgsList(SoapySDRDevice_enumerate()...))
end
Base.length(d::Devices) = length(d.kwargslist)

function Base.show(io::IO, d::Devices)
    if length(d) == 0
        print(io, "< No devices available >")
    end
    for (i, dev) in enumerate(d.kwargslist)
        print(io, "[$i] ")
        join(io, dev, ", ")
        println(io)
    end
end

##

mutable struct Device
    ptr::Ptr{SoapySDRDevice}
    function Device(ptr::Ptr{SoapySDRDevice})
        this = new(ptr)
        finalizer(SoapySDRDevice_unmake, this)
        return this
    end
end
SoapySDRDevice_unmake(d::Device) = SoapySDRDevice_unmake(d.ptr)
Base.unsafe_convert(::Type{Ptr{SoapySDRDevice}}, d::Device) = d.ptr

function Base.getindex(d::Devices, i::Integer)
    Device(SoapySDRDevice_make(ptr(d.kwargslist[i])))
end

function Base.getproperty(d::Device, s::Symbol)
    if s === :info
        OwnedKWArgs(SoapySDRDevice_getHardwareInfo(d))
    elseif s === :driver
        Symbol(unsafe_string(SoapySDRDevice_getDriverKey(d)))
    elseif s === :hardware
        Symbol(unsafe_string(SoapySDRDevice_getHardwareKey(d)))
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

struct ChannelList <: AbstractVector{Channel}
    device::Device
    direction::Direction
end

function Base.size(cl::ChannelList)
    (SoapySDRDevice_getNumChannels(cl.device, cl.direction),)
end

function Base.getindex(cl::ChannelList, i::Integer)
    checkbounds(cl, i)
    Channel(cl.device, cl.direction, i)
end    

function Base.getproperty(c::Channel, s::Symbol)
    if s === :info
        OwnedKWArgs(SoapySDRDevice_getChannelInfo(c.d, c.dir, c.idx))
    elseif s === :antennas || s === :antennae
        # Electrical engineers prefer antennas, but the Latin student in
        # me insists both spellings are available.
        return AntennaList(c)
    elseif s === :gain_elements
        return GainElementList(c)
    else
        return getfield(c, s)
    end
end

## Antenna

struct Antenna
    name::Symbol
end

SoapySDRDevice_listAntennas(channel::Channel) =
    SoapySDRDevice_listAntennas(channel.device, channel.direction, channel.idx)
struct AntennaList <: AbstractVector{Antenna}
    s::StringList
    function AntennaList(channel)
        new(StringList(SoapySDRDevice_listAntennas(channel)...))
    end
end
Base.size(al::AntennaList) = (length(al.s),)
Base.getindex(al::AntennaList, i::Integer) = Antenna(Symbol(al.s[i]))

## GainElement

struct GainElement
    name::Symbol
    range::Union{TODO}
end

SoapySDRDevice_listGains(channel::Channel) =
    SoapySDRDevice_listGains(channel.device, channel.direction, channel.idx)
struct GainElementList <: AbstractVector{Antenna}
    s::StringList
    function GainElementList(channel)
        new(StringList(SoapySDRDevice_listGains(channel)...))
    end
end
Base.size(al::GainElementList) = (length(al.s),)
Base.getindex(al::GainElementList, i::Integer) = GainElement(Symbol(al.s[i]))

function Base.getindex(c::Channel, ge::GainElement)
    SoapySDRDevice_getGainElement(c.device, c.direction, c.idx, CString(unsafe_convert(Ptr{UInt8}, ge.name))) * dB
end

function Base.setindex!(c::Channel, gain::typeof(1.0dB), ge::GainElement)
    SoapySDRDevice_setGainElement(c.device, c.direction, c.idx, CString(unsafe_convert(Ptr{UInt8}, ge.name, gain.val)))
    return gain
end