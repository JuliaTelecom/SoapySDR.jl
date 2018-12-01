include("../src/SoapySDR.jl")
using Printf
using FFTW

# enumerate devices
(kwargs, sz) = SoapySDR.SoapySDRDevice_enumerate()

t = unsafe_load(kwargs)
for i = 1:Int(sz[])
    @printf "\nnumber of results in device = %i\n" t.size
    @printf "Found device #%d: " i
    keys = unsafe_string.(unsafe_wrap(Array, t.keys, t.size))
    vals = unsafe_string.(unsafe_wrap(Array, t.vals, t.size))
    for j = 1:t.size
        @printf "%s=%s, " keys[j] vals[j]
    end
    @printf "\n"
end
#SoapySDR.SoapySDRKwargsList_clear(kwargs, sz)
@printf "\nnumber of devices = %i\n" Int(sz[])
SoapySDR.SoapySDRKwargs_clear(kwargs)

# create device instance
# args can be user defined or from the enumeration result

## does not work
#sdrk = Ref{SoapySDR.SoapySDRKwargs}()
#SoapySDR.SoapySDRKwargs_set(sdrk, "driver", "rtlsdr")

sdr = SoapySDR.SoapySDRDevice_make(kwargs)

if (unsafe_load(sdr) == C_NULL)
    @printf "SoapySDRDevice_make fail: %s\n" unsafe_string(SoapySDR.SoapySDRDevice_lastError())
end

# query device info
(name, sz) = SoapySDR.SoapySDRDevice_listAntennas(sdr, SoapySDR.SOAPY_SDR_RX, 0)
@printf "Rx antennas: "
for i=1:Int(sz[])
    @printf "%s, " unsafe_string.(unsafe_wrap(Array, name, Int(sz[])))[i]
end
@printf "\n"

(name2, sz2) = SoapySDR.SoapySDRDevice_listGains(sdr, SoapySDR.SOAPY_SDR_RX, 0)
@printf "Rx gains: "
for i=1:Int(sz[])
    @printf "%s, " unsafe_string.(unsafe_wrap(Array, name2, Int(sz2[])))[i]
end
@printf "\n"

## cannot do
#SoapySDR.SoapySDRStrings_clear(name, sz[])

(ranges, sz) = SoapySDR.SoapySDRDevice_getFrequencyRange(sdr, SoapySDR.SOAPY_SDR_RX, 0)

@printf "Rx freq ranges: "
for i = 1:Int(sz[])
    range =  unsafe_wrap(Array, ranges, Int(sz[]))[i]
    @printf "[%g Hz -> %g Hz], " range.minimum range.maximum
end
@printf "\n"

# apply settings
if (SoapySDR.SoapySDRDevice_setSampleRate(sdr, SoapySDR.SOAPY_SDR_RX, 0, 1e6) != 0)
    @printf "setSampleRate fail: %s\n" unsafe_string(SoapySDR.SoapySDRDevice_lastError())
end


if (SoapySDR.SoapySDRDevice_setFrequency(sdr, SoapySDR.SOAPY_SDR_RX, 0, 104.1e6) != 0)
    @printf "setFrequency fail: %s\n" unsafe_string(SoapySDR.SoapySDRDevice_lastError())
end

# set up a stream (complex floats)
rxStream = SoapySDR.SoapySDRStream()
if (SoapySDR.SoapySDRDevice_setupStream(sdr, rxStream, SoapySDR.SOAPY_SDR_RX, SoapySDR.SOAPY_SDR_CF32, C_NULL, 0) != 0)
    @printf "setupStream fail: %s\n" unsafe_string(SoapySDR.SoapySDRDevice_lastError())
end


# start streaming
SoapySDR.SoapySDRDevice_activateStream(sdr, rxStream, 0, 0, 0)

# create a re-usable buffer for rx samples
buffsz = 4096
#buff = ComplexF32#[buffsz]
buff = Array{ComplexF32}(undef, buffsz)

##buffs = Ref{ComplexF32}()
#flags = Ref{Cint}()
#timeNs = Ref{Clonglong}()
##buffs = [buff]
##buffs = Ref{ComplexF32}() # THIS SOMEWHAT WORKS
#buffs = [buff] # THIS SOMEWHAT WORKS
#oldbuf = deepcopy(buffs)
#@show buffs
#SoapySDR.SoapySDRDevice_readStream(sdr, rxStream, buffs, buffsz, flags, timeNs, 100000)
#@show buffs
#@show flags
#@show timeNs
## receive some samples
timeSamp = 10000
storeFft = zeros(buffsz, timeSamp)
for i=1:timeSamp
    global buffs = [buff] 
    oldbuf = deepcopy(buffs)
    flags = Ref{Cint}()
    timeNs = Ref{Clonglong}()
    ret = SoapySDR.SoapySDRDevice_readStream(sdr, rxStream, buffs, buffsz, flags, timeNs, 100000)
    #@show ret
    #@show isequal(oldbuf[1], buffs[1])
    #@show bitstring(flags[])
    #@show timeNs
    storeFft[:,i] = 20 .*log10.(abs.(fftshift(fft(buff))))
    
    #@prinf "i = %i, %f +%fi\n"
end


# shutdown the stream
SoapySDR.SoapySDRDevice_deactivateStream(sdr, rxStream, 0, 0)  # stop streaming
SoapySDR.SoapySDRDevice_closeStream(sdr, rxStream)

SoapySDR.SoapySDRDevice_unmake(sdr);
