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

include("lowlevel/auto_wrap.jl")
include("unithelpers.jl")
include("functionwraps.jl")
include("typemap.jl")
include("typewrappers.jl")
include("highlevel.jl")
include("loghandler.jl")

const SDRStream = Stream
export SDRStream


end
