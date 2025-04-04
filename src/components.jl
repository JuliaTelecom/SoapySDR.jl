# High level API exports

export dB, gainrange

# Components is an internal mechaism to allow for dispatch and interface through the Julia API
# For example there may be several GainElements we list in a Channel. A Julian idiom for this is
# the set/getindex class of functions.

abstract type AbstractComponent end
Base.print(io::IO, c::AbstractComponent) = print(io, c.name)
Base.convert(::Type{T}, s::Symbol) where {T<:AbstractComponent} = T(s)
Base.convert(::Type{T}, s::String) where {T<:AbstractComponent} = T(Symbol(s))
Base.convert(::Type{Cstring}, s::AbstractComponent) =
    Cstring(unsafe_convert(Ptr{UInt8}, s.name))

for e in (
    :TimeSource,
    :ClockSource,
    :GainElement,
    :Antenna,
    :FrequencyComponent,
    :SensorComponent,
    :Setting,
    :Register,
    :UART,
    :GPIO,
)
    @eval begin
        struct $e <: AbstractComponent
            name::Symbol
        end
        function $e(s::AbstractString)
            $e(Symbol(s))
        end
    end
end

struct ComponentList{T<:AbstractComponent} <: AbstractVector{T}
    s::StringList
end
Base.size(l::ComponentList) = (length(l.s),)
Base.getindex(l::ComponentList{T}, i::Integer) where {T} = T(Symbol(l.s[i]))
function Base.show(io::IO, l::ComponentList{T}) where {T}
    print(io, T, "[")
    for c in l
        print(io, c, ",")
    end
    print(io, "]")
end

for (e, f) in zip(
    (:Antenna, :GainElement, :FrequencyComponent, :SensorComponent),
    (
        :SoapySDRDevice_listAntennas,
        :SoapySDRDevice_listGains,
        :SoapySDRDevice_listFrequencies,
        :SoapySDRDevice_listSensors,
    ),
)
    @eval begin
        function $(Symbol(string(e, "List")))(channel::Channel)
            len = Ref{Csize_t}()
            ptr = $f(channel.device, channel.direction, channel.idx, len)
            strlist = StringList(ptr, len[])
            return ComponentList{$e}(strlist)
        end
    end
end

function ComponentList(::Type{T}, d::Device) where {T<:AbstractComponent}
    len = Ref{Csize_t}()
    ptr = if T <: SensorComponent
        SoapySDRDevice_listSensors(d, len)
    elseif T <: TimeSource
        SoapySDRDevice_listTimeSources(d, len)
    elseif T <: ClockSource
        SoapySDRDevice_listClockSources(d, len)
    elseif T <: UART
        SoapySDRDevice_listUARTs(d, len)
    elseif T <: GPIO
        SoapySDRDevice_listGPIOBanks(d, len)
    elseif T <: Register
        SoapySDRDevice_listRegisterInterfaces(d, len)
    else
        error("Unsupported component type: $T")
    end
    strlist = StringList(ptr, len[])
    ComponentList{T}(strlist)
end

function ComponentList(::Type{T}, d::Device, c::Channel) where {T<:AbstractComponent}
    len = Ref{Csize_t}()
    if T <: SensorComponent
        s = SoapySDRDevice_listChannelSensors(d, c.direction, c.idx, len)
        ComponentList{SensorComponent}(StringList(s, len[]))
    end
end

using Base: unsafe_convert
function Base.getindex(c::Channel, ge::GainElement)
    SoapySDRDevice_getGainElement(c.device, c.direction, c.idx, ge.name) * dB
end

function Base.getindex(c::Channel, fe::FrequencyComponent)
    SoapySDRDevice_getFrequencyComponent(c.device, c.direction, c.idx, fe.name) * Hz
end

function Base.getindex(c::Channel, se::SensorComponent)
    unsafe_string(SoapySDRDevice_readChannelSensor(c.device, c.direction, c.idx, se.name))
end

function Base.getindex(c::Channel, se::Setting)
    unsafe_string(SoapySDRDevice_readChannelSetting(c.device, c.direction, c.idx, se.name))
end


function Base.getindex(d::Device, se::SensorComponent)
    unsafe_string(SoapySDRDevice_readSensor(d, se.name))
end

function Base.getindex(d::Device, se::Setting)
    unsafe_string(SoapySDRDevice_readSetting(d, se.name))
end

function Base.getindex(d::Device, se::Tuple{Register,<:Integer})
    SoapySDRDevice_readRegister(d, se[1].name, se[2])
end

function Base.setindex!(c::Channel, gain, ge::GainElement)
    SoapySDRDevice_setGainElement(c.device, c.direction, c.idx, ge.name, gain.val)
    return gain
end

function Base.setindex!(c::Channel, frequency, ge::FrequencyComponent)
    SoapySDRDevice_setFrequencyComponent(
        c.device,
        c.direction,
        c.idx,
        ge.name,
        uconvert(u"Hz", frequency).val,
        C_NULL,
    )
    return frequency
end

function Base.setindex!(d::Device, v::AbstractString, ge::Setting)
    SoapySDRDevice_writeSetting(d, ge.name, v)
    return v
end

function Base.setindex!(c::Channel, v::AbstractString, se::Setting)
    SoapySDRDevice_writeChannelSetting(c.device, c.direction, c.idx, se.name, v)
end

"""
Set a register value on a device:

```
dev[SoapySDR.Register("LMS7002M")] = (0x1234, 0x5678) # tuple of: (addr, value)
dev[(SoapySDR.Register("LMS7002M"), 0x1234)] = 0x5678 # this is also equivalent, and symmetric to the getindex form to read
```
"""
function Base.setindex!(d::Device, val::Tuple{<:Integer,<:Integer}, se::Register)
    SoapySDRDevice_writeRegister(d, se.name, val[1], val[2])
end

function Base.setindex!(d::Device, val::Integer, se::Tuple{Register,<:Integer})
    SoapySDRDevice_writeRegister(d, se[1].name, se[2], val)
end


## GainElement

function _gainrange(soapyr::SoapySDRRange)
    if soapyr.step == 0.0
        # Represents an interval rather than a range
        return (soapyr.minimum * dB) .. (soapyr.maximum * dB)
    end
    # TODO
    @warn "Step ranges are not supported for gain elements. Returning Interval instead. Step: $(soapyr.step*dB)"
    #return range(soapyr.minimum*dB; stop=soapyr.maximum*dB, step=soapyr.step*dB)
    return (soapyr.minimum * dB) .. (soapyr.maximum * dB)
end

function gainrange(c::Channel)
    return _gainrange(SoapySDRDevice_getGainRange(c.device, c.direction, c.idx))
end

gainrange(c::Channel, ge::GainElement) = return _gainrange(
    SoapySDRDevice_getGainElementRange(c.device, c.direction, c.idx, ge.name),
)


function _hzrange(soapyr::SoapySDRRange)
    if soapyr.step == 0.0
        # Represents an interval rather than a range
        return (soapyr.minimum * Hz) .. (soapyr.maximum * Hz)
    end
    return range(soapyr.minimum * Hz; stop = soapyr.maximum * Hz, step = soapyr.step * Hz)
end

function bandwidth_ranges(c::Channel)
    len = Ref{Csize_t}()
    ptr = SoapySDRDevice_getBandwidthRange(c.device, c.direction, c.idx, len)
    ptr == C_NULL && return SoapySDRRange[]
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len[],)))
    SoapySDR_free(ptr)
    arr
end

function frequency_ranges(c::Channel)
    len = Ref{Csize_t}()
    ptr = SoapySDRDevice_getFrequencyRange(c.device, c.direction, c.idx, len)
    ptr == C_NULL && return SoapySDRRange[]
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len[],)))
    SoapySDR_free(ptr)
    arr
end

function frequency_ranges(c::Channel, fe::FrequencyComponent)
    len = Ref{Csize_t}()
    ptr = SoapySDRDevice_getFrequencyRangeComponent(c.device, c.direction, c.idx, fe.name, len)
    ptr == C_NULL && return SoapySDRRange[]
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len[],)))
    SoapySDR_free(ptr)
    arr
end

function gain_range(c::Channel, ge::GainElement)
    ptr = SoapySDRDevice_getGainElementRange(c.device, c.direction, c.idx, ge.name)
    ptr
end

function sample_rate_ranges(c::Channel)
    len = Ref{Csize_t}()
    ptr = SoapySDRDevice_getSampleRateRange(c.device, c.direction, c.idx, len)
    ptr == C_NULL && return SoapySDRRange[]
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len[],)))
    SoapySDR_free(ptr)
    arr
end

"""
    list_sample_rates(::Channel)

List the natively supported sample rates for a given channel.
"""
function list_sample_rates(c::Channel)
    len = Ref{Csize_t}(0)
    ptr = SoapySDRDevice_listSampleRates(c.device, c.direction, c.idx, len)
    arr = unsafe_wrap(Array, Ptr{Float64}(ptr), (len[],)) * Hz
    SoapySDR_free(ptr)
    arr
end

### Frequency Setting
struct FreqSpec{T}
    val::T
    kwargs::Dict{Any,String}
end
