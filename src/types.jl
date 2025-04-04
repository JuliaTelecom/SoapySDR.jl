
## KWArgs

export KWArgs

mutable struct KWArgs <: AbstractDict{String,String}
    ptr::Ptr{SoapySDRKwargs}
    roots::Any

    function KWArgs(ptr::Ptr{SoapySDRKwargs}, roots=nothing; owned::Bool=true)
        this = new(ptr, roots)
        owned && finalizer(SoapySDRKwargs_clear, this)
        return this
    end
end

# Some SoapySDR API functions give us SoapySDRKwargs structs (e.g. SoapySDRKwargs_fromString
# or SoapySDRDevice_getHardwareInfo), while functions accepting one take pointers. For this,
# we have to maintain our own box we can derive a pointer from. However, we cannot do this
# for all KWArgs values, e.g., when iterating a KWArgsList, we need to keep referencing the
# contained KWArgs or mutating APIs (e.g. SoapySDRKwargs_set) will affect the wrong object.
function KWArgs(val::SoapySDRKwargs; owned::Bool=true)
    box = Ref(val)
    ptr = Base.unsafe_convert(Ptr{SoapySDRKwargs}, box)
    KWArgs(ptr, box; owned)
end

KWArgs() = parse(KWArgs, "")

function KWArgs(kwargs::Base.Iterators.Pairs)
    args = KWArgs()
    for kv in kwargs
        args[string(kv.first)] = kv.second
    end
    return args
end

Base.unsafe_convert(::Type{<:Ptr{SoapySDRKwargs}}, args::KWArgs) = args.ptr

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

Base.length(kw::KWArgs) = unsafe_load(kw.ptr).size

function Base.iterate(kw::KWArgs, i = 1)
    i > length(kw) && return nothing
    GC.@preserve kw begin
        kwargs = unsafe_load(kw.ptr)
        return (
            unsafe_string(unsafe_load(kwargs.keys, i)) =>
                unsafe_string(unsafe_load(kwargs.vals, i))
        ),
        i + 1
    end
end


## KWArgsList

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

function Base.getindex(kwl::KWArgsList, i::Integer)
    @boundscheck checkbounds(kwl, i)
    KWArgs(kwl.ptr + (i - 1) * sizeof(SoapySDRKwargs); owned = false)
end


## ArgInfoList

mutable struct ArgInfoList <: AbstractVector{SoapySDRArgInfo}
    ptr::Ptr{SoapySDRArgInfo}
    length::Csize_t

    function ArgInfoList(ptr::Ptr{SoapySDRArgInfo}, length::Csize_t)
        this = new(ptr, length)
        finalizer(this) do this
            SoapySDRArgInfoList_clear(this, this.length)
        end
        return this
    end
end

Base.unsafe_convert(::Type{Ptr{SoapySDRArgInfo}}, kwl::ArgInfoList) = kwl.ptr
Base.size(kwl::ArgInfoList) = (kwl.length,)

function Base.getindex(kwl::ArgInfoList, i::Integer)
    @boundscheck checkbounds(kwl, i)
    unsafe_load(kwl.ptr, i)
end


## StringList

mutable struct StringList <: AbstractVector{String}
    strs::Ptr{Cstring}
    length::Csize_t

    function StringList(strs::Ptr{Cstring}, length::Integer; owned::Bool = true)
        this = new(strs, Csize_t(length))
        if owned
            finalizer(SoapySDRStrings_clear, this)
        end
        this
    end
end

function StringList(strs::Ptr{Ptr{Cchar}}, length::Integer; kwargs...)
    StringList(reinterpret(Ptr{Cstring}, strs), length; kwargs...)
end

Base.size(s::StringList) = (s.length,)

function Base.getindex(s::StringList, i::Integer)
    checkbounds(s, i)
    unsafe_string(unsafe_load(s.strs, i))
end

SoapySDRStrings_clear(s::StringList) =
    GC.@preserve s SoapySDRStrings_clear(pointer_from_objref(s), s.length)


## ArgInfo

function Base.show(io::IO, s::SoapySDRArgInfo)
    println(io, "name: ", unsafe_string(s.name))
    println(io, "key: ", unsafe_string(s.key))
    #println(io, "value: ", unsafe_string(s.value))
    println(io, "description: ", unsafe_string(s.description))
    println(io, "units: ", unsafe_string(s.units))
    #type
    #range
    println(io, "options: ", StringList(s.options, s.numOptions; owned = false))
    println(io, "optionNames: ", StringList(s.optionNames, s.numOptions; owned = false))
end

function Base.show(io::IO, s::SoapySDRRange)
    print(io, s.minimum, ":", s.step, ":", s.maximum)
end
