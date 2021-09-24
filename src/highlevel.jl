# High level API exports

export Devices, dB, gainrange

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

####################################################################################################
#    Device
####################################################################################################

"""
    Device

A device is a collection of SDR channels, obtained from the `Devices()` list.

Fields:
- `info`
- `driver`
- `hardware`
- `tx`
- `rx`
"""
mutable struct Device
    ptr::Ptr{SoapySDRDevice}
    function Device(ptr::Ptr{SoapySDRDevice})
        this = new(ptr)
        finalizer(this) do this
            SoapySDRDevice_unmake(this.ptr)
        end
        return this
    end
end
SoapySDRDevice_unmake(d::Device) = SoapySDRDevice_unmake(d.ptr)
Base.cconvert(::Type{<:Ptr{SoapySDRDevice}}, d::Device) = d
Base.unsafe_convert(::Type{<:Ptr{SoapySDRDevice}}, d::Device) = d.ptr

function Base.show(io::IO, d::Device)
    println(io, "SoapySDR ", d.hardware, " device")
    println(io, "  driver: ", d.driver)
    println(io, "  number of TX channels:", length(d.tx))
    println(io, "  number of RX channels:", length(d.rx))
    println(io, "  sensors: ", d.sensors)
    println(io, "  timesources:", d.timesources)
    println(io, "  frontendmapping_rx: ", d.frontendmapping_rx)
    println(io, "  frontendmapping_tx: ", d.frontendmapping_tx)
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
    elseif s === :tx
        ChannelList(d, Tx)
    elseif s === :rx
        ChannelList(d, Rx)
    elseif s === :sensors
        ComponentList(SensorComponent, d)
    elseif s === :timesources
        ComponentList(TimeSource, d)
    elseif s === :timesource
        TimeSource(Symbol(unsafe_string(SoapySDRDevice_getTimeSource(d.ptr))))
    elseif s === :frontendmapping_tx
        unsafe_string(SoapySDRDevice_getFrontendMapping(d, Tx))
    elseif s === :frontendmapping_rx
        unsafe_string(SoapySDRDevice_getFrontendMapping(d, Rx))
    else
        getfield(d, s)
    end
end

function Base.setproperty!(c::Device, s::Symbol, v)
    if s === :frontendmapping_tx
        SoapySDRDevice_setFrontendMapping(c.ptr, Tx, v)
    elseif s === :frontendmapping_rx
        SoapySDRDevice_setFrontendMapping(c.ptr, Rx, v)
    elseif s === :timesource
        SoapySDRDevice_setTimeSource(c.ptr, v)
    else
        return setfield!(c, s, v)
    end
end


function Base.propertynames(c::Device)
    return (:ptr, :info, :driver, :hardware, :tx, :rx, :sensors, :time)
end

####################################################################################################
#    Channel
####################################################################################################
"""
    Channel

A channel on the given `Device`. Has the following properties:
- `direction`: `Tx` or `Rx`
- `index`: channel index
- `info`: channel info
- `rate`: sample rate
- `gain`: gain range
- `freq`: frequency range
- `bw`: bandwidth range
- `antenna`: antenna list
- `dc`: DC offset correction
- `iq`: IQ imbalance correction
- `sensors`: sensor list

Note: A Channel can be created from a `Device` or extracted from a `ChannelList`. It should rarely
be necessary to create a Channel directly.
"""
struct Channel
    device::Device
    direction::Direction
    idx::Int
end
Base.show(io::IO, c::Channel) =
    print(io, "Channel(", c.device.hardware, ", ", c.direction, ", ", c.idx, ")")

####################################################################################################
#    Unit Printing
####################################################################################################


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

function print_unit_steprange(io::IO, min, max, step)
    print_unit(io, min)
    print(io, ":")
    print_unit(io, step)
    print(io, ":")
    print_unit(io, max)
end

print_unit_interval(io::IO, x::Interval{<:Any, Closed, Closed}) =
    print_unit_interval(io, minimum(x), maximum(x))

using Intervals: Closed
function print_hz_range(io::IO, x::Interval{<:Any, Closed, Closed})
    min, max = pick_freq_unit(minimum(x)), pick_freq_unit(maximum(x))
    print_unit_interval(io, min, max)
end

function print_hz_range(io::IO, x::AbstractRange)
    min, step, max = pick_freq_unit(first(x)), pick_freq_unit(Base.step(x)), pick_freq_unit(last(x))
    print_unit_steprange(io, min, max, step)
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
        println(io, "  gain_mode (AGC=true/false/missing): ", c.gain_mode)
        println(io, "  fullduplex: ", c.fullduplex)
        println(io, "  stream_formats: ", c.stream_formats)
        println(io, "  native_stream_format: ", c.native_stream_format)
        print(io, "  Sample Rate [ ", )
            join(io, map(x->sprint(print_hz_range, x), sample_rate_ranges(c)), ", ")
            println(io, " ]: ", pick_freq_unit(c.sample_rate))
        println(io, "  dc_offset_mode (true/false/missing): ", c.dc_offset_mode)
        println(io, "  dc_offset (if has dc_offset_mode): ", c.dc_offset)
        println(io, "  iq_balance_mode (true/false/missing): ", c.iq_balance_mode)
        println(io, "  iq_balance: ", c.iq_balance)
        println(io, "  frequency_correction: ", c.frequency_correction, " ppm")
    end
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
    elseif s === :fullduplex
        return Bool(SoapySDRDevice_getFullDuplex(c.device.ptr, c.direction, c.idx))
    elseif s === :stream_formats
        slist = StringList(SoapySDRDevice_getStreamFormats(c.device.ptr, c.direction, c.idx)...)
        return map(_stream_map_soapy2jl, slist)
    elseif s === :native_stream_format
        fmt, _ = SoapySDRDevice_getNativeStreamFormat(c.device.ptr, c.direction, c.idx)
        return _stream_map_soapy2jl(unsafe_string(fmt))
    elseif s === :fullscale
        _, fullscale = SoapySDRDevice_getNativeStreamFormat(c.device.ptr, c.direction, c.idx)
        return fullscale
    else
        return getfield(c, s)
    end
end

function Base.propertynames(::SoapySDR.Channel)
    return (:device,
            :direction,
            :idx,
            :info,
            :antenna,
            :gain,
            :dc_offset_mode,
            :dc_offset,
            :iq_balance_mode,
            :iq_balance,
            :gain_mode,
            :frequency_correction,
            :sample_rate,
            :bandwidth,
            :frequency,
            :fullduplex,
            :native_stream_format,
            :stream_formats,
            :fullscale,
            :sensors)
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
    elseif s === :gain_mode
        SoapySDRDevice_setGainMode(c.device.ptr, c.direction, c.idx, v)
    elseif s === :gain
        SoapySDRDevice_setGain(c.device.ptr, c.direction, c.idx, uconvert(u"dB", v).val)
    elseif s === :sample_rate
        SoapySDRDevice_setSampleRate(c.device.ptr, c.direction, c.idx, uconvert(u"Hz", v).val)
    else
        return setfield!(c, s, v)
    end
end

####################################################################################################
#    Components
####################################################################################################

# Components is an internal mechaism to allow for dispatch and interface through the Julia API
# For example there may be several GainElements we list in a Channel. A Julian idiom for this is
# the set/getindex class of functions. 

abstract type AbstractComponent; end
Base.print(io::IO, c::AbstractComponent) = print(io, c.name)
Base.convert(::Type{T}, s::Symbol) where {T <: AbstractComponent} = T(s)
Base.convert(::Type{T}, s::String) where {T <: AbstractComponent} = T(Symbol(s))

for e in (:TimeSource, :GainElement, :Antenna, :FrequencyComponent, :SensorComponent)
    @eval begin
        struct $e <: AbstractComponent;
            name::Symbol
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

for (e, f) in zip((:Antenna, :GainElement, :FrequencyComponent, :SensorComponent),
               (:SoapySDRDevice_listAntennas, :SoapySDRDevice_listGains, :SoapySDRDevice_listFrequencies, :SoapySDRDevice_listSensors))
    @eval begin
        $f(channel::Channel) =
            $f(channel.device, channel.direction, channel.idx)
        $(Symbol(string(e, "List")))(channel::Channel) = ComponentList{$e}(StringList($f(channel)...))
    end
end

function ComponentList(::Type{T}, d::Device) where {T <: AbstractComponent}
    if T <: SensorComponent
        ComponentList{SensorComponent}(StringList(SoapySDRDevice_listSensors(d.ptr)...))
    elseif T <: TimeSource
        ComponentList{TimeSource}(StringList(SoapySDRDevice_listTimeSources(d.ptr)...))
    end
end

using Base: unsafe_convert
function Base.getindex(c::Channel, ge::GainElement)
    SoapySDRDevice_getGainElement(c.device, c.direction, c.idx, Cstring(unsafe_convert(Ptr{UInt8}, ge.name))) * dB
end

function Base.getindex(c::Channel, fe::FrequencyComponent)
    SoapySDRDevice_getFrequencyComponent(c.device, c.direction, c.idx, Cstring(unsafe_convert(Ptr{UInt8}, fe.name))) * Hz
end

function Base.getindex(c::Channel, se::SensorComponent)
    unsafe_string(SoapySDRDevice_readChannelSensor(c.device, c.direction, c.idx, Cstring(unsafe_convert(Ptr{UInt8}, se.name))))
end

function Base.getindex(d::Device, se::SensorComponent)
    unsafe_string(SoapySDRDevice_readSensor(d.ptr, Cstring(unsafe_convert(Ptr{UInt8}, se.name))))
end


## GainElement

function _gainrange(soapyr::SoapySDRRange)
    if soapyr.step == 0.0
        # Represents an interval rather than a range
        return (soapyr.minimum*dB)..(soapyr.maximum*dB)
    end
    # TODO
    @warn "Step ranges are not supported for gain elements. Returning Interval instead. Step: $(soapyr.step*dB)"
    #return range(soapyr.minimum*dB; stop=soapyr.maximum*dB, step=soapyr.step*dB)
    return (soapyr.minimum*dB)..(soapyr.maximum*dB)
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

####################################################################################################
#    Stream
####################################################################################################

"""
    Stream{T}

"""
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

streamtype(::Stream{T}) where T = T

function Base.setproperty!(c::Stream, s::Symbol, v)
    if s === :mtu
        c.mtu
    else
        return setfield!(c, s, v)
    end
end

function Base.getproperty(c::Stream, s::Symbol)
    if s === :mtu
        SoapySDRDevice_getStreamMTU(c.device.ptr, c.ptr)
    else
        return getfield(c, s)
    end
end

function Base.show(io::IO, s::Stream)
    print(io, "Stream on ", s.d.hardware)
end

function Stream(format::Type, device::Device, direction::Direction; kwargs...)
    isempty(kwargs) || error("TODO")
    Stream{T}(device, 1, SoapySDRDevice_setupStream(device, direction, string(format), C_NULL, 0, C_NULL))
end

function Stream(format::Type, channels::AbstractVector{T}; kwargs...) where {T <: Channel}
    soapy_format = _stream_map_jl2soapy(format)
    isempty(kwargs) || error("TODO")
    isempty(channels) && error("Must specify at least one channel or use the device/direction constructor for automatic.")
    device = first(channels).device
    direction = first(channels).direction
    if !all(channels) do channel
                channel.device == device && channel.direction == direction
            end
        throw(ArgumentError("Channels must agree on device and direction"))
    end
    Stream{format}(device, length(channels), SoapySDRDevice_setupStream(device, direction, soapy_format, map(x->x.idx, channels), length(channels), C_NULL))
end

function Stream(channels::AbstractVector{T}; kwargs...) where {T <: Channel}
    native_format = promote_type(map(c -> c.native_stream_format, channels)...)
    if native_format <: AbstractComplexInteger
        @warn "$(string(native_format)) may be poorly supported, it is recommend to specify a different type with Stream(format::Type, channels)"
    end
    Stream(native_format, channels; kwargs...)
end

"""
    SampleBuffer(s::SoapySDR.Stream)
    SampleBuffer(s::SoapySDR.Stream, n::Int)

Constructs a sample buffer for a given stream. Can contain multiple channels and be of arbitrary length.
To avoid undefined behavior, this requested length with be aligned to the device MTU. It is therefore
important to ensure that subsequent calls and calculations use this length.

Returns a `SampleBuffer{N,T}` with fields:
    bufs::NTuple{N, T}
    packet_count::Int
    timens::Vector{Pair{Int,typeof(1u"ns")}}

where N is the number of channels and T is the vector type of the buffer (default: Vector).

`bufs` are the buffers for each channel.
`length` length of the buffer.
`packet_count` are the number of transactions of MTU size required by subsequent `read` and `write` operations.
`timens` are the offset and time stamp pairs for each packet.
"""
struct SampleBuffer{N, T}
    bufs::NTuple{N, T}
    length::Int
    packet_count::Int
    timens::Vector{Pair{Int, typeof(1u"ns")}}
end
Base.length(sb::SampleBuffer) = length(first(sb.bufs))
Base.getindex(sb::SampleBuffer, i::Int) = sb.bufs[i]
Base.setindex(sb::SampleBuffer, i::Int, v) = (sb.bufs[i] = v)
Base.eachindex(::SampleBuffer{N,T}) where {N, T} = 1:N
SampleBuffer(s::Stream) = SampleBuffer(s, s.mtu)

function SampleBuffer(s::Stream{T}, length; round::RoundingMode{RM}=RoundDown, vectortype=Vector) where {T, RM}

    # align to MTU
    overrun = length%s.mtu
    realigned = false
    if length < s.mtu
        length = s.mtu
        realigned = true
    elseif length > s.mtu && overrun != 0
        length = if RM == :Down
                      length - overrun
                  elseif RM == :Up
                      length + s.mtu - overrun
                  end
        realigned = true
    end
    if realigned
        @info "requested 'length' is not aligned to MTU! Aligning to length of $(length) samples"
        @info "get MTU with stream.mtu"
    end

    packet_count = Int(length/s.mtu)
    bufs = ntuple(_->vectortype{T}(undef, length), s.nchannels)
    SampleBuffer(bufs, length, packet_count, Vector{Pair{Int, typeof(1u"ns")}}(undef, packet_count))
end


"""
    read!(s::SoapySDR.Stream, buf::SampleBuffer; timeout::Int)

Read data from the device into the given buffer.
"""
function Base.read!(s::Stream{T}, samplebuffer::SampleBuffer{N, VT}; timeout=nothing, activate=true, deactivate=true) where {N, T, VT <: AbstractVector{T}}
    timeout === nothing && (timeout = 0.1u"s") # Default from SoapySDR upstream

    # check length did not change
    for i in eachindex(samplebuffer.bufs)
        @assert length(samplebuffer.bufs[i]) == samplebuffer.length
    end

    activate && activate!(s)
    for packet in 1:samplebuffer.packet_count
        offset = (packet-1)*s.mtu
        @show offset
        nread, flags, timens = SoapySDRDevice_readStream(s.d, s, Ref(map(b -> pointer(b, offset), samplebuffer.bufs)), s.mtu, uconvert(u"μs", timeout).val)
        timens = timens * u"ns"

        @assert flags & SOAPY_SDR_MORE_FRAGMENTS == 0

        if nread != s.mtu
            @info("assertion debugging", nread, n)
            @assert nread == n
        end

        samplebuffer.timens[packet] = (offset => timens)
    end
    deactivate && deactivate!(s)

    samplebuffer
end

function activate!(s::Stream; flags = 0, timens = nothing, numElems=0)
    SoapySDRDevice_activateStream(s.d, s, flags, timens === nothing ? 0 : uconvert(u"ns", timens).val, numElems)
    nothing
end

function deactivate!(s::Stream; flags = 0, timens = nothing)
    SoapySDRDevice_deactivateStream(s.d, s, flags, timens === nothing ? 0 : uconvert(u"ns", timens).val)
    nothing
end

function Base.write(s::Stream{T}, samplebuffer::SampleBuffer{N, VT}; timeout = nothing, activate=true, deactivate=true) where {N, T, VT <: AbstractVector{T}}
    timeout === nothing && (timeout = 0.1u"s") # Default from SoapySDR upstream

    # check length did not change
    for i in eachindex(samplebuffer.bufs)
        @assert length(samplebuffer.bufs[i]) == samplebuffer.length
    end

    activate && activate!(s)
    for packet in 1:samplebuffer.packet_count
        offset = (packet-1)*s.mtu
        
        nelem, flags = SoapySDRDevice_writeStream(s.d, s, Ref(map(b -> pointer(b, offset), samplebuffer.bufs)), s.mtu, 0, 0, uconvert(u"μs", timeout).val)

        if nelem != s.mtu
            @info("assertion debugging", nelem, n)
            @assert nelem == n
        end

    end
    deactivate && deactivate!(s)

    samplebuffer
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
    set_hardware_time(::Device, timeNs::Int64 what::String)

Set hardware time for the given source.
"""
function set_hardware_time(d::Device, timeNs::Int64, what::String)
    SoapySDRDevice_setHardwareTime(d.ptr, timeNs, what)
end
