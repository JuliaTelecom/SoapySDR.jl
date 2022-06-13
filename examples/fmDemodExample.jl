using Printf
using FFTW
using PyPlot
using DSP
using SoapySDR

# Don't forget to add/import a device-specific plugin package!
# using xtrx_jll
# using SoapyLMS7_jll
# using SoapyRTLSDR_jll
# using SoapyPlutoSDR_jll
# using SoapyUHD_jll

include("fmDemod.jl")

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

@printf "\nnumber of devices = %i\n" Int(sz[])
SoapySDR.SoapySDRKwargs_clear(kwargs)

# create device instance
# args can be user defined or from the enumeration result
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

(ranges, sz) = SoapySDR.SoapySDRDevice_getFrequencyRange(sdr, SoapySDR.SOAPY_SDR_RX, 0)

@printf "Rx freq ranges: "
for i = 1:Int(sz[])
    range =  unsafe_wrap(Array, ranges, Int(sz[]))[i]
    @printf "[%g Hz -> %g Hz], " range.minimum range.maximum
end
@printf "\n"

# apply settings
#sampRate = 1024e3
sampRate = 2048e3
#sampRate = 512e3
if (SoapySDR.SoapySDRDevice_setSampleRate(sdr, SoapySDR.SOAPY_SDR_RX, 0, sampRate) != 0)
    @printf "setSampleRate fail: %s\n" unsafe_string(SoapySDR.SoapySDRDevice_lastError())
end


#f0 = 103.3e6
f0 = 104.1e6
#f0 = 938.2e6
if (SoapySDR.SoapySDRDevice_setFrequency(sdr, SoapySDR.SOAPY_SDR_RX, 0, f0, C_NULL) != 0)
    @printf "setFrequency fail: %s\n" unsafe_string(SoapySDR.SoapySDRDevice_lastError())
end

# set up a stream (complex floats)
rxStream = SoapySDR.SoapySDRStream()
if (SoapySDR.SoapySDRDevice_setupStream(sdr, SoapySDR.SOAPY_SDR_RX, SoapySDR.SOAPY_SDR_CF32, C_NULL, 0, SoapySDR.KWArgs()) != 0)
    @printf "setupStream fail: %s\n" unsafe_string(SoapySDR.SoapySDRDevice_lastError())
end

# start streaming
SoapySDR.SoapySDRDevice_activateStream(sdr, pointer_from_objref(rxStream), 0, 0, 0)

# create a re-usable buffer for rx samples
buffsz = 1024
buff = Array{ComplexF32}(undef, buffsz)

# receive some samples
timeS = 15 
timeSamp = Int(floor(timeS * sampRate / buffsz))
storeIq = zeros(ComplexF32, buffsz*timeSamp)

flags = Ref{Cint}()
timeNs = Ref{Clonglong}()
buffs = [buff] 

#storeFft = zeros(timeSamp, buffsz)
storeBuff = zeros(ComplexF32,timeSamp, buffsz)
for i=1:timeSamp
    nelem, flags, timeNs = SoapySDR.SoapySDRDevice_readStream(sdr, pointer_from_objref(rxStream), Ref(pointer(buff)), buffsz, 100000)
    local storeBuff[i,:] = buff
end

b = blackman(20)
storeFft = zeros(timeSamp, buffsz)
for i = 1:size(storeBuff)[1]
    local storeFft[i,:] = 20 .*log10.(abs.(fftshift(fft(storeBuff[i,:]))))
end

# get IQ array
storeIq = Array(reshape(storeBuff', :, size(storeBuff)[1]*size(storeBuff)[2])')[:]

# shutdown the stream
SoapySDR.SoapySDRDevice_deactivateStream(sdr, pointer_from_objref(rxStream), 0, 0)  # stop streaming
SoapySDR.SoapySDRDevice_closeStream(sdr, pointer_from_objref(rxStream))
SoapySDR.SoapySDRDevice_unmake(sdr)

function plotTimeFreq(storeFft, fs, f0)
    w, h = figaspect(0.5)
    figure(figsize=[w,h])
    minF = (f0 - fs/2 )./ 1e6
    maxF = (f0 + fs/2 )./ 1e6
    maxT = 1/fs * size(storeFft)[1] * size(storeFft)[2]
    imshow(storeFft, extent=[minF,maxF,0,maxT], aspect="auto")
    xlabel("Frequnecy (MHz)")
    ylabel("Time (s)")
    cb = colorbar()
    cb[:set_label]("Magnitude (dB)")
end

function plotTime(data, fs)
    w, h = figaspect(0.25)
    figure(figsize=[w,h])
    maxT = 1/fs * size(data)[1]
    t = range(0, maxT, length=size(data)[1])
    plot(t, data, linewidth=0.1)
    xlim([0, maxT])
    xlabel("Time (s)")
    ylabel("Amplitude")
end

function plotIq(data)
    figure()
    scatter(real.(data), imag.(data), s=10)
    xlabel("In-phase")
    ylabel("Quadrature")
    title("IQ data")
end
plotIq(storeIq[1:10000])
plotTimeFreq(storeFft, sampRate, f0)

(data, fs) =  fmDemod(storeIq, sampRate)
plotTime(data, fs)

wavwrite(data, "demod.wav", Fs=fs)
