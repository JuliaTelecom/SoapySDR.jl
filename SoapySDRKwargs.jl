#!/usr/bin/julia

# http://pothosware.github.io/SoapySDR/doxygen/0.1.1/structSoapySDRKwargs.html
struct SoapySDRKwargs
    size::Csize_t
    keys::Ptr{Cstring}
    vals::Ptr{Cstring}
end

struct SDRKwargs
    size::Int
    keys::Array{String, 1}
    vals::Array{String, 1}
end

function createSDRKwargs(kwargs::Ptr{SoapySDRKwargs}, numDevices::Ref{Csize_t})::SDRKwargs
    s = Int(numDevices[])
    t = unsafe_load(kwargs)
    size = t.size
    keys = unsafe_string.(unsafe_wrap(Array, t.keys, size))
    vals = unsafe_string.(unsafe_wrap(Array, t.vals, size))
    return SDRKwargs(Int(size), keys, vals)
end

#function createSoapySDRKwargs(kwargs::SDRKwargs)
#
#end

#function Base.display(kwargs::SDRKwargs)
#        # write this
#end

function SoapySDRDevice_enumerate()
    size=Ref{Csize_t}()
    ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, size)
end

function SoapySDRKwargsList_clear(kwargs::Ptr{SoapySDRKwargs})
    ccall((:SoapySDRKwargsList_clear, "libSoapySDR.so"), Nothing, (Ptr{SoapySDRKwargs}, Csize_t), kwargs, 1)
end

function getSoapySDRDevice()::SDRKwargs
    size=Ref{Csize_t}()
    t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, size)
    t = createSDRKwargs(t2, size)
    SoapySDRKwargsList_clear(t2)
    return t
end


size=Ref{Csize_t}()
t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, (Ptr{Nothing}, Ref{Csize_t}), C_NULL, size)
t = createSDRKwargs(t2, size)

#device = ccall((:SoapySDRDevice_make, "libSoapySDR.so"), Ptr{SoapySDRDevice}, (Ptr{SoapySDRKwargs},), t2)

#names = ccall((:SoapySDRDevice_listAntennas, "libSoapySDR.so"), Ptr{Ptr{Char}}, (Ptr{SoapySDRDevice},Cint, Csize_t, Csize_t), device, 1, 0, 1)
    #char** names = SoapySDRDevice_listAntennas(sdr, SOAPY_SDR_RX, 0, &length);
#SoapySDRKwargsList_clear(t2)

#i = 1
#t3 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, (Ptr{SoapySDRKwargs}, Ptr{Csize_t}, ), SoapySDRKwargs(nothing,nothing,nothing), i)

##t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, ())
##t = createSDRKwargs(t2)
##
##
#t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, ())
##t = getSoapySDRDevice()


#size = 0;
#
#for i=1:1
#    println("Found device #", i, ": ");
#    for j=1:t.size
#        println("    ", unsafe_string(unsafe_load(t.keys,j))," = ", unsafe_string(unsafe_load(t.vals,j)))
#    end
#end
#
### Clear kwargs
### or Ptr{Nothing}...
##
### Create device instance
###args = SoapySDRKwargs(1, "asdas", "Asdas")
##args = SoapySDRKwargs(1, "driver","rtlsdr")
###args = SoapySDRKwargs()
##ccall((:SoapySDRKwargs_set, "libSoapySDR.so"), Ptr{Nothing}, (SoapySDRKwargs, Cstring, Cstring), args, "driver", "rtlsdr")
##=#


#t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, ())
