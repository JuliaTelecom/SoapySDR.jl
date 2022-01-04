
## KWArgs

export KWArgs

mutable struct KWArgs <: AbstractDict{String, String}
    box::Base.RefValue{SoapySDRKwargs}

    function KWArgs(kw::SoapySDRKwargs; owned::Bool=true)
        this = new(Ref(kw))
        owned && finalizer(SoapySDRKwargs_clear, this)
        return this
    end
end

KWArgs() = KWArgs(SoapySDRKwargs_fromString(""))

function KWArgs(kwargs::Base.Iterators.Pairs)
    args = KWArgs()
    for kv in kwargs
        args[String(kv.first)] = kv.second
    end
    return args
end

Base.unsafe_convert(T::Type{Ptr{SoapySDRKwargs}}, args::KWArgs) =
    Base.unsafe_convert(T, args.box)

Base.String(args::KWArgs) = unsafe_string(SoapySDRKwargs_toString(args))

Base.parse(::Type{KWArgs}, str::String) = KWArgs(SoapySDRKwargs_fromString(str))

function Base.show(io::IO, ::MIME{Symbol("text/plain")}, args::KWArgs)
    print(io, "KWArgs(")
    print(io, String(args))
    print(io, ")")
end

function Base.getindex(args::KWArgs, key)
    key = convert(String, key)
    cstr = SoapySDRKwargs_get(args, key)
    cstr == C_NULL && throw(KeyError(key))
    unsafe_string(cstr)
end

function Base.setindex!(args::KWArgs, value, key)
    key = convert(String, key)
    value = convert(String, value)
    SoapySDRKwargs_set(args, key, value)
    args
end

Base.length(kw::KWArgs) = kw.box[].size

function Base.iterate(kw::KWArgs, i=1)
    i > length(kw) && return nothing
    @GC.preserve kw begin
        return (unsafe_string(unsafe_load(kw.box[].keys, i))=>
                unsafe_string(unsafe_load(kw.box[].vals, i))), i+1
    end
end


## KWArgsList

mutable struct KWArgsList <: AbstractVector{KWArgs}
    ptr::Ptr{SoapySDRKwargs}
    length::Csize_t

    function KWArgsList(ptr::Ptr{SoapySDRKwargs}, length::Csize_t)
        this = new(ptr, length)
        finalizer(this) do this
            SoapySDRKwargsList_clear(this, this.length)
        end
    end
end

Base.size(kwl::KWArgsList) = (kwl.length,)

function Base.unsafe_convert(::Type{Ptr{SoapySDRKwargs}}, kwl::KWArgsList)
    @assert kwl.ptr !== C_NULL
    kwl.ptr
end

function Base.getindex(kwl::KWArgsList, i::Integer)
    @boundscheck checkbounds(kwl, i)
    KWArgs(unsafe_load(kwl.ptr, i); owned=false)
end


## StringList

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
