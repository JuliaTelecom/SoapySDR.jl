module SoapySDR

using soapysdr_jll
const lib = soapysdr_jll.libsoapysdr

using Intervals
using Unitful
using Unitful.DefaultSymbols
const dB = u"dB"
const GC = Base.GC

export @u_str

include("lowlevel/Constants.jl") # Done
include("lowlevel/Errors.jl")    # Done
include("lowlevel/Formats.jl")   # Done
include("lowlevel/Types.jl")     # Done
include("lowlevel/Device.jl")
include("lowlevel/Modules.jl")
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
