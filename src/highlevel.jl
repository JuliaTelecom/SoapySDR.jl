# High level API exports

export Devices, Device, dB, gainrange

"""
    Devices()
    Device(args...)

Enumerates all detectable SDR devices on the system.
Indexing into the returned `Devices` object returns a list of
keywords used to create a `Device` struct.

Optionally pass in a list of keywords to filter the returned list.
Example:

```
Devices(driver="rtlsdr")
```
"""
struct Devices
    kwargslist::KWArgsList
    function Devices(args)
        len = Ref{Csize_t}()
        kwargs = SoapySDRDevice_enumerate(isnothing(args) ? C_NULL : args, len)
        kwargs = KWArgsList(kwargs, len[])
        if isempty(kwargs)
            @warn "No devices available! Make sure a supported SDR module is included."
        end
        new(kwargs)
    end
end
Base.length(d::Devices) = length(d.kwargslist)

function Devices(;kwargs...)
    Devices(KWArgs(kwargs))
end

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

Base.getindex(d::Devices, i::Integer) = d.kwargslist[i]
Base.iterate(d::Devices, state=1) = state > length(d) ? nothing : (d[state], state+1)

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
- `sensors`
- `time_source`
- `time_sources`
- `clock_source`
- `clock_sources`
- `frontendmapping_rx`
- `frontendmapping_tx`
"""
mutable struct Device
    ptr::Ptr{SoapySDRDevice}
    function Device(args::KWArgs)
        dev_ptr = SoapySDRDevice_make(args)
        if dev_ptr == C_NULL
            throw(ArgumentError("Unable to open device!"))
        end
        this = new(dev_ptr)
        finalizer(this) do this
            this.ptr != C_NULL && SoapySDRDevice_unmake(this.ptr)
            this.ptr = Ptr{SoapySDRDevice}(C_NULL)
        end
        return this
    end
end

function Device(f::Function, args::KWArgs)
    dev = Device(args)
    try
        f(dev)
    finally
        finalize(dev)
    end
end

Base.cconvert(::Type{<:Ptr{SoapySDRDevice}}, d::Device) = d
Base.unsafe_convert(::Type{<:Ptr{SoapySDRDevice}}, d::Device) = d.ptr
Base.isopen(d::Device) = d.ptr != C_NULL

function Base.show(io::IO, d::Device)
    println(io, "SoapySDR ", d.hardware, " device")
    println(io, "  driver: ", d.driver)
    println(io, "  number of TX channels:", length(d.tx))
    println(io, "  number of RX channels:", length(d.rx))
    println(io, "  sensors: ", d.sensors)
    println(io, "  time_source: ", d.time_source)
    println(io, "  time_sources:", d.time_sources)
    println(io, "  clock_source: ", d.clock_source)
    println(io, "  clock_sources:", d.clock_sources)
    println(io, "  frontendmapping_rx: ", d.frontendmapping_rx)
    println(io, "  frontendmapping_tx: ", d.frontendmapping_tx)
    println(io, "  uarts: ", d.uarts)
    println(io, "  gpios: ", d.gpios)
    println(io, "  registers: ", d.registers)
    print(io, "  master_clock_rate: ");  print_unit(io, d.master_clock_rate)
end

function Base.getproperty(d::Device, s::Symbol)
    if s === :info
        KWArgs(SoapySDRDevice_getHardwareInfo(d))
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
    elseif s === :time_sources
        ComponentList(TimeSource, d)
    elseif s === :uarts
        ComponentList(UART, d)
    elseif s === :registers
        ComponentList(Register, d)
    elseif s === :gpios
        ComponentList(GPIO, d)
    elseif s === :time_source
        TimeSource(Symbol(unsafe_string(SoapySDRDevice_getTimeSource(d.ptr))))
    elseif s === :clock_sources
        ComponentList(ClockSource, d)
    elseif s === :clock_source
        ClockSource(Symbol(unsafe_string(SoapySDRDevice_getClockSource(d.ptr))))
    elseif s === :frontendmapping_tx
        unsafe_string(SoapySDRDevice_getFrontendMapping(d, Tx))
    elseif s === :frontendmapping_rx
        unsafe_string(SoapySDRDevice_getFrontendMapping(d, Rx))
    elseif s === :master_clock_rate
        SoapySDRDevice_getMasterClockRate(d.ptr)*u"Hz"
    else
        getfield(d, s)
    end
end

function Base.setproperty!(c::Device, s::Symbol, v)
    if s === :frontendmapping_tx
        SoapySDRDevice_setFrontendMapping(c.ptr, Tx, v)
    elseif s === :frontendmapping_rx
        SoapySDRDevice_setFrontendMapping(c.ptr, Rx, v)
    elseif s === :time_source
        SoapySDRDevice_setTimeSource(c.ptr, string(v))
    elseif s === :clock_source
        SoapySDRDevice_setClockSource(c.ptr, string(v))
    elseif s === :master_clock_rate
        SoapySDRDevice_setMasterClockRate(c.ptr, v)
    else
        return setfield!(c, s, v)
    end
end


function Base.propertynames(::Device)
    return (:ptr, :info, :driver, :hardware, :tx, :rx, :sensors, :time_source, :timesources, :clock_source, :clock_source, :frontendmapping_rx, :frontendmapping_tx, :uarts, :registers, :gpios, :master_clock_rate)
end

####################################################################################################
#    Channel
####################################################################################################
"""
    Channel

A channel on the given `Device`.

Note!!: A Channel can be created from a `Device` or extracted from a `ChannelList`. It should rarely
be necessary to create a Channel directly.

Has the following properties:
- `device::Device` - `Device` to which the `Channel` belongs
- `direction` - either `Tx` or `Rx`
- `idx` - channel index used by Soapy
- `info` - channel info consiting of `KWArgs`
- `antenna` - antenna name
- `gain_mode` - Automatic Gain control, `true`, `false`, or `missing`
- `gain_elements` - list of `GainElements` of the channel
- `gain` - effective gain, distributed amongst the `GainElements`
- `dc_offset_mode` - Automatic DC offset mode, `true`, `false` or `missing`
- `dc_offset` -  DC offset value
- `iq_balance_mode` -  Automatic IQ balance mode, `true`, `false` or `missing`
- `iq_balance` - IQ balance value
- `frequency_correction` - frequency correction value
- `sample_rate` - sample rate
- `bandwidth` - bandwidth
- `frequency` - center frequency
- `fullduplex` - full duplex mode with other (TX/RX) channels
- `native_stream_format` - native stream format
- `stream_formats` - supported stream formats (converted by Soapy)
- `fullscale` - full scale value
- `sensors` - sensor list


## Reading and writing to Components

gains, antennas, and sensors may consist of a chain or selectable subcomponets.
To set or read e.g. a sensors, one may use the following syntax:

dev = Devices()[1]
cr = dev.rx[1]

# read a sensor value
s1 = cr.sensors[1]
cr[s1]

# read and set the gain element
g1 = cr.gain_elements[1]
cr[g1]
cr[g1] = 4*u"dB"

# read and set the frequency component
f1 = cr.frequency_components[1]
cr[f1]
cr[f1] = 2.498*u"GHz"

"""
struct Channel
    device::Device
    direction::Direction
    idx::Int
end

function Base.show(io::IO, c::Channel)
    println(io, "  antenna: ", c.antenna)
    println(io, "  antennas: ", c.antennas)
    print(io, "  bandwidth [ ")
        join(io, map(x->sprint(print_hz_range, x), bandwidth_ranges(c)), ", ")
        println(io, " ]: ", pick_freq_unit(c.bandwidth))
    print(io, "  frequency [ ")
            join(io, map(x->sprint(print_hz_range, x), frequency_ranges(c)), ", ")
            println(io, " ]: ", pick_freq_unit(c.frequency))
        for element in FrequencyComponentList(c)
            print(io, "    ", element, " [ ")
            join(io, map(x->sprint(print_hz_range, x), frequency_ranges(c, element)), ", ")
            println(io, " ]: ", pick_freq_unit(c[element]))
        end
    println(io, "  gain_mode (AGC=true/false/missing): ", c.gain_mode)
    println(io, "  gain: ", c.gain)
    println(io, "  gain_elements:")
        for element in c.gain_elements
            println(io, "    ", element, " [", gain_range(c, element),"]: ", c[element])
        end
    println(io, "  fullduplex: ", c.fullduplex)
    println(io, "  stream_formats: ", c.stream_formats)
    println(io, "  native_stream_format: ", c.native_stream_format)
    println(io, "  fullscale: ", c.fullscale)
    println(io, "  sensors: ", c.sensors)
    print(io, "  sample_rate [ ", )
        join(io, map(x->sprint(print_hz_range, x), sample_rate_ranges(c)), ", ")
        println(io, " ]: ", pick_freq_unit(c.sample_rate))
    println(io, "  dc_offset_mode (true/false/missing): ", c.dc_offset_mode)
    println(io, "  dc_offset: ", c.dc_offset)
    println(io, "  iq_balance_mode (true/false/missing): ", c.iq_balance_mode)
    println(io, "  iq_balance: ", c.iq_balance)
    fc = c.frequency_correction
    println(io, "  frequency_correction: ", fc, ismissing(fc) ? "" : " ppm")
end

"""
    ChannelList

A grouping of channels on the Device.
Note: This should not be called directly, but rather through the Device.rx and Device.tx properties.
"""
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
        return KWArgs(SoapySDRDevice_getChannelInfo(c.device.ptr, c.direction, c.idx))
    elseif s === :antenna
        ant = SoapySDRDevice_getAntenna(c.device.ptr, c.direction, c.idx)
        return Antenna(Symbol(ant == C_NULL ? "" : unsafe_string(ant)))
    elseif s === :antennas
        return AntennaList(c)
    elseif s === :gain
        return SoapySDRDevice_getGain(c.device.ptr, c.direction, c.idx)*dB
    elseif s === :gain_elements
        return GainElementList(c)
    elseif s === :dc_offset_mode
        if !SoapySDRDevice_hasDCOffsetMode(c.device.ptr, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getDCOffsetMode(c.device.ptr, c.direction, c.idx)
    elseif s === :dc_offset
        if !SoapySDRDevice_hasDCOffset(c.device.ptr, c.direction, c.idx)
            return missing
        end
        i = Ref{Cdouble}(0)
        q = Ref{Cdouble}(0)
        SoapySDRDevice_getDCOffset(c.device.ptr, c.direction, c.idx, i, q)
        return i[], q[]
    elseif s === :iq_balance_mode
        if !SoapySDRDevice_hasIQBalanceMode(c.device.ptr, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getIQBalanceMode(c.device.ptr, c.direction, c.idx)
    elseif s === :iq_balance
        if !SoapySDRDevice_hasIQBalance(c.device.ptr, c.direction, c.idx)
            return missing
        end
        i = Ref{Cdouble}(0)
        q = Ref{Cdouble}(0)
        SoapySDRDevice_getIQBalance(c.device.ptr, c.direction, c.idx, i,q)
        return i[], q[]
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
    elseif s === :sensors
        ComponentList(SensorComponent, c.device, c)
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
        return _stream_map_soapy2jl(fmt == C_NULL ? "" : unsafe_string(fmt))
    elseif s === :fullscale
        _, fullscale = SoapySDRDevice_getNativeStreamFormat(c.device.ptr, c.direction, c.idx)
        return fullscale
    elseif s === :frequency_components
        return FrequencyComponentList(c)
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
            :antennas,
            :gain_elements,
            :gain,
            :dc_offset_mode,
            :dc_offset,
            :iq_balance_mode,
            :iq_balance,
            :gain_mode,
            :frequency_correction,
            :frequency_components,
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
    if s === :antenna
        if v isa Antenna
            SoapySDRDevice_setAntenna(c.device.ptr, c.direction, c.idx, v.name)
        elseif v isa Symbol || v isa String
            SoapySDRDevice_setAntenna(c.device.ptr, c.direction, c.idx, v)
        else
            throw(ArgumentError("antenna must be an Antenna or a Symbol"))
        end
    elseif s === :frequency
        if isa(v, Quantity)
            SoapySDRDevice_setFrequency(c.device.ptr, c.direction, c.idx, uconvert(u"Hz", v).val, C_NULL)
        elseif isa(v, FreqSpec)
            throw(ArgumentError("FreqSpec unsupported"))
        else
            throw(ArgumentError("Frequency must be specified as either a Quantity or a FreqSpec!"))
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
Base.convert(::Type{Cstring}, s::AbstractComponent) =  Cstring(unsafe_convert(Ptr{UInt8}, s.name))

for e in (:TimeSource, :ClockSource, :GainElement, :Antenna, :FrequencyComponent, :SensorComponent, :Setting, :Register, :UART, :GPIO)
    @eval begin
        struct $e <: AbstractComponent;
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
    elseif T <: ClockSource
        ComponentList{ClockSource}(StringList(SoapySDRDevice_listClockSources(d.ptr)...))
    elseif T <: UART
        ComponentList{UART}(StringList(SoapySDRDevice_listUARTs(d.ptr)...))
    elseif T <: GPIO
        ComponentList{GPIO}(StringList(SoapySDRDevice_listGPIOBanks(d.ptr)...))
    elseif T <: Register
        ComponentList{Register}(StringList(SoapySDRDevice_listRegisterInterfaces(d.ptr)...))
    end
end

function ComponentList(::Type{T}, d::Device, c::Channel) where {T <: AbstractComponent}
    len = Ref{Csize_t}()
    if T <: SensorComponent
        s = SoapySDRDevice_listChannelSensors(d.ptr, c.direction, c.idx, len)
        ComponentList{SensorComponent}(StringList(s, len[]))
    end
end

using Base: unsafe_convert
function Base.getindex(c::Channel, ge::GainElement)
    SoapySDRDevice_getGainElement(c.device, c.direction, c.idx, ge.name) * dB
end

function Base.getindex(c::Channel, fe::FrequencyComponent)
    SoapySDRDevice_getFrequencyComponent(c.device, c.direction, c.idx,fe.name) * Hz
end

function Base.getindex(c::Channel, se::SensorComponent)
    unsafe_string(SoapySDRDevice_readChannelSensor(c.device, c.direction, c.idx, se.name))
end

function Base.getindex(d::Device, se::SensorComponent)
    unsafe_string(SoapySDRDevice_readSensor(d.ptr, se.name))
end

function Base.getindex(d::Device, se::Setting)
    unsafe_string(SoapySDRDevice_readSetting(d.ptr, se.name))
end

function Base.getindex(d::Device, se::Tuple{Register, Int})
    SoapySDRDevice_readRegister(d.ptr, se[1].name, se[2])
end

function Base.setindex!(c::Channel, gain, ge::GainElement)
    SoapySDRDevice_setGainElement(c.device, c.direction, c.idx, ge.name, gain.val)
    return gain
end

function Base.setindex!(c::Channel, frequency, ge::FrequencyComponent)
    SoapySDRDevice_setFrequencyComponent(c.device, c.direction, c.idx, ge.name, uconvert(u"Hz", frequency).val, C_NULL)
    return frequency
end

function Base.setindex!(d::Device, v, ge::Setting)
    SoapySDRDevice_writeSetting(d, ge.name, v)
    return v
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
    return _gainrange(SoapySDRDevice_getGainElementRange(c.device, c.direction, c.idx, ge.name))


function _hzrange(soapyr::SoapySDRRange)
    if soapyr.step == 0.0
        # Represents an interval rather than a range
        return (soapyr.minimum*Hz)..(soapyr.maximum*Hz)
    end
    return range(soapyr.minimum*Hz; stop=soapyr.maximum*Hz, step=soapyr.step*Hz)
end

function bandwidth_ranges(c::Channel)
    (ptr, len) = SoapySDRDevice_getBandwidthRange(c.device.ptr, c.direction, c.idx)
    ptr == C_NULL && return SoapySDRRange[]
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len,)))
    SoapySDR_free(ptr)
    arr
end

function frequency_ranges(c::Channel)
    (ptr, len) = SoapySDRDevice_getFrequencyRange(c.device.ptr, c.direction, c.idx)
    ptr == C_NULL && return SoapySDRRange[]
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len,)))
    SoapySDR_free(ptr)
    arr
end

function frequency_ranges(c::Channel, fe::FrequencyComponent)
    (ptr, len) = SoapySDRDevice_getFrequencyRangeComponent(c.device.ptr, c.direction, c.idx, fe.name)
    ptr == C_NULL && return SoapySDRRange[]
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len,)))
    SoapySDR_free(ptr)
    arr
end

function gain_range(c::Channel, ge::GainElement)
    ptr = SoapySDRDevice_getGainElementRange(c.device.ptr, c.direction, c.idx, ge.name)
    ptr
end

function sample_rate_ranges(c::Channel)
    (ptr, len) = SoapySDRDevice_getSampleRateRange(c.device.ptr, c.direction, c.idx)
    ptr == C_NULL && return SoapySDRRange[]
    arr = map(_hzrange, unsafe_wrap(Array, Ptr{SoapySDRRange}(ptr), (len,)))
    SoapySDR_free(ptr)
    arr
end

"""
    list_sample_rates(::Channel)

List the natively supported sample rates for a given channel.
"""
function list_sample_rates(c::Channel)
    len = Ref{Csize_t}(0)
    ptr = SoapySDRDevice_listSampleRates(c.device.ptr, c.direction, c.idx, len)
    arr = unsafe_wrap(Array, Ptr{Float64}(ptr), (len[],)) * Hz
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
    SoapySDR.Stream(channels)
    SoapySDR.Stream(::Type{T}, channels)

Constructs a `Stream{T}` where `T` is the stream type of the device. If unspecified,
the native format will be used.

Fields:
- nchannels - The number of channels in the stream
- mtu - The stream Maximum Transmission Unit
- num_direct_access_buffers - The numer of direct access buffers available in the stream

## Example
```
SoapySDR.Stream(Devices()[1].rx)
```
"""
mutable struct Stream{T}
    d::Device
    nchannels::Int
    ptr::Ptr{SoapySDRStream}
    function Stream{T}(d::Device, nchannels, ptr::Ptr{SoapySDRStream}) where {T}
        this = new{T}(d, Int(nchannels), ptr)
        finalizer(this) do obj
            isopen(d) || return
            SoapySDRDevice_closeStream(d, obj.ptr)
            obj.ptr = Ptr{SoapySDRStream}(C_NULL)
        end
        return this
    end
end

Base.cconvert(::Type{<:Ptr{SoapySDRStream}}, s::Stream) = s
Base.unsafe_convert(::Type{<:Ptr{SoapySDRStream}}, s::Stream) = s.ptr
Base.isopen(s::Stream) = s.ptr != C_NULL && isopen(s.d)

streamtype(::Stream{T}) where T = T

function Base.setproperty!(c::Stream, s::Symbol, v)
    return setfield!(c, s, v)
end

function Base.propertynames(::Stream)
    return (:d, :nchannels, :mtu, :num_direct_access_buffers)
end

function Base.getproperty(stream::Stream, s::Symbol)
    if s === :mtu
        if !isopen(stream)
            throw(InvalidStateException("Stream is closed!", :closed))
        end
        SoapySDRDevice_getStreamMTU(stream.d.ptr, stream.ptr)
    elseif s === :num_direct_access_buffers
        if !isopen(stream)
            throw(InvalidStateException("Stream is closed!", :closed))
        end
        SoapySDRDevice_getNumDirectAccessBuffers(stream.d.ptr, stream.ptr)
    else
        return getfield(stream, s)
    end
end

function Base.show(io::IO, s::Stream)
    print(io, "Stream on ", s.d.hardware)
end

function Stream(format::Type, device::Device, direction::Direction; kwargs...)
    Stream{T}(device, 1, SoapySDRDevice_setupStream(device, direction, string(format), C_NULL, 0, KWArgs(kwargs)))
end

function Stream(format::Type, channels::AbstractVector{T}; kwargs...) where {T <: Channel}
    soapy_format = _stream_map_jl2soapy(format)
    isempty(channels) && error("Must specify at least one channel or use the device/direction constructor for automatic.")
    device = first(channels).device
    direction = first(channels).direction
    if !all(channels) do channel
                channel.device == device && channel.direction == direction
            end
        throw(ArgumentError("Channels must agree on device and direction"))
    end
    Stream{format}(device, length(channels), SoapySDRDevice_setupStream(device, direction, soapy_format, map(x->x.idx, channels), length(channels), KWArgs(kwargs)))
end

function Stream(channels::AbstractVector{T}; kwargs...) where {T <: Channel}
    native_format = promote_type(map(c -> c.native_stream_format, channels)...)
    if native_format <: AbstractComplexInteger
        @warn "$(string(native_format)) may be poorly supported, it is recommend to specify a different type with Stream(format::Type, channels)"
    end
    Stream(native_format, channels; kwargs...)
end

function Stream(format::Type, channel::Channel; kwargs...)
    Stream(format, [channel], kwargs...)
end

function Stream(channel::Channel; kwargs...)
    Stream([channel], kwargs...)
end

function Stream(f::Function, args...; kwargs...)
    stream = Stream(args...; kwargs...)
    try
        f(stream)
    finally
        finalize(stream)
    end
end

const SoapyStreamFlags = Dict(
    "END_BURST" => SOAPY_SDR_END_BURST,
    "HAS_TIME" => SOAPY_SDR_HAS_TIME,
    "END_ABRUPT" => SOAPY_SDR_END_ABRUPT,
    "ONE_PACKET" => SOAPY_SDR_ONE_PACKET,
    "MORE_FRAGMENTS" => SOAPY_SDR_MORE_FRAGMENTS,
    "WAIT_TRIGGER" => SOAPY_SDR_WAIT_TRIGGER,
)

function flags_to_set(flags)
    s = Set{String}()
    for (name, val) in SoapyStreamFlags
        if val & flags != 0
            push!(s, name)
        end
    end
    return s
end

"""
    read!(s::SoapySDR.Stream{T}, buffers::NTuple{N, Vector{T}}; [timeout])

Read data from the device into the given buffers.
"""
function Base.read!(s::Stream{T}, buffers::NTuple{N, AbstractVector{T}}; timeout=nothing) where {N, T}
    t_start = time()
    timeout === nothing && (timeout = 0.1u"s") # Default from SoapySDR upstream
    timeout_s = uconvert(u"s", timeout).val
    timeout_us = uconvert(u"μs", timeout).val

    total_nread = 0
    samples_to_read = length(first(buffers))
    if !all(length(b) == samples_to_read for b in buffers)
        throw(ArgumentError("Buffers must all be same length!"))
    end
    GC.@preserve buffers while total_nread < samples_to_read
        # collect list of pointers to pass to SoapySDR
        buff_ptrs = Ref(map(b -> pointer(b, total_nread+1), buffers))
        nread, flags, timens = SoapySDRDevice_readStream(s.d, s, buff_ptrs, samples_to_read - total_nread, timeout_us)
        total_nread += nread

        if time() > t_start + timeout_s
            # We've timed out, return early and warn.  Something is probably wrong.
            @warn("readStream timeout!",
                timeout=timeout_s,
                total_nread,
                samples_to_read,
                flags=join(flags_to_set(flags), ","),
            )
            return buffers
        end
    end
    return buffers
end

"""
    read(s::SoapySDR.Stream{T}, nb::Integer; [timeout])

Read at most `nb` samples from s
"""
function Base.read(s::Stream{T}, n::Integer; timeout=nothing) where {T}
    bufs = ntuple(_->Vector{T}(undef, n), s.nchannels)
    read!(s, bufs; timeout)
    bufs
end

function activate!(s::Stream; flags = 0, timens = nothing, numElems = nothing)
    if !isopen(s)
        throw(InvalidStateException("stream is closed!", :closed))
    end
    if timens === nothing
        timens = 0
    else
        timens = uconvert(u"ns", timens).val
    end
    if numElems === nothing
        numElems = 0
    end

    SoapySDRDevice_activateStream(s.d, s, flags, timens, numElems)
    return nothing
end

function activate!(f::Function, streams::AbstractVector{<:Stream}; kwargs...)
    activated_streams = SoapySDR.Stream[]
    try
        for s in streams
            activate!(s; kwargs...)
            push!(activated_streams, s)
        end
        f()
    finally
        for s in activated_streams
            deactivate!(s; kwargs...)
        end
    end
end
activate!(f::Function, s::Stream; kwargs...) = activate!(f, [s]; kwargs...)

function deactivate!(s::Stream; flags = 0, timens = nothing)
    SoapySDRDevice_deactivateStream(s.d, s, flags, timens === nothing ? 0 : uconvert(u"ns", timens).val)
    return nothing
end

"""
    write(s::SoapySDR.Stream{T}, buffer::NTuple{N, Vector{T}}; [timeout]) where {N, T}

Write data from the given buffers into the device.  The buffers must all be the same length.
"""
function Base.write(s::Stream{T}, buffers::NTuple{N, AbstractVector{T}}; timeout = nothing) where {N, T}
    t_start = time()
    timeout === nothing && (timeout = 0.1u"s") # Default from SoapySDR upstream
    timeout_s = uconvert(u"s", timeout).val
    timeout_us = uconvert(u"μs", timeout).val

    total_nwritten = 0
    samples_to_write = length(first(buffers))
    if !all(length(b) == samples_to_write for b in buffers)
        throw(ArgumentError("Buffers must all be same length!"))
    end
    if length(buffers) != s.nchannels
        throw(ArgumentError("Must provide buffers for every channel in stream!"))
    end

    GC.@preserve buffers while total_nwritten < samples_to_write
        buff_ptrs = Ref(map(b -> pointer(b, total_nwritten+1), buffers))
        nwritten, flags = SoapySDRDevice_writeStream(s.d, s, buff_ptrs, samples_to_write - total_nwritten, 0, 0, timeout_us)
        total_nwritten += nwritten

        if time() > t_start + timeout_s
            # We've timed out, return early and warn.  Something is probably wrong.
            @warn("writeStream timeout!",
                timeout=timeout_s,
                total_nwritten,
                samples_to_write,
                flags=join(flags_to_set(flags), ","),
            )
            return buffers
        end
    end
    return buffers
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
