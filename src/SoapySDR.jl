module SoapySDR

using soapysdr_jll
const soapysdr = soapysdr_jll.libsoapysdr

using CEnum

using Intervals
using Unitful
using Unitful.DefaultSymbols
const dB = u"dB"
const GC = Base.GC

export @u_str

include("error.jl")
include("libsoapysdr.jl")

include("unithelpers.jl")
include("typemap.jl")
include("typewrappers.jl")
include("highlevel.jl")
include("functionwraps.jl")
include("logger.jl")
include("version.jl")
include("modules.jl")

const SDRStream = Stream

export SDRStream,
    SOAPY_SDR_TX,
    SOAPY_SDR_RX,
    SOAPY_SDR_END_BURST,
    SOAPY_SDR_HAS_TIME,
    SOAPY_SDR_END_ABRUPT,
    SOAPY_SDR_ONE_PACKET,
    SOAPY_SDR_MORE_FRAGMENTS,
    SOAPY_SDR_WAIT_TRIGGER,
    SOAPY_SDR_TIMEOUT,
    SOAPY_SDR_STREAM_ERROR,
    SOAPY_SDR_CORRUPTION,
    SOAPY_SDR_OVERFLOW,
    SOAPY_SDR_NOT_SUPPORTED,
    SOAPY_SDR_TIME_ERROR,
    SOAPY_SDR_UNDERFLOW

end
