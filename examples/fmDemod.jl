using FFTW
using PyPlot
using DSP
using WAV

function downsample(data, M)
       order = 35 # filter order
       d = 0.01 # transition band
       coeffs = remez(order, [0, 1/(M*2) - d, 1/(M*2)+d, 0.5], [1, 0])
       return (decimate(filt(coeffs, [1], data), M), coeffs, [1])
end

function decimate(data, M)
       return data[1:M:end]
end

function discriminator(data, M)
       # Limiter
       data = data ./ abs.(data)

       # differentiator
       (data2, b2, a2) = differentiator(data, M)

       # complex conj delay
       (ds, b, a) = delay((conj.(data2)), (M-1)/2.0, 80)
       data_mod = ds.* data2
       return (imag.(data_mod), b, a, b2, a2)
end

function differentiator(data, M)
       b = remez(M, [0, 0.5], [1.0], filter_type=RemezFilterType(2))
       return (filt(b, [1], data), b, [1])
end

function delay(data, D, o)
       a = 0.1
       b = [sin.(a*(n - D))/(a*(n - D) ) + 0im for n = 0:o-1]
       c = filt(b, a, data)
       return (c, b, [1])
end

function deemphasis(data, t, f)
       T = 1/f
       al = 1/tan(T/(2*t))
       b = [1, 1]
       a = [1+al, 1-al]
       return (filt(b, a, data), b, a)
end

function lowPassFilter(data, f, pb, sb)
       fp = pb/f
       ft = sb/f
       order = 35
       coeffs = remez(order, [0, fp, ft, 0.5], [1, 0])
       return (filt(coeffs, [1], data), coeffs, [1])
end

function plotTimeFreq(storeFft, fs, f0)
    w, h = figaspect(0.33)
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
    w, h = figaspect(0.33)
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

function fmDemod(data, fs)
    # downsample
    fs2 = 256e3
    M = Int(fs/fs2)
    (data3, b3, a3) = downsample(data, M);
    
    (data4, b4, a4, b42, a42) = discriminator(data3, 10);
    
    t = 75e-6
    (data5, b5, a5) = deemphasis(data4, t, fs2);
    
    (data6, b6, a6) = lowPassFilter(data5, fs2, 15e3, 18e3)
    
    
    fs3 = 64e3
    M = Int(fs2 / fs3)
    (data7, b7, a7) = downsample(data6, M)
    
    maxval = abs(data7[argmax(abs.(data7))])
    data8 = data7./maxval
    return (data8, fs3)
    return (data7, fs3)
end
