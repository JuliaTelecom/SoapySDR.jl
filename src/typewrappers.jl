
## KWArgs

abstract type KWArgs <: AbstractDict{Symbol, String}; end

mutable struct OwnedKWArgs <: KWArgs
    ptr::SoapySDRKwargs
    function OwnedKWArgs(kw::SoapySDRKwargs)
        this = new(kw)
        finalizer(SoapySDRKwargs_clear, this)
        this
    end
end
Base.unsafe_load(o::OwnedKWArgs) = o.ptr
function ptr(kw::OwnedKWArgs)
    return pointer_from_objref(kw)
end
function SoapySDRKwargs_clear(kw::OwnedKWArgs)
    SoapySDRKwargs_clear(ptr(kw))
end

mutable struct KWArgsList <: AbstractVector{KWArgs}
    ptr::Ptr{SoapySDRKwargs}
    length::Csize_t
    function KWArgsList(ptr::Ptr{SoapySDRKwargs}, length::Csize_t)
        this = new(ptr, length)
        finalizer(this) do this
            SoapySDRKwargsList_clear(this.ptr, this.length)
        end
        this
    end
end
Base.size(kwl::KWArgsList) = (kwl.length,)

struct KWArgsListRef <: KWArgs
    list::KWArgsList
    idx::Int
    function Base.getindex(kwl::KWArgsList, i::Integer)
        checkbounds(kwl, i)
        new(kwl, i)
    end
end

function ptr(kwl::KWArgsListRef)
    @assert kwl.list.ptr !== C_NULL
    kwl.list.ptr + (kwl.idx-1)*sizeof(SoapySDRKwargs)
end

function Base.setindex!(kwl::KWArgsListRef, val::String, key::String)
    SoapySDRKwargs_set(ptr(kwl), key, val)
end

Base.unsafe_load(kw::KWArgs) = unsafe_load(ptr(kw))
Base.length(kw::KWArgs) = unsafe_load(kw).size
function _getindex(kw::KWArgs, i::Integer)
    1 <= i <= length(kw) || throw(BoundsError(kw, i))
    @GC.preserve kw begin
        return Symbol(unsafe_string(unsafe_load(unsafe_load(kw).keys, i))) =>
               unsafe_string(unsafe_load(unsafe_load(kw).vals, i))
    end
end

Base.iterate(kw::KWArgs, i=1) = i > length(kw) ? nothing : (_getindex(kw, i), i+1)


function SoapySDRKwargsList_clear(list::KWArgsList)
    SoapySDRKwargsList_clear(list.ptr, list.length)
    list.ptr = C_NULL
end

##

mutable struct StringList <: AbstractVector{String}
    strs::Ptr{Cstring}
    length::Csize_t
    function StringList(strs::Ptr{Cstring}, length::Integer)
        this = new(strs, Csize_t(length))
        finalizer(SoapySDRStrings_clear, this)
        this
    end
end
Base.size(s::StringList) = (s.length,)
function Base.getindex(s::StringList, i::Integer)
    checkbounds(s, i)
    unsafe_string(unsafe_load(s.strs, i))
end

SoapySDRStrings_clear(s::StringList) = @GC.preserve s SoapySDRStrings_clear(pointer_from_objref(s), s.length)


function Base.show(io::IO, s::SoapySDRArgInfo)
    println(io, "name: ", unsafe_string(s.units))
    println(io, "key: ", unsafe_string(s.key))
    println(io, "value: ", unsafe_string(s.name))
    println(io, "description: ", unsafe_string(s.description))
    println(io, "units: ", unsafe_string(s.units))
    #type
    #range
    println(io, "options: ", StringList(s.options, s.numOptions))
    println(io, "optionNames: ", StringList(s.optionNames, s.numOptions))
end