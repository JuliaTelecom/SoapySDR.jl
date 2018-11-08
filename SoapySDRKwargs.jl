#!/usr/bin/julia

# http://pothosware.github.io/SoapySDR/doxygen/0.1.1/structSoapySDRKwargs.html
mutable struct SoapySDRKwargs
    size::Csize_t
    keys::Ptr{Ptr{Cchar}}
    vals::Ptr{Ptr{Cchar}}
end

mutable struct SoapySDRDevice
    size::Csize_t
    keys::Ptr{Ptr{Cchar}}
    vals::Ptr{Ptr{Cchar}}
end

mutable struct SDRKwargs
    size::Int
    keys::Array{String, 1}
    vals::Array{String, 1}
end

function createSDRKwargs(kwargs::Ptr{SoapySDRKwargs})::SDRKwargs
    t = unsafe_load(kwargs)
    keys =  Array{String, 1}(undef, t.size)
    vals =  Array{String, 1}(undef, t.size)
    for i = 1:t.size
        keys[i] = unsafe_string(unsafe_load(t.keys,i))
        vals[i] = unsafe_string(unsafe_load(t.vals,i))
    end
    return SDRKwargs(Int(t.size),keys,vals)
end

#function createSoapySDRKwargs(kwargs::SDRKwargs)
#
#end

#function Base.display(kwargs::SDRKwargs)
#        # write this
#end

function SoapySDRDevice_enumerate()::Ptr{SoapySDRKwargs}
    t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, ())
    return t2
end

function SoapySDRKwargsList_clear(kwargs::Ptr{SoapySDRKwargs})
    ccall((:SoapySDRKwargsList_clear, "libSoapySDR.so"), Nothing, (Ptr{SoapySDRKwargs}, Csize_t), kwargs, 1)
end

function getSoapySDRDevice()::SDRKwargs
    t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, ())
    t = createSDRKwargs(t2)
    SoapySDRKwargsList_clear(t2)
    return t
end

t2 = ccall((:SoapySDRDevice_enumerate, "libSoapySDR.so"), Ptr{SoapySDRKwargs}, ())
t = createSDRKwargs(t2)

device = ccall((:SoapySDRDevice_make, "libSoapySDR.so"), Ptr{SoapySDRDevice}, (Ptr{SoapySDRKwargs},), t2)

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
##

