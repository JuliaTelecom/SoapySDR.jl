# Map of Soapy stream formats to Julia types

"""
Abstract type denoting a Complex(U)Int(12/4) type.

These need to be specially handled with bit shifting, and
we do no data processing in this library, so this
exists for convience to other package developers.

Subtypes are `ComplexInt` and `ComplexUInt`,
for convience with handling sign extends.
"""
abstract type AbstractComplexInteger end

"""
Type indicating a Complex Int format.

Parameter `T` indicates the number of bits.
"""
struct ComplexInt{T} <: AbstractComplexInteger; end

"""
Type indicating a Complex Unsigned Int format.

Parameter `T` indicates the number of bits.
"""
struct ComplexUInt{T} <: AbstractComplexInteger; end

const _stream_type_pairs = [
    (SOAPY_SDR_CF64, Complex{Float64}),
    (SOAPY_SDR_CF32, Complex{Float32}),
    (SOAPY_SDR_CS32, Complex{Int32}),
    (SOAPY_SDR_CU32, Complex{UInt32}),
    (SOAPY_SDR_CS16, Complex{Int16}),
    (SOAPY_SDR_CU16, Complex{UInt16}),
    (SOAPY_SDR_CS12, ComplexInt{12}),
    (SOAPY_SDR_CU12, ComplexUInt{12}),
    (SOAPY_SDR_CS8, Complex{Int8}),
    (SOAPY_SDR_CU8, Complex{UInt8}),
    (SOAPY_SDR_CS4, ComplexInt{4}),
    (SOAPY_SDR_CU4, ComplexUInt{4}),
    (SOAPY_SDR_F64, Float64),
    (SOAPY_SDR_F32, Float32),
    (SOAPY_SDR_S32, Int32),
    (SOAPY_SDR_U32, UInt32),
    (SOAPY_SDR_S16, Int16),
    (SOAPY_SDR_U16, UInt16),
    (SOAPY_SDR_S8, Int8),
    (SOAPY_SDR_U8, UInt8) ]

"""
Type map from SoapySDR Stream formats to Julia types.

Note: Please see ComplexUInt and ComplexUInt if using 12 or 4 bit complex types.
"""
const _stream_type_soapy2jl = Dict{String, Type}(_stream_type_pairs)

"""
Type map from SoapySDR Stream formats to Julia types.

Note: Please see ComplexUInt and ComplexUInt if using 12 or 4 bit complex types.
"""
const _stream_type_jl2soapy = Dict{Type, String}(reverse.(_stream_type_pairs))

function _stream_map_jl2soapy(stream_type)
    if !haskey(_stream_type_jl2soapy, stream_type)
        error("Unsupported stream type: " + stream_type)
    end
    return _stream_type_jl2soapy[stream_type]
end

function _stream_map_soapy2jl(stream_type)
    if !haskey(_stream_type_soapy2jl, stream_type)
        error("Unsupported stream type: " + stream_type)
    end
    return _stream_type_soapy2jl[stream_type]
end