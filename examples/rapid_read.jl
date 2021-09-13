using SoapySDR, SoapyRTLSDR_jll

#using CUDA

# Here we want to test the behavior in a loop, to ensure
# that we can block on buffer overflow conditions, and
# handle partial reads, measure latnecy, etc

function rapid_read()
    dev = Devices()[1]
    rx_chan = dev.rx
    rx_stream = SoapySDR.Stream(rx_chan)
    SoapySDR.activate!(rx_stream)
    bufs = [SoapySDR.SampleBuffer(rx_stream, 10^6) for i = 1:2]
    @show bufs[1], typeof(bufs[1])
    @show bufs[1].packet_count
    @show bufs[2].packet_count
    flip = true
    for i = 1:10
        # double buffer
        flip = !flip
        current_buff = bufs[Int(flip)+1]
        prev_buff = bufs[Int(!flip)+1]
        @assert length(current_buff.bufs[1])%rx_stream.mtu == 0

        read!(rx_stream, current_buff)

        #@show current_buff.bufs[1]

        # sanity checks?
        #nequal = 0
        #for i in eachindex(current_buff.bufs)
        #    nequal += Int(current_buff.bufs[1][i] == prev_buff.bufs[1][i])
        #end
        #@show current_buff.timens
        #@show nequal, current_buff.timens, delta_t
    end

end