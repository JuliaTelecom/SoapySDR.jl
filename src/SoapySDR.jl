module SoapySDR

using soapysdr_jll
const lib = soapysdr_jll.libsoapysdr

using Unitful
const dB = u"dB"

include("lowlevel/Constants.jl") # Done
include("lowlevel/Errors.jl")    # Done
include("lowlevel/Formats.jl")   # Done
include("lowlevel/Types.jl")     # Done
include("lowlevel/Device.jl")
include("highlevel.jl")

end
