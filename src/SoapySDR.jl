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

# auto-generated C library wrappers
include("errors.jl")
include("libsoapysdr.jl")

# Julia wrappers
include("constants.jl")
include("types.jl")
include("logger.jl")
include("version.jl")
include("modules.jl")
include("device.jl")
include("device/channel.jl")
include("device/stream.jl")
include("device/sensor.jl")
include("device/time.jl")

# helpers
include("typemap.jl")
include("unithelpers.jl")
include("wrappers.jl")  # TODO: get rid of this

# high-level functionality
include("components.jl")

end
