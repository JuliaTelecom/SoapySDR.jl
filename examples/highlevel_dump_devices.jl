using SoapySDR

# Don't forget to add/import a device-specific plugin package!
# using xtrx_jll
# using SoapyLMS7_jll
# using SoapyRTLSDR_jll


for (didx, dev) in enumerate(Devices())
    @info("device", dev, idx=didx)

    dev = open(dev)

    @info("TX channels:")
    for (idx, tx_channel) in enumerate(dev.tx)
        display(tx_channel)
    end
    
    @info("RX channels:")
    for (idx, rx_channel) in enumerate(dev.rx)
        display(rx_channel)
    end

    close(dev)
end
