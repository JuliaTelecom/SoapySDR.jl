export Devices, Device

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

function Devices(; kwargs...)
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
Base.iterate(d::Devices, state = 1) = state > length(d) ? nothing : (d[state], state + 1)

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
    print(io, "  master_clock_rate: ")
    print_unit(io, d.master_clock_rate)
end

function Base.getproperty(d::Device, s::Symbol)
    if s === :info
        KWArgs(SoapySDRDevice_getHardwareInfo(d))
    elseif s === :driver
        Symbol(unsafe_string(SoapySDRDevice_getDriverKey(d)))
    elseif s === :hardware
        isopen(d) || throw(InvalidStateException("Device is closed!", :closed))
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
        SoapySDRDevice_getMasterClockRate(d.ptr) * u"Hz"
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
    return (
        :ptr,
        :info,
        :driver,
        :hardware,
        :tx,
        :rx,
        :sensors,
        :time_source,
        :timesources,
        :clock_source,
        :clock_source,
        :frontendmapping_rx,
        :frontendmapping_tx,
        :uarts,
        :registers,
        :gpios,
        :master_clock_rate,
    )
end
