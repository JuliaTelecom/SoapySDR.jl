"""
`SoapySDR.Modules` provides a modules for loading SoapySDR modules via paths.
This is an alternative to environmental variables and dlopen. 
"""
module Modules

using ..SoapySDR

function get_root_path()
    ptr = SoapySDR.SoapySDR_getRootPath()
    ptr == C_NULL ? "" : unsafe_string(ptr)
end

function list_search_paths()
    len = Ref{Csize_t}()
    ptr = SoapySDR.SoapySDR_listSearchPaths(len)
    SoapySDR.StringList(ptr, len[])
end

function list()
    len = Ref{Csize_t}()
    ptr = SoapySDR.SoapySDR_listModules(len)
    SoapySDR.StringList(ptr, len[])
end

function list_in_path(path)
    len = Ref{Csize_t}()
    ptr = SoapySDR.SoapySDR_listModulesPath(path, len)
    SoapySDR.StringList(ptr, len[])
end

function load_module(path)
    ptr = SoapySDR.SoapySDR_loadModule(path)
    ptr == C_NULL ? "" : unsafe_string(ptr)
end

function get_module_version(path)
    ptr = SoapySDR.SoapySDR_getModuleVersion(path)
    ptr == C_NULL ? "" : unsafe_string(ptr)
end

function unload_module(path)
    ptr = SoapySDR.SoapySDR_unloadModule(path)
    ptr == C_NULL ? "" : unsafe_string(ptr)
end

function load()
    SoapySDR.SoapySDR_loadModules()
end

function unload()
    SoapySDR.SoapySDR_unloadModules()
end

end