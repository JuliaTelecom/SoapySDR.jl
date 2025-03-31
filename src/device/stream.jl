"""
    SoapySDR.Stream(channels)
    SoapySDR.Stream(::Type{T}, channels)

Constructs a `Stream{T}` where `T` is the stream type of the device. If unspecified,
the native format will be used.

Fields:
- nchannels - The number of channels in the stream
- mtu - The stream Maximum Transmission Unit
- num_direct_access_buffers - The numer of direct access buffers available in the stream

## Example
```
SoapySDR.Stream(Devices()[1].rx)
```
"""
mutable struct Stream{T}
    d::Device
    nchannels::Int
    ptr::Ptr{SoapySDRStream}
    function Stream{T}(d::Device, nchannels, ptr::Ptr{SoapySDRStream}) where {T}
        this = new{T}(d, Int(nchannels), ptr)
        finalizer(this) do obj
            isopen(d) || return
            SoapySDRDevice_closeStream(d, obj.ptr)
            obj.ptr = Ptr{SoapySDRStream}(C_NULL)
        end
        return this
    end
end

# XXX: why this export?
export SDRStream
const SDRStream = Stream

Base.cconvert(::Type{<:Ptr{SoapySDRStream}}, s::Stream) = s
Base.unsafe_convert(::Type{<:Ptr{SoapySDRStream}}, s::Stream) = s.ptr
Base.isopen(s::Stream) = s.ptr != C_NULL && isopen(s.d)

streamtype(::Stream{T}) where {T} = T

function Base.setproperty!(c::Stream, s::Symbol, v)
    return setfield!(c, s, v)
end

function Base.propertynames(::Stream)
    return (:d, :nchannels, :mtu, :num_direct_access_buffers)
end

function Base.getproperty(stream::Stream, s::Symbol)
    if s === :mtu
        if !isopen(stream)
            throw(InvalidStateException("Stream is closed!", :closed))
        end
        SoapySDRDevice_getStreamMTU(stream.d.ptr, stream.ptr)
    elseif s === :num_direct_access_buffers
        if !isopen(stream)
            throw(InvalidStateException("Stream is closed!", :closed))
        end
        SoapySDRDevice_getNumDirectAccessBuffers(stream.d.ptr, stream.ptr)
    else
        return getfield(stream, s)
    end
end

function Base.show(io::IO, s::Stream)
    print(io, "Stream on ", s.d.hardware)
end

function Stream(format::Type, device::Device, direction::Direction; kwargs...)
    Stream{T}(
        device,
        1,
        SoapySDRDevice_setupStream(
            device,
            direction,
            string(format),
            C_NULL,
            0,
            KWArgs(kwargs),
        ),
    )
end

function Stream(format::Type, channels::AbstractVector{T}; kwargs...) where {T<:Channel}
    soapy_format = _stream_map_jl2soapy(format)
    isempty(channels) && error(
        "Must specify at least one channel or use the device/direction constructor for automatic.",
    )
    device = first(channels).device
    direction = first(channels).direction
    if !all(channels) do channel
        channel.device == device && channel.direction == direction
    end
        throw(ArgumentError("Channels must agree on device and direction"))
    end
    Stream{format}(
        device,
        length(channels),
        SoapySDRDevice_setupStream(
            device,
            direction,
            soapy_format,
            map(x -> x.idx, channels),
            length(channels),
            KWArgs(kwargs),
        ),
    )
end

function Stream(channels::AbstractVector{T}; kwargs...) where {T<:Channel}
    native_format = promote_type(map(c -> c.native_stream_format, channels)...)
    if native_format <: AbstractComplexInteger
        @warn "$(string(native_format)) may be poorly supported, it is recommend to specify a different type with Stream(format::Type, channels)"
    end
    Stream(native_format, channels; kwargs...)
end

function Stream(format::Type, channel::Channel; kwargs...)
    Stream(format, [channel], kwargs...)
end

function Stream(channel::Channel; kwargs...)
    Stream([channel], kwargs...)
end

function Stream(f::Function, args...; kwargs...)
    stream = Stream(args...; kwargs...)
    try
        f(stream)
    finally
        finalize(stream)
    end
end

const SoapyStreamFlags = Dict(
    "END_BURST" => SOAPY_SDR_END_BURST,
    "HAS_TIME" => SOAPY_SDR_HAS_TIME,
    "END_ABRUPT" => SOAPY_SDR_END_ABRUPT,
    "ONE_PACKET" => SOAPY_SDR_ONE_PACKET,
    "MORE_FRAGMENTS" => SOAPY_SDR_MORE_FRAGMENTS,
    "WAIT_TRIGGER" => SOAPY_SDR_WAIT_TRIGGER,
)

function flags_to_set(flags)
    s = Set{String}()
    for (name, val) in SoapyStreamFlags
        if val & flags != 0
            push!(s, name)
        end
    end
    return s
end

function Base.read!(
    ::Stream,
    ::NTuple;
    kwargs...
)
    error("Buffers should be a Vector of Vectors rather than NTuple.")
end

"""
    read!(s::SoapySDR.Stream{T}, buffers::AbstractVector{AbstractVector{T}}; [timeout], [flags::Ref{Int}], [throw_error=false])

Read data from the device into the given buffers.
"""
function Base.read!(
    s::Stream{T},
    buffers::AbstractVector{<:AbstractVector{T}};
    timeout = nothing,
    flags::Union{Ref{Int},Nothing} = nothing,
    throw_error::Bool = false,
) where {T}
    t_start = time()
    timeout === nothing && (timeout = 0.1u"s") # Default from SoapySDR upstream
    timeout_s = uconvert(u"s", timeout).val
    timeout_us = uconvert(u"μs", timeout).val

    total_nread = 0
    samples_to_read = length(first(buffers))
    if !all(length(b) == samples_to_read for b in buffers)
        throw(ArgumentError("Buffers must all be same length!"))
    end
    GC.@preserve buffers while total_nread < samples_to_read
        # collect list of pointers to pass to SoapySDR
        isopen(s) || throw(InvalidStateException("stream is closed!", :closed))
        buff_ptrs = pointer(map(b -> pointer(b, total_nread + 1), buffers))
        out_flags = Ref{Cint}()
        timens = Ref{Clonglong}()
        nread = SoapySDRDevice_readStream(
            s.d,
            s,
            buff_ptrs,
            samples_to_read - total_nread,
            out_flags,
            timens,
            timeout_us,
        )

        if typeof(flags) <: Ref
            flags[] |= out_flags[]
        end

        if nread < 0
            if throw_error
                throw(SoapySDRDeviceError(nread, error_to_string(nread)))
            end
        else
            total_nread += nread
        end

        if time() > t_start + timeout_s
            # We've timed out, return early and warn.  Something is probably wrong.
            @warn(
                "readStream timeout!",
                timeout = timeout_s,
                total_nread,
                samples_to_read,
                flags = join(flags_to_set(out_flags[]), ","),
            )
            return buffers
        end
    end
    return buffers
end

"""
    read(s::SoapySDR.Stream{T}, nb::Integer; [timeout])

Read at most `nb` samples from s
"""
function Base.read(s::Stream{T}, n::Integer; timeout = nothing) where {T}
    bufs = [Vector{T}(undef, n) for _ in 1:s.nchannels]
    read!(s, bufs; timeout)
    bufs
end

function activate!(s::Stream; flags = 0, timens = nothing, numElems = nothing)
    if !isopen(s)
        throw(InvalidStateException("stream is closed!", :closed))
    end
    if timens === nothing
        timens = 0
    else
        timens = uconvert(u"ns", timens).val
    end
    if numElems === nothing
        numElems = 0
    end

    SoapySDRDevice_activateStream(s.d, s, flags, timens, numElems)
    return nothing
end

function activate!(f::Function, streams::AbstractVector{<:Stream}; kwargs...)
    activated_streams = Vector{SoapySDR.Stream}(undef, length(streams))
    try
        for i in eachindex(streams)
            s = streams[i]
            activate!(s; kwargs...)
            activated_streams[i] = s
        end
        f()
    finally
        for s in activated_streams
            deactivate!(s; kwargs...)
        end
    end
end

function activate!(f::Function, s::Stream; kwargs...)
    try
        activate!(s; kwargs...)
        f()
    finally
        deactivate!(s; kwargs...)
    end
end

function deactivate!(s::Stream; flags = 0, timens = nothing)
    isopen(s) || throw(InvalidStateException("Stream is closed!", :closed))
    SoapySDRDevice_deactivateStream(
        s.d,
        s,
        flags,
        timens === nothing ? 0 : uconvert(u"ns", timens).val,
    )
    return nothing
end

function Base.write(
    ::Stream,
    ::NTuple;
    kwargs...
)
    error("Buffers should be a Vector of Vectors rather than NTuple.")
end

"""
    write(s::SoapySDR.Stream{T}, buffer::AbstractVector{AbstractVector{T}}; [timeout], [flags::Ref{Int}], [throw_error=false]) where {N, T}

Write data from the given buffers into the device.  The buffers must all be the same length.
"""
function Base.write(
    s::Stream{T},
    buffers::AbstractVector{<:AbstractVector{T}};
    timeout = nothing,
    flags::Union{Ref{Int},Nothing} = nothing,
    throw_error::Bool = false,
) where {T}
    t_start = time()
    timeout === nothing && (timeout = 0.1u"s") # Default from SoapySDR upstream
    timeout_s = uconvert(u"s", timeout).val
    timeout_us = uconvert(u"μs", timeout).val

    total_nwritten = 0
    samples_to_write = length(first(buffers))
    if !all(length(b) == samples_to_write for b in buffers)
        throw(ArgumentError("Buffers must all be same length!"))
    end
    if length(buffers) != s.nchannels
        throw(ArgumentError("Must provide buffers for every channel in stream!"))
    end

    GC.@preserve buffers while total_nwritten < samples_to_write
        buff_ptrs = pointer(map(b -> pointer(b, total_nwritten + 1), buffers))
        out_flags = Ref{Cint}(0)
        nwritten = SoapySDRDevice_writeStream(
            s.d,
            s,
            buff_ptrs,
            samples_to_write - total_nwritten,
            flags,
            0,
            timeout_us,
        )

        if typeof(flags) <: Ref
            flags[] |= out_flags[]
        end

        if nwritten < 0
            if throw_error
                throw(SoapySDRDeviceError(nwritten, error_to_string(nwritten)))
            end
        else
            total_nwritten += nwritten
        end

        if time() > t_start + timeout_s
            # We've timed out, return early and warn.  Something is probably wrong.
            @warn(
                "writeStream timeout!",
                timeout = timeout_s,
                total_nwritten,
                samples_to_write,
                flags = join(flags_to_set(out_flags[]), ","),
            )
            return buffers
        end
    end
    return buffers
end
