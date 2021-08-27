# Misc data type definitions used in the API.

# Definition for a min/max numeric range
struct SoapySDRRange
    minimum::Cdouble
    maximum::Cdouble
    step::Cdouble
end

#Definition for a key/value string map
struct SoapySDRKwargs
    size::Csize_t
    keys::Ptr{Cstring}
    vals::Ptr{Cstring}
end

"""
Convert a markup string to a key-value map.
The markup format is: "key0=value0, key1=value1"
"""
function SoapySDRKwargs_fromString(markup)
    ccall((:SoapySDRKwargs_fromString, lib), SoapySDRKwargs, (Cstring,), markup)
end

"""
Convert a key-value map to a markup string.
The markup format is: "key0=value0, key1=value1"
"""
function SoapySDRKwargs_toString(args)
    ccall((:SoapySDRKwargs_toString, lib), Cstring, (Ptr{SoapySDRKwargs},), args)
end

# Possible data types for argument info
@enum SoapySDRArgInfoType begin
    SOAPY_SDR_ARG_INFO_BOOL
    SOAPY_SDR_ARG_INFO_INT
    SOAPY_SDR_ARG_INFO_FLOAT
    SOAPY_SDR_ARG_INFO_STRING
end

# Definition for argument info
struct SoapySDRArgInfo
    # The key used to identify the argument (required)
    key::Cstring    # key::Ptr{Cchar}

    # The default value of the argument when not specified (required)
    # Numbers should use standard floating point and integer formats.
    # Boolean values should be represented as "true" and  "false".
    value::Cstring

    # The displayable name of the argument (optional, use key if empty)
    name::Cstring

    # A brief description about the argument (optional)
    description::Cstring

    # The units of the argument: dB, Hz, etc (optional)
    units::Cstring

    # The data type of the argument (required)
    type::SoapySDRArgInfoType

    # The range of possible numeric values (optional)
    # When specified, the argument should be restricted to this range.
    # The range is only applicable to numeric argument types.
    range::SoapySDRRange

    # The size of the options set, or 0 when not used.
    numOptions::Csize_t

    # A discrete list of possible values (optional)
    # When specified, the argument should be restricted to this options set.
    options::Ptr{Cstring}

    # A discrete list of displayable names for the enumerated options (optional)
    # When not specified, the option value itself can be used as a display name.
    optionNames::Ptr{Cstring}
end

# Clear the contents of a list of string
# Convenience call to deal with results that return a string list.
function SoapySDRStrings_clear(elems, length)
    ccall((:SoapySDRStrings_clear, lib), Cvoid, (Ptr{Ptr{Cstring}}, Cint), elems, length)
end

"""
Set a key/value pair in a kwargs structure.
If the key exists, the existing entry will be modified;
otherwise a new entry will be appended to args.
On error, the elements of args will not be modified,
and args is guaranteed to be in a good state.
return 0 for success, otherwise allocation error
"""
function SoapySDRKwargs_set(args, key, val) # THIS IS BROKEN
    ccall((:SoapySDRKwargs_set, lib), Cint, (Ptr{SoapySDRKwargs}, Cstring, Cstring), args, key, val)
end

"""
Get a value given a key in a kwargs structure.
return the string or NULL if not found
"""
function SoapySDRKwargs_get(args, key)
    ccall((:SoapySDRKwargs_get, lib), Cstring, (Ptr{SoapySDRKwargs}, Cstring), args, key)
end

"""
Clear the contents of a kwargs structure.
This frees all the underlying memory and clears the members.
"""
function SoapySDRKwargs_clear(args)
    ccall((:SoapySDRKwargs_clear, lib), Cvoid, (Ptr{SoapySDRKwargs},), args)
end

"""Clear a list of kwargs structures.
This frees all the underlying memory and clears the members."""
function SoapySDRKwargsList_clear(args, length::Integer)
    ccall((:SoapySDRKwargsList_clear, lib), Cvoid, (Ptr{SoapySDRKwargs}, Csize_t), args, length)
end

"""Clear the contents of a argument info structure.
This frees all the underlying memory and clears the members."""
function SoapySDRArgInfo_clear(info)
    ccall((:SoapySDRArgInfo_clear, lib), Cvoid, (Ptr{SoapySDRArgInfo},), info)
end

"""
Clear a list of argument info structures.
This frees all the underlying memory and clears the members."""
function SoapySDRArgInfoList_clear(info, length::Cint)
    ccall((:SoapySDRArgInfoList_clear, lib), Cvoid, (Ptr{SoapySDRArgInfo}, Cint), info, length)
end

function SoapySDR_free(ptr::Ptr)
    ccall((:SoapySDR_free, lib), Cvoid, (Ptr{Cvoid},), ptr)
end