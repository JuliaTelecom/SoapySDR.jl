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
include("typemap.jl")
include("highlevel.jl")

const SDRStream = Stream
export SDRStream

end
