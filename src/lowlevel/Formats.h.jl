"""
    SoapySDR_formatToSize(format)

Get the size of a single element in the specified format.
\\param format a supported format string
\\return the size of an element in bytes
"""
function SoapySDR_formatToSize(format)
    ccall((:SoapySDR_formatToSize, soapysdr), Csize_t, (Ptr{Cchar},), format)
end

const SOAPY_SDR_CF64 = "CF64"

const SOAPY_SDR_CF32 = "CF32"

const SOAPY_SDR_CS32 = "CS32"

const SOAPY_SDR_CU32 = "CU32"

const SOAPY_SDR_CS16 = "CS16"

const SOAPY_SDR_CU16 = "CU16"

const SOAPY_SDR_CS12 = "CS12"

const SOAPY_SDR_CU12 = "CU12"

const SOAPY_SDR_CS8 = "CS8"

const SOAPY_SDR_CU8 = "CU8"

const SOAPY_SDR_CS4 = "CS4"

const SOAPY_SDR_CU4 = "CU4"

const SOAPY_SDR_F64 = "F64"

const SOAPY_SDR_F32 = "F32"

const SOAPY_SDR_S32 = "S32"

const SOAPY_SDR_U32 = "U32"

const SOAPY_SDR_S16 = "S16"

const SOAPY_SDR_U16 = "U16"

const SOAPY_SDR_S8 = "S8"

const SOAPY_SDR_U8 = "U8"

