# 
# SoapySDR Modules API
#
# https://github.com/pothosware/SoapySDR/blob/1cf5a539a21414ff509ff7d0eedfc5fa8edb90c6/include/SoapySDR/Modules.h

""" Query the root installation path"""
function SoapySDR_getRootPath()
    #SOAPY_SDR_API const char *SoapySDR_getRootPath(void);
    @check_error ccall((:SoapySDR_getRootPath, lib), Cstring, ())
end

"""
The list of paths automatically searched by loadModules().

param [out] length the number of elements in the result.
return a list of automatically searched file paths
"""
function SoapySDR_listSearchPaths()
    #SOAPY_SDR_API char **SoapySDR_listSearchPaths(size_t *length);
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDR_listSearchPaths, lib), Ptr{Cstring}, (Ref{Csize_t},), len)
    (ptr, len[])
end

"""
List all modules found in default path.
The result is an array of strings owned by the caller.

param [out] length the number of elements in the result.
return a list of file paths to loadable modules
"""
function SoapySDR_listModules()
    #SOAPY_SDR_API char **SoapySDR_listModules(size_t *length);
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDR_listModules, lib), Ptr{Cstring}, (Ref{Csize_t},), len)
    (ptr, len[])
end

"""
List all modules found in the given path.
The result is an array of strings owned by the caller.

param path a directory on the system
param [out] length the number of elements in the result.
return a list of file paths to loadable modules
"""
function SoapySDR_listModulesPath(path)
    #SOAPY_SDR_API char **SoapySDR_listModulesPath(const char *path, size_t *length);
    len = Ref{Csize_t}()
    ptr = @check_error ccall((:SoapySDR_listModulesPath, lib), Ptr{Cstring}, (Cstring, Ref{Csize_t}), path, len)
    (ptr, len[])
end

"""
Load a single module given its file system path.
The caller must free the result error string.

param path the path to a specific module file]
return an error message, empty on success
"""
function SoapySDR_loadModule(path)
    #SOAPY_SDR_API char *SoapySDR_loadModule(const char *path);
    err = @check_error ccall((:SoapySDR_loadModule, lib), SoapySDRKwargs, (Cstring,), path)
    err
end

"""
List all registration loader errors for a given module path.
The resulting dictionary contains all registry entry names
provided by the specified module. The value of each entry
is an error message string or empty on successful load.

param path the path to a specific module file
return a dictionary of registry names to error messages
"""
function SoapySDR_listLoaderResult(path)
    #SOAPY_SDR_API SoapySDRKwargs SoapySDR_getLoaderResult(const char *path);
    kwargs = @check_error ccall((:SoapySDR_listLoaderResult, lib), SoapySDRKwargs, (Cstring,), path)
    kwargs
end

"""
Get a version string for the specified module.
Modules may optionally provide version strings.

param path the path to a specific module file
return a version string or empty if no version provided
"""
function SoapySDR_getModuleVersion(path)
    #SOAPY_SDR_API char *SoapySDR_getModuleVersion(const char *path);
    ver = @check_error ccall((:SoapySDR_getModuleVersion, lib), Cstring, (Cstring,), path)
    ver
end

"""
Unload a module that was loaded with loadModule().
The caller must free the result error string.

param path the path to a specific module file
return an error message, empty on success
"""
function SoapySDR_unloadModule(path)
    #SOAPY_SDR_API char *SoapySDR_unloadModule(const char *path);
    err = @check_error ccall((:SoapySDR_loadModules, lib), Cstring, (Cstring,), path)
    err
end

"""
Load the support modules installed on this system.
This call will only actually perform the load once.
Subsequent calls are a NOP.
"""
function SoapySDR_loadModules()
    #SOAPY_SDR_API void SoapySDR_loadModules(void);
    @check_error ccall((:SoapySDR_loadModules, lib), Cvoid, ())
end

"""
Unload all currently loaded support modules.
"""
function SoapySDR_unloadModules()
    #SOAPY_SDR_API void SoapySDR_unloadModules(void);
    @check_error ccall((:SoapySDR_unloadModule, lib), Cvoid, ())
end