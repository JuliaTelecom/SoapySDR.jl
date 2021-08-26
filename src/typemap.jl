# Map of Soapy stream formats to Julia types

const _stream_type_map = Dict{String, Type}(
    SOAPY_SDR_CF64 => Complex{Float64},
    SOAPY_SDR_CF32 => Complex{Float32},
    SOAPY_SDR_CS32 => Complex{Int32},
    SOAPY_SDR_CU32 => Complex{UInt32},
    SOAPY_SDR_CS16 => Complex{Int16},
    SOAPY_SDR_CU16 => Complex{UInt16},
    SOAPY_SDR_CS12 => ErrorException, #Complex{Int12},
    SOAPY_SDR_CU12 => ErrorException, #Complex{UInt12},
    SOAPY_SDR_CS8  => Complex{Int8},
    SOAPY_SDR_CU8  => Complex{UInt8},
    SOAPY_SDR_CS4  => ErrorException, #Complex{Int4},
    SOAPY_SDR_CU4  => ErrorException, #Complex{UInt4},
    SOAPY_SDR_F64  => Float64,
    SOAPY_SDR_F32  => Float32,
    SOAPY_SDR_S32  => Int32,
    SOAPY_SDR_U32  => UInt32,
    SOAPY_SDR_S16  => Int16,
    SOAPY_SDR_U16  => UInt16,
    SOAPY_SDR_S8   => Int8,
    SOAPY_SDR_U8   => UInt8
)