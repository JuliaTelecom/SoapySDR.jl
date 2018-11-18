#!/usr/bin/julia

# http://pothosware.github.io/SoapySDR/doxygen/0.1.1/structSoapySDRKwargs.html
struct SoapySDRKwargs
    size::Csize_t
    keys::Ptr{Cstring}
    vals::Ptr{Cstring}
end

SoapySDRKwargs() = SoapySDRKwargs(C_NULL, C_NULL, C_NULL)

struct SDRKwargs
    size::Int
    keys::Array{String, 1}
    vals::Array{String, 1}
end

struct SoapySDRDevice
end

struct SoapySDRStream
end

struct SoapySDRRange
    minimum::Cdouble
    maximum::Cdouble
end

#function createSDRKwargs(kwargs::Ptr{SoapySDRKwargs}, numDevices)::SDRKwargs
function createSDRKwargs(kwargs::Ptr{SoapySDRKwargs}, numDevices::Ref{Csize_t})::SDRKwargs
    s = Int(numDevices[])
    t = unsafe_load(kwargs)
    size = t.size
    keys = unsafe_string.(unsafe_wrap(Array, t.keys, size))
    vals = unsafe_string.(unsafe_wrap(Array, t.vals, size))
    return SDRKwargs(Int(size), keys, vals)
end

function createSDRKwargs(kwargs::SoapySDRKwargs)::SDRKwargs
    size = kwargs.size
    keys = unsafe_string.(unsafe_wrap(Array, kwargs.keys, size))
    vals = unsafe_string.(unsafe_wrap(Array, kwargs.vals, size))
    return SDRKwargs(Int(size), keys, vals)
end

function createSoapySDRKwargs(kwargs::SDRKwargs)::SoapySDRKwargs
    markup = ""
    for i = 1:kwargs.size
        markup = string(markup,t.keys[i],"=",t.vals[i],",")
    end
    ccall((:SoapySDRKwargs_fromString, "libSoapySDR.so"), SoapySDRKwargs, (Ptr{Cchar},), markup)
end

#function Base.display(kwargs::SDRKwargs)
#        # write this
#end

function SoapySDRDevice_enumerate()
    size=Ref{Csize_t}()
    t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, size)
    return (t2, size)
end

function SoapySDRKwargsList_clear(kwargs::Ptr{SoapySDRKwargs})
    ccall((:SoapySDRKwargsList_clear, "libSoapySDR.so"), Nothing, (Ptr{SoapySDRKwargs}, Csize_t), kwargs, 1)
end

function getSoapySDRDevice()::SDRKwargs
    #size=Ref{Csize_t}()
    #t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, size)
    (t2, size) = SoapySDRDevice_enumerate()
    t = createSDRKwargs(t2, size)
    SoapySDRKwargsList_clear(t2)
    return t
end

s = Ref{Csize_t}()
t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, s)
t = createSDRKwargs(t2, s)

sdrk = Ref{SoapySDRKwargs}()
ccall((:SoapySDRKwargs_set, "libSoapySDR.so"), Nothing, (Ref{SoapySDRKwargs}, Cstring, Cstring, ), sdrk, "driver", "rtlsdr")

kw = Ref(unsafe_load(t2))
sdr = ccall((:SoapySDRDevice_make, "libSoapySDR.so"), Ptr{SoapySDRDevice}, (Ref{SoapySDRKwargs},), kw)
sdr2 = unsafe_load(sdr)


SOAPY_SDR_RX = 1
#SoapySDRKwargs *SoapySDRDevice_enumerate(const SoapySDRKwargs *args, size_t *length);
#t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, s)

## query device info
#char **SoapySDRDevice_listAntennas(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
leng = Ref{Csize_t}()
names2 = ccall((:SoapySDRDevice_listAntennas, "libSoapySDR.so"), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), sdr, SOAPY_SDR_RX, 0, leng)
names = unsafe_string(unsafe_load(names2))


names4 = ccall((:SoapySDRDevice_listGains, "libSoapySDR.so"), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), sdr, SOAPY_SDR_RX, 0, leng)
names3 = unsafe_string(unsafe_load(names4))

# SoapySDRRange *ranges = SoapySDRDevice_getFrequencyRange(sdr, SOAPY_SDR_RX, 0, &length);
ranges2 = ccall((:SoapySDRDevice_getFrequencyRange, "libSoapySDR.so"), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), sdr, SOAPY_SDR_RX, 0, leng)
ranges = unsafe_load(ranges2)

rxStream = Ref{SoapySDRStream}()

#SOAPY_SDR_API int SoapySDRDevice_setupStream(SoapySDRDevice *device,
#    SoapySDRStream **stream,
#    const int direction,
#    const char *format,
#    const size_t *channels,
#    const size_t numChans,
#    const SoapySDRKwargs *args);
SOAPY_SDR_CF32 = "CF32"

sdrk = Ref{SoapySDRKwargs}()
# 0 == success here...... :(
success = ccall((:SoapySDRDevice_setupStream, "libSoapySDR.so"), Int, (Ref{SoapySDRDevice},Ref{Ref{SoapySDRStream}}, Cint, Cstring, Ref{Csize_t}, Csize_t, Ref{SoapySDRKwargs}), sdr, rxStream, SOAPY_SDR_RX, SOAPY_SDR_CF32, C_NULL, 0, sdrk)

