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
SoapySDRKwargsList_clear(t2)
#
#
#SOAPY_SDR_RX = 1
##SoapySDRKwargs *SoapySDRDevice_enumerate(const SoapySDRKwargs *args, size_t *length);
##t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, s)
#
### query device info
##char **SoapySDRDevice_listAntennas(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
#leng = Ref{Csize_t}()
#names2 = ccall((:SoapySDRDevice_listAntennas, "libSoapySDR.so"), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), sdr, SOAPY_SDR_RX, 0, leng)
#names = unsafe_string(unsafe_load(names2))
#
#
#names4 = ccall((:SoapySDRDevice_listGains, "libSoapySDR.so"), Ptr{Cstring}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), sdr, SOAPY_SDR_RX, 0, leng)
#names3 = unsafe_string(unsafe_load(names4))
#
## SoapySDRRange *ranges = SoapySDRDevice_getFrequencyRange(sdr, SOAPY_SDR_RX, 0, &length);
#ranges2 = ccall((:SoapySDRDevice_getFrequencyRange, "libSoapySDR.so"), Ptr{SoapySDRRange}, (Ptr{SoapySDRDevice}, Cint, Csize_t, Ref{Csize_t}), sdr, SOAPY_SDR_RX, 0, leng)
#ranges = unsafe_load(ranges2)
#
##    //apply settings
##    if (SoapySDRDevice_setSampleRate(sdr, SOAPY_SDR_RX, 0, 1e6) != 0)
##    {
##        printf("setSampleRate fail: %s\n", SoapySDRDevice_lastError());
##    }
##    if (SoapySDRDevice_setFrequency(sdr, SOAPY_SDR_RX, 0, 912.3e6, NULL) != 0)
##    {
##        printf("setFrequency fail: %s\n", SoapySDRDevice_lastError());
##    }
##
#
## SOAPY_SDR_API int SoapySDRDevice_setSampleRate(SoapySDRDevice *device, const int direction, const size_t channel, const double rate);
#success = ccall((:SoapySDRDevice_setSampleRate, "libSoapySDR.so"), Int, (Ref{SoapySDRDevice}, Cint, Csize_t, Cdouble), sdr, SOAPY_SDR_RX, 0, 1e6)
#
## SOAPY_SDR_API int SoapySDRDevice_setFrequency(SoapySDRDevice *device, const int direction, const size_t channel, const double frequency, const SoapySDRKwargs *args);
#sdrk = Ref{SoapySDRKwargs}()
#success = ccall((:SoapySDRDevice_setFrequency, "libSoapySDR.so"), Int, (Ref{SoapySDRDevice}, Cint, Csize_t, Cdouble, Ref{SoapySDRKwargs}), sdr, SOAPY_SDR_RX, 0, 912.3e6, sdrk)
#
#
#
## setup stream
#rxStream = Ref{SoapySDRStream}()
#
##SOAPY_SDR_API int SoapySDRDevice_setupStream(SoapySDRDevice *device,
##    SoapySDRStream **stream,
##    const int direction,
##    const char *format,
##    const size_t *channels,
##    const size_t numChans,
##    const SoapySDRKwargs *args);
#SOAPY_SDR_CF32 = "CF32"
#
#sdrk = Ref{SoapySDRKwargs}()
## 0 == success here...... :(
##
##SoapySDRDevice_setupStream(sdr, &rxStream, SOAPY_SDR_RX, SOAPY_SDR_CF32, NULL, 0, NULL)
#success = ccall((:SoapySDRDevice_setupStream, "libSoapySDR.so"), Int, (Ref{SoapySDRDevice},Ref{Ref{SoapySDRStream}}, Cint, Cstring, Ref{Csize_t}, Csize_t, Ref{SoapySDRKwargs}), sdr, rxStream, SOAPY_SDR_RX, SOAPY_SDR_CF32, C_NULL, 0, sdrk)
#
## SOAPY_SDR_API int SoapySDRDevice_activateStream(SoapySDRDevice *device,
##    SoapySDRStream *stream,
##    const int flags,
##    const long long timeNs,
##    const size_t numElems);
##SoapySDRDevice_activateStream(sdr, rxStream, 0, 0, 0); //start streaming
##success = ccall((:SoapySDRDevice_activateStream, "libSoapySDR.so"), Int, (Ref{SoapySDRDevice},Ref{SoapySDRStream}, Cint, Clonglong, Csize_t), sdr, rxStream, 0, 0, 0)
#const Device = "libSoapySDR.so"
#success=ccall((:SoapySDRDevice_activateStream, Device), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Cint, Clonglong, Cint), sdr, rxStream, 0, 0, 0)
## reusable buffer...
##ComplexF32
##
#
##SOAPY_SDR_API int SoapySDRDevice_readStream(SoapySDRDevice *device,
##    SoapySDRStream *stream,
##    void * const *buffs,
##    const size_t numElems,
##    int *flags,
##    long long *timeNs,
##    const long timeoutUs);
##int ret = SoapySDRDevice_readStream(sdr, rxStream, buffs, 1024, &flags, &timeNs, 100000);
##
#buff = ComplexF32[]
##buffs = Ref{buff}()
##buffs = Ref{buff}()
#flags = Ref{Ptr{Cint}}()
#timeNs = Clonglong
#buffs = buff
#
##ret = ccall((:SoapySDRDevice_readStream, "libSoapySDR.so"), Int, (Ref{SoapySDRDevice}, Ref{SoapySDRStream}, Ptr{Cvoid}, Csize_t, Ref{Cint}, Ptr{Clonglong}, Clong,), sdr, rxStream, buffs, 1024, flags, timeNs, 100000)
#
#
#ret = ccall((:SoapySDRDevice_readStream, Device), Cint, (Ptr{SoapySDRDevice}, Ptr{SoapySDRStream}, Ptr{Ptr{Cvoid}}, Cint, Ptr{Cint}, Ptr{Clonglong}, Clong), sdr, rxStream, buffs, 1024, flags, timeNs, 100000)
