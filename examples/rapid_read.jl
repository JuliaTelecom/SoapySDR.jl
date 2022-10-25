using SoapySDR, SoapyRTLSDR_jll

# Here we want to test the behavior in a loop, to ensure
# that we can block on buffer overflow conditions, and
# handle partial reads, measure latnecy, etc

function rapid_read()
    dev = open(Devices()[1])
    rx_chan = dev.rx
    rx_stream = SoapySDR.Stream(rx_chan)
    @show rx_stream.mtu
    SoapySDR.activate!(rx_stream)
    bufs = [Vector{SoapySDR.streamtype(rx_stream)}(undef, 1_000_000) for i = 1:2]

    flip = true
    while true
        # double buffer
        flip = !flip
        current_buff = bufs[Int(flip)+1]
        prev_buff = bufs[Int(!flip)+1]

        read!(rx_stream, (current_buff,))

        # sanity checks?
        #nequal = 0
        #for i in eachindex(current_buff.bufs)
        #    nequal += Int(current_buff.bufs[1][i] == prev_buff.bufs[1][i])
        #end
        #@show current_buff.timens
        #@show nequal, current_buff.timens, delta_t
    end

end
