using Printf
using FFTW
using PyPlot
using DSP
using SoapySDR
using Unitful

# Don't forget to add/import a device-specific plugin package!
# using xtrx_jll
# using SoapyLMS7_jll
# using SoapyRTLSDR_jll
# using SoapyPlutoSDR_jll
# using SoapyUHD_jll

include("fmDemod.jl")

include("highlevel_dump_devices.jl")

devs = Devices()

sdr = SoapySDR.Device(devs[1])

rx1 = sdr.rx[1]

# setup AGC if available
#rx1.gain_mode = true

sampRate = 2.048e6

rx1.sample_rate = sampRate*u"Hz"

f0 = 104.1e6

rx1.frequency = f0*u"Hz"

# set up a stream (complex floats)
rxStream = SoapySDR.Stream(ComplexF32, [rx1])

# start streaming

# create a re-usable buffer for rx samples
buffsz = 1024
buff = Array{ComplexF32}(undef, buffsz)

# receive some samples
timeS = 15 
timeSamp = Int(floor(timeS * sampRate / buffsz))
storeIq = zeros(ComplexF32, buffsz*timeSamp)


#storeFft = zeros(timeSamp, buffsz)
storeBuff = zeros(ComplexF32,timeSamp, buffsz)

# Enable ther stream
SoapySDR.activate!(rxStream)

for i=1:timeSamp
    read!(rxStream, (buff, ))
    storeBuff[i,:] = buff
end

b = blackman(20)
storeFft = zeros(timeSamp, buffsz)
for i = 1:size(storeBuff)[1]
    local storeFft[i,:] = 20 .*log10.(abs.(fftshift(fft(storeBuff[i,:]))))
end

# get IQ array
storeIq = Array(reshape(storeBuff', :, size(storeBuff)[1]*size(storeBuff)[2])')[:]

function plotTimeFreq(storeFft, fs, f0)
    w, h = figaspect(0.5)
    figure(figsize=[w,h])
    minF = (f0 - fs/2 )./ 1e6
    maxF = (f0 + fs/2 )./ 1e6
    maxT = 1/fs * size(storeFft)[1] * size(storeFft)[2]
    imshow(storeFft, extent=[minF,maxF,0,maxT], aspect="auto")
    xlabel("Frequency (MHz)")
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
