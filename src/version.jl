"""
    versioninfo(io::IO=stdout)

Print information about the version of SoapySDR in use.
"""
function versioninfo(io = stdout; kwargs...)
    api_ver = unsafe_string(SoapySDR_getAPIVersion())
    abi_ver = unsafe_string(SoapySDR_getABIVersion())
    lib_ver = unsafe_string(SoapySDR_getLibVersion())
    println(io, "API Version ", api_ver)
    println(io, "ABI Version ", abi_ver)
    println(io, "Library Version ", lib_ver)
end
