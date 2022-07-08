# This script shows how to use the direct buffer access API with the RTLSDR
# and validate acess using its internal testmode

using SoapySDR

using SoapyRTLSDR_jll

SoapySDR.versioninfo()

function dma_test()
    # open the first device
    devs = Devices()
    dev_args = devs[1]

    dev = Device(dev_args)

    # get the RX channel
    chan = dev.rx[1]

    # enable the test pattern so we can validate the type conversions
    SoapySDR.SoapySDRDevice_writeSetting(dev, "testmode", "true")

    native_format = chan.native_stream_format

    # open RX stream
    stream = SDRStream(native_format, [chan])
    for rate in SoapySDR.list_sample_rates(chan)
        println("Testing sample rate:", rate)
        chan.sample_rate = rate
        SoapySDR.activate!(stream)

        # acquire buffers using the low-level API
        buffs = Ptr{native_format}[C_NULL]
        bytes = 0
        total_bytes = 0
        timeout_count = 0
        overflow_count = 0

        buf_ct = stream.num_direct_access_buffers

        println("Receiving data")
        time = @elapsed for i in 1:buf_ct*3 # cycle through all buffers three times
            err, handle, flags, timeNs = SoapySDR.SoapySDRDevice_acquireReadBuffer(dev, stream, buffs, 1000000)

            if err == SOAPY_SDR_TIMEOUT
                timeout_count += 1
            elseif err == SOAPY_SDR_OVERFLOW
                overflow_count += 1
            end

            arr = unsafe_wrap(Array{native_format}, buffs[1], stream.mtu)

            # check the count
            for j in eachindex(arr)
                @assert imag(arr[j]) - real(arr[j]) == 1
            end

            SoapySDR.SoapySDRDevice_releaseReadBuffer(dev, stream, handle)
            total_bytes += stream.mtu*sizeof(native_format)
        end
        println("Data rate: $(Base.format_bytes(total_bytes / time))/s")
        println("Timeout count:", timeout_count)
        println("Overflow count:", overflow_count)

        SoapySDR.deactivate!(stream)

    end
end
dma_test()

