function SettingInfo(dev::Device)
    len = Ref{Csize_t}()
    ptr = SoapySDRDevice_getSettingInfo(dev, len)
    ArgInfoList(ptr, len[])
end
