

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