struct SoapySDRKwargs
    size::Csize_t
    keys::Ptr{Ptr{Cchar}}
    vals::Ptr{Ptr{Cchar}}
end

"""
    SoapySDR_getRootPath()

Query the root installation path
"""
function SoapySDR_getRootPath()
    ccall((:SoapySDR_getRootPath, soapysdr), Ptr{Cchar}, ())
end

"""
    SoapySDR_listSearchPaths(length)

The list of paths automatically searched by loadModules().
\\param [out] length the number of elements in the result.
\\return a list of automatically searched file paths
"""
function SoapySDR_listSearchPaths(length)
    ccall((:SoapySDR_listSearchPaths, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Csize_t},), length)
end

"""
    SoapySDR_listModules(length)

List all modules found in default path.
The result is an array of strings owned by the caller.
\\param [out] length the number of elements in the result.
\\return a list of file paths to loadable modules
"""
function SoapySDR_listModules(length)
    ccall((:SoapySDR_listModules, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Csize_t},), length)
end

"""
    SoapySDR_listModulesPath(path, length)

List all modules found in the given path.
The result is an array of strings owned by the caller.
\\param path a directory on the system
\\param [out] length the number of elements in the result.
\\return a list of file paths to loadable modules
"""
function SoapySDR_listModulesPath(path, length)
    ccall((:SoapySDR_listModulesPath, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Cchar}, Ptr{Csize_t}), path, length)
end

"""
    SoapySDR_loadModule(path)

Load a single module given its file system path.
The caller must free the result error string.
\\param path the path to a specific module file
\\return an error message, empty on success
"""
function SoapySDR_loadModule(path)
    ccall((:SoapySDR_loadModule, soapysdr), Ptr{Cchar}, (Ptr{Cchar},), path)
end

"""
    SoapySDR_getLoaderResult(path)

List all registration loader errors for a given module path.
The resulting dictionary contains all registry entry names
provided by the specified module. The value of each entry
is an error message string or empty on successful load.
\\param path the path to a specific module file
\\return a dictionary of registry names to error messages
"""
function SoapySDR_getLoaderResult(path)
    ccall((:SoapySDR_getLoaderResult, soapysdr), SoapySDRKwargs, (Ptr{Cchar},), path)
end

"""
    SoapySDR_getModuleVersion(path)

Get a version string for the specified module.
Modules may optionally provide version strings.
\\param path the path to a specific module file
\\return a version string or empty if no version provided
"""
function SoapySDR_getModuleVersion(path)
    ccall((:SoapySDR_getModuleVersion, soapysdr), Ptr{Cchar}, (Ptr{Cchar},), path)
end

"""
    SoapySDR_unloadModule(path)

Unload a module that was loaded with loadModule().
The caller must free the result error string.
\\param path the path to a specific module file
\\return an error message, empty on success
"""
function SoapySDR_unloadModule(path)
    ccall((:SoapySDR_unloadModule, soapysdr), Ptr{Cchar}, (Ptr{Cchar},), path)
end

"""
    SoapySDR_loadModules()

Load the support modules installed on this system.
This call will only actually perform the load once.
Subsequent calls are a NOP.
"""
function SoapySDR_loadModules()
    ccall((:SoapySDR_loadModules, soapysdr), Cvoid, ())
end

"""
    SoapySDR_unloadModules()

Unload all currently loaded support modules.
"""
function SoapySDR_unloadModules()
    ccall((:SoapySDR_unloadModules, soapysdr), Cvoid, ())
end

