module SoapySDR

using soapysdr_jll
const lib = soapysdr_jll.libsoapysdr

# Julia support for Units and Interval for Highlevel API
using Intervals
using Unitful
using Unitful.DefaultSymbols

# SoapySDR modules in Yggdrasil
using SoapyLMS7_jll
using SoapyRTLSDR_jll
using SoapyUHD_jll
using xtrx_jll

const dB = u"dB"
const GC = Base.GC

export @u_str

include("lowlevel/Constants.jl") # Done
include("lowlevel/Errors.jl")    # Done
include("lowlevel/Formats.jl")   # Done
include("lowlevel/Types.jl")     # Done
include("lowlevel/Device.jl")
include("lowlevel/Modules.jl")
include("typemap.jl")
include("highlevel.jl")

const SDRStream = Stream
export SDRStream

end
