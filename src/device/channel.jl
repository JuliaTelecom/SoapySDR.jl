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
    join(io, map(x -> sprint(print_hz_range, x), bandwidth_ranges(c)), ", ")
    println(io, " ]: ", pick_freq_unit(c.bandwidth))
    print(io, "  frequency [ ")
    join(io, map(x -> sprint(print_hz_range, x), frequency_ranges(c)), ", ")
    println(io, " ]: ", pick_freq_unit(c.frequency))
    for element in FrequencyComponentList(c)
        print(io, "    ", element, " [ ")
        join(io, map(x -> sprint(print_hz_range, x), frequency_ranges(c, element)), ", ")
        println(io, " ]: ", pick_freq_unit(c[element]))
    end
    println(io, "  gain_mode (AGC=true/false/missing): ", c.gain_mode)
    println(io, "  gain: ", c.gain)
    println(io, "  gain_elements:")
    for element in c.gain_elements
        println(io, "    ", element, " [", gain_range(c, element), "]: ", c[element])
    end
    println(io, "  fullduplex: ", c.fullduplex)
    println(io, "  stream_formats: ", c.stream_formats)
    println(io, "  native_stream_format: ", c.native_stream_format)
    println(io, "  fullscale: ", c.fullscale)
    println(io, "  sensors: ", c.sensors)
    print(io, "  sample_rate [ ")
    join(io, map(x -> sprint(print_hz_range, x), sample_rate_ranges(c)), ", ")
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
    Channel(cl.device, cl.direction, i - 1)
end

function Base.getproperty(c::Channel, s::Symbol)
    if s === :info
        return KWArgs(SoapySDRDevice_getChannelInfo(c.device, c.direction, c.idx))
    elseif s === :antenna
        ant = SoapySDRDevice_getAntenna(c.device, c.direction, c.idx)
        return Antenna(Symbol(ant == C_NULL ? "" : unsafe_string(ant)))
    elseif s === :antennas
        return AntennaList(c)
    elseif s === :gain
        return SoapySDRDevice_getGain(c.device, c.direction, c.idx) * dB
    elseif s === :gain_elements
        return GainElementList(c)
    elseif s === :dc_offset_mode
        if !SoapySDRDevice_hasDCOffsetMode(c.device, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getDCOffsetMode(c.device, c.direction, c.idx)
    elseif s === :dc_offset
        if !SoapySDRDevice_hasDCOffset(c.device, c.direction, c.idx)
            return missing
        end
        i = Ref{Cdouble}(0)
        q = Ref{Cdouble}(0)
        SoapySDRDevice_getDCOffset(c.device, c.direction, c.idx, i, q)
        return i[], q[]
    elseif s === :iq_balance_mode
        if !SoapySDRDevice_hasIQBalanceMode(c.device, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getIQBalanceMode(c.device, c.direction, c.idx)
    elseif s === :iq_balance
        if !SoapySDRDevice_hasIQBalance(c.device, c.direction, c.idx)
            return missing
        end
        i = Ref{Cdouble}(0)
        q = Ref{Cdouble}(0)
        SoapySDRDevice_getIQBalance(c.device, c.direction, c.idx, i, q)
        return Complex(i[], q[])
    elseif s === :gain_mode
        if !SoapySDRDevice_hasGainMode(c.device, c.direction, c.idx)
            return missing
        end
        return SoapySDRDevice_getGainMode(c.device, c.direction, c.idx)
    elseif s === :frequency_correction
        if !SoapySDRDevice_hasFrequencyCorrection(c.device, c.direction, c.idx)
            return missing
        end
        # TODO: ppm unit?
        return SoapySDRDevice_getFrequencyCorrection(c.device, c.direction, c.idx)
    elseif s === :sample_rate
        return SoapySDRDevice_getSampleRate(c.device, c.direction, c.idx) * Hz
    elseif s === :sensors
        ComponentList(SensorComponent, c.device, c)
    elseif s === :bandwidth
        return SoapySDRDevice_getBandwidth(c.device, c.direction, c.idx) * Hz
    elseif s === :frequency
        return SoapySDRDevice_getFrequency(c.device, c.direction, c.idx) * Hz
    elseif s === :fullduplex
        return Bool(SoapySDRDevice_getFullDuplex(c.device, c.direction, c.idx))
    elseif s === :stream_formats
        len = Ref{Csize_t}()
        ptr = SoapySDRDevice_getStreamFormats(c.device, c.direction, c.idx, len)
        slist = StringList(ptr, len[])
        return map(_stream_map_soapy2jl, slist)
    elseif s === :native_stream_format
        fullscale = Ref{Cdouble}()
        fmt = SoapySDRDevice_getNativeStreamFormat(c.device, c.direction, c.idx, fullscale)
        return _stream_map_soapy2jl(fmt == C_NULL ? "" : unsafe_string(fmt))
    elseif s === :fullscale
        fullscale = Ref{Cdouble}()
        fmt = SoapySDRDevice_getNativeStreamFormat(c.device, c.direction, c.idx, fullscale)
        return fullscale[]
    elseif s === :frequency_components
        return FrequencyComponentList(c)
    else
        return getfield(c, s)
    end
end

function Base.propertynames(::SoapySDR.Channel)
    return (
        :device,
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
        :sensors,
    )
end

function Base.setproperty!(c::Channel, s::Symbol, v)
    if s === :antenna
        if v isa Antenna
            SoapySDRDevice_setAntenna(c.device, c.direction, c.idx, v.name)
        elseif v isa Symbol || v isa String
            SoapySDRDevice_setAntenna(c.device, c.direction, c.idx, v)
        else
            throw(ArgumentError("antenna must be an Antenna or a Symbol"))
        end
    elseif s === :frequency
        if isa(v, Quantity)
            SoapySDRDevice_setFrequency(
                c.device,
                c.direction,
                c.idx,
                uconvert(u"Hz", v).val,
                C_NULL,
            )
        elseif isa(v, FreqSpec)
            throw(ArgumentError("FreqSpec unsupported"))
        else
            throw(
                ArgumentError(
                    "Frequency must be specified as either a Quantity or a FreqSpec!",
                ),
            )
        end
    elseif s === :bandwidth
        SoapySDRDevice_setBandwidth(
            c.device,
            c.direction,
            c.idx,
            uconvert(u"Hz", v).val,
        )
    elseif s === :gain_mode
        SoapySDRDevice_setGainMode(c.device, c.direction, c.idx, v)
    elseif s === :gain
        SoapySDRDevice_setGain(c.device, c.direction, c.idx, uconvert(u"dB", v).val)
    elseif s === :sample_rate
        SoapySDRDevice_setSampleRate(
            c.device,
            c.direction,
            c.idx,
            uconvert(u"Hz", v).val,
        )
    elseif s === :dc_offset_mode
        SoapySDRDevice_setDCOffsetMode(c.device, c.direction, c.idx, v)
    elseif s === :iq_balance
        SoapySDRDevice_setIQBalance(c.device, c.direction, c.idx, real(v), imag(v))
    else
        throw(ArgumentError("Channel has no property: $s"))
    end
end
