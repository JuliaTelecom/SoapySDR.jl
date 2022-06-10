"""
    SoapySDRRange

Definition for a min/max numeric range
"""
struct SoapySDRRange
    minimum::Cdouble
    maximum::Cdouble
    step::Cdouble
end

"""
    SoapySDRKwargs

Definition for a key/value string map
"""
struct SoapySDRKwargs
    size::Csize_t
    keys::Ptr{Ptr{Cchar}}
    vals::Ptr{Ptr{Cchar}}
end

"""
    SoapySDRKwargs_fromString(markup)

Convert a markup string to a key-value map.
The markup format is: "key0=value0, key1=value1"
"""
function SoapySDRKwargs_fromString(markup)
    ccall((:SoapySDRKwargs_fromString, soapysdr), SoapySDRKwargs, (Ptr{Cchar},), markup)
end

"""
    SoapySDRKwargs_toString(args)

Convert a key-value map to a markup string.
The markup format is: "key0=value0, key1=value1"
"""
function SoapySDRKwargs_toString(args)
    ccall((:SoapySDRKwargs_toString, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRKwargs},), args)
end

"""
    SoapySDRArgInfoType

Possible data types for argument info
"""
@cenum SoapySDRArgInfoType::UInt32 begin
    SOAPY_SDR_ARG_INFO_BOOL = 0
    SOAPY_SDR_ARG_INFO_INT = 1
    SOAPY_SDR_ARG_INFO_FLOAT = 2
    SOAPY_SDR_ARG_INFO_STRING = 3
end

"""
    SoapySDRArgInfo

Definition for argument info
"""
struct SoapySDRArgInfo
    key::Ptr{Cchar}
    value::Ptr{Cchar}
    name::Ptr{Cchar}
    description::Ptr{Cchar}
    units::Ptr{Cchar}
    type::SoapySDRArgInfoType
    range::SoapySDRRange
    numOptions::Csize_t
    options::Ptr{Ptr{Cchar}}
    optionNames::Ptr{Ptr{Cchar}}
end

"""
    SoapySDR_free(ptr)

Free a pointer allocated by SoapySDR.
For most platforms this is a simple call around free()
"""
function SoapySDR_free(ptr)
    ccall((:SoapySDR_free, soapysdr), Cvoid, (Ptr{Cvoid},), ptr)
end

"""
    SoapySDRStrings_clear(elems, length)

Clear the contents of a list of string
Convenience call to deal with results that return a string list.
"""
function SoapySDRStrings_clear(elems, length)
    ccall((:SoapySDRStrings_clear, soapysdr), Cvoid, (Ptr{Ptr{Ptr{Cchar}}}, Csize_t), elems, length)
end

"""
    SoapySDRKwargs_set(args, key, val)

Set a key/value pair in a kwargs structure.
\\post
If the key exists, the existing entry will be modified;
otherwise a new entry will be appended to args.
On error, the elements of args will not be modified,
and args is guaranteed to be in a good state.
\\return 0 for success, otherwise allocation error
"""
function SoapySDRKwargs_set(args, key, val)
    ccall((:SoapySDRKwargs_set, soapysdr), Cint, (Ptr{SoapySDRKwargs}, Ptr{Cchar}, Ptr{Cchar}), args, key, val)
end

"""
    SoapySDRKwargs_get(args, key)

Get a value given a key in a kwargs structure.
\\return the string or NULL if not found
"""
function SoapySDRKwargs_get(args, key)
    ccall((:SoapySDRKwargs_get, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRKwargs}, Ptr{Cchar}), args, key)
end

"""
    SoapySDRKwargs_clear(args)

Clear the contents of a kwargs structure.
This frees all the underlying memory and clears the members.
"""
function SoapySDRKwargs_clear(args)
    ccall((:SoapySDRKwargs_clear, soapysdr), Cvoid, (Ptr{SoapySDRKwargs},), args)
end

"""
    SoapySDRKwargsList_clear(args, length)

Clear a list of kwargs structures.
This frees all the underlying memory and clears the members.
"""
function SoapySDRKwargsList_clear(args, length)
    ccall((:SoapySDRKwargsList_clear, soapysdr), Cvoid, (Ptr{SoapySDRKwargs}, Csize_t), args, length)
end

"""
    SoapySDRArgInfo_clear(info)

Clear the contents of a argument info structure.
This frees all the underlying memory and clears the members.
"""
function SoapySDRArgInfo_clear(info)
    ccall((:SoapySDRArgInfo_clear, soapysdr), Cvoid, (Ptr{SoapySDRArgInfo},), info)
end

"""
    SoapySDRArgInfoList_clear(info, length)

Clear a list of argument info structures.
This frees all the underlying memory and clears the members.
"""
function SoapySDRArgInfoList_clear(info, length)
    ccall((:SoapySDRArgInfoList_clear, soapysdr), Cvoid, (Ptr{SoapySDRArgInfo}, Csize_t), info, length)
end

const SOAPY_SDR_TRUE = "true"

const SOAPY_SDR_FALSE = "false"

