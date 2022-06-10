module SoapySDR

using soapysdr_jll
const lib = soapysdr_jll.libsoapysdr
const soapysdr = soapysdr_jll.libsoapysdr
using CEnum

using Intervals
using Unitful
using Unitful.DefaultSymbols
const dB = u"dB"
const GC = Base.GC

export @u_str

include("lowlevel/Constants.h.jl")
include("lowlevel/Converters.h.jl")
include("lowlevel/Version.h.jl")
include("lowlevel/Errors.h.jl")
include("lowlevel/Formats.h.jl")
include("lowlevel/Time.h.jl")
include("lowlevel/Types.h.jl")
include("lowlevel/Device.jl")
include("lowlevel/Modules.h.jl")
include("lowlevel/Logger.jl")
include("typemap.jl")
include("typewrappers.jl")
include("highlevel.jl")
include("loghandler.jl")

const SDRStream = Stream
export SDRStream

#
# FIXME: Log handler breaks USRP Support
#
#function __init__()
#    julia_log_handler = @cfunction(logger_soapy2jl, Cvoid, (Cint, Cstring))
#    SoapySDR_registerLogHandler(julia_log_handler)
#end

end
