# This script shows how to use the direct buffer access API with the RTLSDR

using SoapySDR

using SoapyRTLSDR_jll

# open the first device
devs = Devices()
dev_args = devs[1]

dev = open(dev_args)

# get the RX channel
chan = dev.rx[1]

# enable the test pattern so we can validate the type conversions
SoapySDR.SoapySDRDevice_writeSetting(dev, "testmode", "true")

native_format = chan.native_stream_format

# open RX stream
stream = SoapySDR.Stream(native_format, [chan])

function dma_test(stream)
    for rate in SoapySDR.list_sample_rates(chan)
        println("Testing sample rate:", rate)
        chan.sample_rate = rate
        SoapySDR.activate!(stream)

        # acquire buffers using the low-level API
        buffs = Ptr{native_format}[C_NULL]
        bytes = 0
        total_bytes = 0

        println("Receiving data")
        time = @elapsed for i in 1:30
            bytes, handle, flags, timeNs = SoapySDR.SoapySDRDevice_acquireReadBuffer(dev, stream, buffs, 1000000)
            
            arr = unsafe_wrap(Array{native_format}, buffs[1], bytes ÷ sizeof(native_format))

            # check the count
            for j in eachindex(arr)
                @assert imag(arr[j]) - real(arr[j]) == 1
            end

            SoapySDR.SoapySDRDevice_releaseReadBuffer(dev, stream, handle)
            total_bytes += bytes
        end
        println("Data rate: $(Base.format_bytes(total_bytes / time))/s")

        SoapySDR.deactivate!(stream)

    end
end
dma_test(stream)

# close everything
close(stream)
close(dev)
