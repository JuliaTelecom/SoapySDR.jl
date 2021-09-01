using SoapySDR

# Don't forget to add/import a device-specific plugin package!
# using xtrx_jll
# using SoapyLMS7_jll
# using SoapyRTLSDR_jll

# Open second channels on first device
c_tx = Devices()[1].tx[2]
c_rx = Devices()[1].rx[2]

# Configure channel with appropriate parameters.  We choose to sneak into
# the very high end of the 2.4 GHz ISM band, above Wifi channel 14 (which
# itself is well outside of the typical US equipment range, which only goes
# up to channel 11, e.g. 2.473 GHz).
c_tx.bandwidth = 2u"MHz"
c_rx.bandwidth = 2u"MHz"
c_tx.frequency = 2.498u"GHz"
c_rx.frequency = 2.498u"GHz"
c_tx.gain = 52u"dB"
c_rx.gain = -2u"dB"
c_tx.sample_rate = 4u"MHz"
c_rx.sample_rate = 4u"MHz"

# Write out a sinusoid oscillating at 100KHz, lasting 10ms
t = (1:round(Int, 0.01*4e6))./4e6
data_tx = ComplexF32.(sin.(2π.*t.*100e3), 0.0f0)
data_tx_zeros = zeros(ComplexF32, length(data_tx))

# Open both RX and TX streams
s_tx = SoapySDR.Stream(ComplexF32, [c_tx])
s_rx = SoapySDR.Stream(ComplexF32, [c_rx])


# Then, do the actual writing and reading!
function loopback_test(s_tx, s_rx, num_buffers)
    SoapySDR.activate!.((s_tx, s_rx))
    data_rx_buffs = SoapySDR.SampleBuffer[]

    # Read/write `num_buffers`, writing zeros out except for one buffer.
    for idx in 1:num_buffers
        if idx == ceil(num_buffers/2)
            Base.write(s_tx, (data_tx,))
        else
            Base.write(s_tx, (data_tx_zeros,))
        end
        push!(data_rx_buffs, Base.read(s_rx, length(data_tx)))
    end
    SoapySDR.deactivate!.((s_tx, s_rx))
    return data_rx_buffs
end

# This should take about 100ms, since we're rx/tx'ing 10x buffers which should each be 10ms long.
loopback_test(s_tx, s_rx, 2)
data_rx_buffs = @time loopback_test(s_tx, s_rx, 10)

# Join all buffers together
data_rx = vcat((buff.bufs[1] for buff in data_rx_buffs)...)

# Should see a nice big spike of a sinusoid being transmitted halfway through
