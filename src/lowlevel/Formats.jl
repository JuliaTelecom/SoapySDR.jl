# Format strings used in the stream API.

# Complex 64-bit floats (complex double)
const SOAPY_SDR_CF64 = "CF64"

# Complex 32-bit floats (complex float)
const SOAPY_SDR_CF32 = "CF32"

# Complex signed 32-bit integers (complex int32)
const SOAPY_SDR_CS32 = "CS32"

# Complex unsigned 32-bit integers (complex uint32)
const SOAPY_SDR_CU32 = "CU32"

# Complex signed 16-bit integers (complex int16)
const SOAPY_SDR_CS16 = "CS16"

# Complex unsigned 16-bit integers (complex uint16)
const SOAPY_SDR_CU16 = "CU16"

# Complex signed 12-bit integers (3 bytes)
const SOAPY_SDR_CS12 = "CS12"

# Complex unsigned 12-bit integers (3 bytes)
const SOAPY_SDR_CU12 = "CU12"

# Complex signed 8-bit integers (complex int8)
const SOAPY_SDR_CS8 = "CS8"

# Complex unsigned 8-bit integers (complex uint8)
const SOAPY_SDR_CU8 = "CU8"

# Complex signed 4-bit integers (1 byte)
const SOAPY_SDR_CS4 = "CS4"

# Complex unsigned 4-bit integers (1 byte)
const SOAPY_SDR_CU4 = "CU4"

# Real 64-bit floats (double)
const SOAPY_SDR_F64 = "F64"

# Real 32-bit floats (float)
const SOAPY_SDR_F32 = "F32"

# Real signed 32-bit integers (int32)
const SOAPY_SDR_S32 = "S32"

# Real unsigned 32-bit integers (uint32)
const SOAPY_SDR_U32 = "U32"

# Real signed 16-bit integers (int16)
const SOAPY_SDR_S16 = "S16"

# Real unsigned 16-bit integers (uint16)
const SOAPY_SDR_U16 = "U16"

# Real signed 8-bit integers (int8)
const SOAPY_SDR_S8 = "S8"

# Real unsigned 8-bit integers (uint8)
const SOAPY_SDR_U8 = "U8"


# Get the size of a single element in the specified format.
# param format a supported format string
# return the size of an element in bytes
function SoapySDR_formatToSize(format)
    ccall((:SoapySDR_formatToSize, lib), Cint, (Cstring, ), format)
end
