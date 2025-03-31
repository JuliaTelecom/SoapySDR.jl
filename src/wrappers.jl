

function SoapySDRDevice_listSensors(device)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_listSensors(device, len)
    (args, len[])
end

function SoapySDRDevice_getSettingInfo(device)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_getSettingInfo(device, len)
    (args, len[])
end

function SoapySDRDevice_listTimeSources(device)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_listTimeSources(device, len)
    (args, len[])
end

function SoapySDRDevice_listClockSources(device)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_listClockSources(device, len)
    (args, len[])
end

function SoapySDRDevice_listRegisterInterfaces(device)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_listRegisterInterfaces(device, len)
    (args, len[])
end

function SoapySDRDevice_listGPIOBanks(device)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_listGPIOBanks(device, len)
    (args, len[])
end

function SoapySDRDevice_listUARTs(device)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_listUARTs(device, len)
    (args, len[])
end

function SoapySDRDevice_listAntennas(device, direction, channel)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_listAntennas(device, direction, channel, len)
    (args, len[])
end

function SoapySDRDevice_getBandwidthRange(device, direction, channel)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_getBandwidthRange(device, direction, channel, len)
    (args, len[])
end

function SoapySDRDevice_getFrequencyRange(device, direction, channel)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_getFrequencyRange(device, direction, channel, len)
    (args, len[])
end

function SoapySDRDevice_listFrequencies(device, direction, channel)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_listFrequencies(device, direction, channel, len)
    (args, len[])
end

function SoapySDRDevice_getFrequencyRangeComponent(device, direction, channel, name)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_getFrequencyRangeComponent(device, direction, channel, name, len)
    (args, len[])
end

function SoapySDRDevice_listGains(device, direction, channel)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_listGains(device, direction, channel, len)
    (args, len[])
end

function SoapySDRDevice_getStreamFormats(device, direction, channel)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_getStreamFormats(device, direction, channel, len)
    (args, len[])
end

function SoapySDRDevice_getNativeStreamFormat(device, direction, channel)
    fullscale = Ref{Cdouble}()
    str = SoapySDRDevice_getNativeStreamFormat(device, direction, channel, fullscale)
    (str, fullscale[])
end

function SoapySDRDevice_getSampleRateRange(device, direction, channel)
    len = Ref{Csize_t}()
    args = SoapySDRDevice_getSampleRateRange(device, direction, channel, len)
    (args, len[])
end

function SoapySDRDevice_acquireReadBuffer(device::Device, stream, buffs, timeoutUs = 100000)
    handle = Ref{Csize_t}()
    flags = Ref{Cint}(0)
    timeNs = Ref{Clonglong}(-1)
    if !isopen(stream)
        throw(InvalidStateException("stream is closed!", :closed))
    end
    bytes = SoapySDRDevice_acquireReadBuffer(
        device,
        stream,
        handle,
        buffs,
        flags,
        timeNs,
        timeoutUs,
    )
    bytes, handle[], flags[], timeNs[]
end

function SoapySDRDevice_acquireWriteBuffer(
    device::Device,
    stream,
    buffs,
    timeoutUs = 100000,
)
    handle = Ref{Csize_t}()
    if !isopen(stream)
        throw(InvalidStateException("stream is closed!", :closed))
    end
    bytes = SoapySDRDevice_acquireWriteBuffer(device, stream, handle, buffs, timeoutUs)
    return bytes, handle[]
end

function SoapySDRDevice_releaseWriteBuffer(
    device::Device,
    stream,
    handle,
    numElems,
    flags = Ref{Cint}(0),
    timeNs = 0,
)
    SoapySDRDevice_releaseWriteBuffer(
        device,
        stream,
        handle,
        numElems,
        flags,
        timeNs,
    )
    flags[]
end

function SoapySDRDevice_readStream(device::Device, stream, buffs, numElems, timeoutUs)
    if !isopen(stream)
        throw(InvalidStateException("stream is closed!", :closed))
    end
    flags = Ref{Cint}()
    timeNs = Ref{Clonglong}()
    nelems = SoapySDRDevice_readStream(
        device,
        stream,
        buffs,
        numElems,
        flags,
        timeNs,
        timeoutUs,
    )
    nelems, flags[], timeNs[]
end

function SoapySDRDevice_writeStream(
    device::Device,
    stream,
    buffs,
    numElems,
    flags,
    timeNs,
    timeoutUs,
)
    if !isopen(stream)
        throw(InvalidStateException("stream is closed!", :closed))
    end
    flags = Ref{Cint}(flags)
    nelems = SoapySDRDevice_writeStream(
        device,
        stream,
        buffs,
        numElems,
        flags,
        timeNs,
        timeoutUs,
    )
    nelems, flags[]
end
