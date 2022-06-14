# typedef void ( * SoapySDRConverterFunction ) ( const void * , void * , const size_t , const double )
"""
A typedef for declaring a ConverterFunction to be maintained in the ConverterRegistry.
A converter function copies and optionally converts an input buffer of one format into an
output buffer of another format.
The parameters are (input pointer, output pointer, number of elements, optional scalar)
"""
const SoapySDRConverterFunction = Ptr{Cvoid}

"""
    SoapySDRConverterFunctionPriority

Allow selection of a converter function with a given source and target format.
"""
@cenum SoapySDRConverterFunctionPriority::UInt32 begin
    SOAPY_SDR_CONVERTER_GENERIC = 0
    SOAPY_SDR_CONVERTER_VECTORIZED = 3
    SOAPY_SDR_CONVERTER_CUSTOM = 5
end

"""
    SoapySDRConverter_listTargetFormats(sourceFormat, length)

Get a list of existing target formats to which we can convert the specified source from.
\\param sourceFormat the source format markup string
\\param [out] length the number of valid target formats
\\return a list of valid target formats
"""
function SoapySDRConverter_listTargetFormats(sourceFormat, length)
    ccall((:SoapySDRConverter_listTargetFormats, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Cchar}, Ptr{Csize_t}), sourceFormat, length)
end

"""
    SoapySDRConverter_listSourceFormats(targetFormat, length)

Get a list of existing source formats to which we can convert the specified target from.
\\param targetFormat the target format markup string
\\param [out] length the number of valid source formats
\\return a list of valid source formats
"""
function SoapySDRConverter_listSourceFormats(targetFormat, length)
    ccall((:SoapySDRConverter_listSourceFormats, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Cchar}, Ptr{Csize_t}), targetFormat, length)
end

"""
    SoapySDRConverter_listPriorities(sourceFormat, targetFormat, length)

Get a list of available converter priorities for a given source and target format.
\\param sourceFormat the source format markup string
\\param targetFormat the target format markup string
\\param [out] length the number of priorities
\\return a list of priorities or nullptr if none are found
"""
function SoapySDRConverter_listPriorities(sourceFormat, targetFormat, length)
    ccall((:SoapySDRConverter_listPriorities, soapysdr), Ptr{SoapySDRConverterFunctionPriority}, (Ptr{Cchar}, Ptr{Cchar}, Ptr{Csize_t}), sourceFormat, targetFormat, length)
end

"""
    SoapySDRConverter_getFunction(sourceFormat, targetFormat)

Get a converter between a source and target format with the highest available priority.
\\param sourceFormat the source format markup string
\\param targetFormat the target format markup string
\\return a conversion function pointer or nullptr if none are found
"""
function SoapySDRConverter_getFunction(sourceFormat, targetFormat)
    ccall((:SoapySDRConverter_getFunction, soapysdr), SoapySDRConverterFunction, (Ptr{Cchar}, Ptr{Cchar}), sourceFormat, targetFormat)
end

"""
    SoapySDRConverter_getFunctionWithPriority(sourceFormat, targetFormat, priority)

Get a converter between a source and target format with a given priority.
\\param sourceFormat the source format markup string
\\param targetFormat the target format markup string
\\return a conversion function pointer or nullptr if none are found
"""
function SoapySDRConverter_getFunctionWithPriority(sourceFormat, targetFormat, priority)
    ccall((:SoapySDRConverter_getFunctionWithPriority, soapysdr), SoapySDRConverterFunction, (Ptr{Cchar}, Ptr{Cchar}, SoapySDRConverterFunctionPriority), sourceFormat, targetFormat, priority)
end

"""
    SoapySDRConverter_listAvailableSourceFormats(length)

Get a list of known source formats in the registry.
\\param [out] length the number of known source formats
\\return a list of known source formats
"""
function SoapySDRConverter_listAvailableSourceFormats(length)
    ccall((:SoapySDRConverter_listAvailableSourceFormats, soapysdr), Ptr{Ptr{Cchar}}, (Ptr{Csize_t},), length)
end

"""
    SoapySDR_errToStr(errorCode)

Convert a error code to a string for printing purposes.
If the error code is unrecognized, errToStr returns "UNKNOWN".
\\param errorCode a negative integer return code
\\return a pointer to a string representing the error
"""
function SoapySDR_errToStr(errorCode)
    ccall((:SoapySDR_errToStr, soapysdr), Ptr{Cchar}, (Cint,), errorCode)
end

"""
    SoapySDR_formatToSize(format)

Get the size of a single element in the specified format.
\\param format a supported format string
\\return the size of an element in bytes
"""
function SoapySDR_formatToSize(format)
    ccall((:SoapySDR_formatToSize, soapysdr), Csize_t, (Ptr{Cchar},), format)
end

"""
    SoapySDRLogLevel

The available priority levels for log messages.

The default log level threshold is SOAPY_SDR_INFO.
Log messages with lower priorities are dropped.

The default threshold can be set via the
SOAPY_SDR_LOG_LEVEL environment variable.
Set SOAPY_SDR_LOG_LEVEL to the string value:
"WARNING", "ERROR", "DEBUG", etc...
or set it to the equivalent integer value.
"""
@cenum SoapySDRLogLevel::UInt32 begin
    SOAPY_SDR_FATAL = 1
    SOAPY_SDR_CRITICAL = 2
    SOAPY_SDR_ERROR = 3
    SOAPY_SDR_WARNING = 4
    SOAPY_SDR_NOTICE = 5
    SOAPY_SDR_INFO = 6
    SOAPY_SDR_DEBUG = 7
    SOAPY_SDR_TRACE = 8
    SOAPY_SDR_SSI = 9
end

"""
    SoapySDR_log(logLevel, message)

Send a message to the registered logger.
\\param logLevel a possible logging level
\\param message a logger message string
"""
function SoapySDR_log(logLevel, message)
    ccall((:SoapySDR_log, soapysdr), Cvoid, (SoapySDRLogLevel, Ptr{Cchar}), logLevel, message)
end

# typedef void ( * SoapySDRLogHandler ) ( const SoapySDRLogLevel logLevel , const char * message )
"""
Typedef for the registered log handler function.
"""
const SoapySDRLogHandler = Ptr{Cvoid}

"""
    SoapySDR_registerLogHandler(handler)

Register a new system log handler.
Platforms should call this to replace the default stdio handler.
Passing `NULL` restores the default.
"""
function SoapySDR_registerLogHandler(handler)
    ccall((:SoapySDR_registerLogHandler, soapysdr), Cvoid, (SoapySDRLogHandler,), handler)
end

"""
    SoapySDR_setLogLevel(logLevel)

Set the log level threshold.
Log messages with lower priority are dropped.
"""
function SoapySDR_setLogLevel(logLevel)
    ccall((:SoapySDR_setLogLevel, soapysdr), Cvoid, (SoapySDRLogLevel,), logLevel)
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
    SoapySDRKwargs

Definition for a key/value string map
"""
struct SoapySDRKwargs
    size::Csize_t
    keys::Ptr{Ptr{Cchar}}
    vals::Ptr{Ptr{Cchar}}
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

"""
    SoapySDR_ticksToTimeNs(ticks, rate)

Convert a tick count into a time in nanoseconds using the tick rate.
\\param ticks a integer tick count
\\param rate the ticks per second
\\return the time in nanoseconds
"""
function SoapySDR_ticksToTimeNs(ticks, rate)
    ccall((:SoapySDR_ticksToTimeNs, soapysdr), Clonglong, (Clonglong, Cdouble), ticks, rate)
end

"""
    SoapySDR_timeNsToTicks(timeNs, rate)

Convert a time in nanoseconds into a tick count using the tick rate.
\\param timeNs time in nanoseconds
\\param rate the ticks per second
\\return the integer tick count
"""
function SoapySDR_timeNsToTicks(timeNs, rate)
    ccall((:SoapySDR_timeNsToTicks, soapysdr), Clonglong, (Clonglong, Cdouble), timeNs, rate)
end

"""
    SoapySDRRange

Definition for a min/max numeric range
"""
struct SoapySDRRange
    minimum::Cdouble
    maximum::Cdouble
    step::Cdouble
end

"""
    SoapySDRKwargs_fromString(markup)

Convert a markup string to a key-value map.
The markup format is: "key0=value0, key1=value1"
"""
function SoapySDRKwargs_fromString(markup)
    ccall((:SoapySDRKwargs_fromString, soapysdr), SoapySDRKwargs, (Ptr{Cchar},), markup)
end

"""
    SoapySDRKwargs_toString(args)

Convert a key-value map to a markup string.
The markup format is: "key0=value0, key1=value1"
"""
function SoapySDRKwargs_toString(args)
    ccall((:SoapySDRKwargs_toString, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRKwargs},), args)
end

"""
    SoapySDRArgInfoType

Possible data types for argument info
"""
@cenum SoapySDRArgInfoType::UInt32 begin
    SOAPY_SDR_ARG_INFO_BOOL = 0
    SOAPY_SDR_ARG_INFO_INT = 1
    SOAPY_SDR_ARG_INFO_FLOAT = 2
    SOAPY_SDR_ARG_INFO_STRING = 3
end

"""
    SoapySDRArgInfo

Definition for argument info
"""
struct SoapySDRArgInfo
    key::Ptr{Cchar}
    value::Ptr{Cchar}
    name::Ptr{Cchar}
    description::Ptr{Cchar}
    units::Ptr{Cchar}
    type::SoapySDRArgInfoType
    range::SoapySDRRange
    numOptions::Csize_t
    options::Ptr{Ptr{Cchar}}
    optionNames::Ptr{Ptr{Cchar}}
end

"""
    SoapySDR_free(ptr)

Free a pointer allocated by SoapySDR.
For most platforms this is a simple call around free()
"""
function SoapySDR_free(ptr)
    ccall((:SoapySDR_free, soapysdr), Cvoid, (Ptr{Cvoid},), ptr)
end

"""
    SoapySDRStrings_clear(elems, length)

Clear the contents of a list of string
Convenience call to deal with results that return a string list.
"""
function SoapySDRStrings_clear(elems, length)
    ccall((:SoapySDRStrings_clear, soapysdr), Cvoid, (Ptr{Ptr{Ptr{Cchar}}}, Csize_t), elems, length)
end

"""
    SoapySDRKwargs_set(args, key, val)

Set a key/value pair in a kwargs structure.
\\post
If the key exists, the existing entry will be modified;
otherwise a new entry will be appended to args.
On error, the elements of args will not be modified,
and args is guaranteed to be in a good state.
\\return 0 for success, otherwise allocation error
"""
function SoapySDRKwargs_set(args, key, val)
    ccall((:SoapySDRKwargs_set, soapysdr), Cint, (Ptr{SoapySDRKwargs}, Ptr{Cchar}, Ptr{Cchar}), args, key, val)
end

"""
    SoapySDRKwargs_get(args, key)

Get a value given a key in a kwargs structure.
\\return the string or NULL if not found
"""
function SoapySDRKwargs_get(args, key)
    ccall((:SoapySDRKwargs_get, soapysdr), Ptr{Cchar}, (Ptr{SoapySDRKwargs}, Ptr{Cchar}), args, key)
end

"""
    SoapySDRKwargs_clear(args)

Clear the contents of a kwargs structure.
This frees all the underlying memory and clears the members.
"""
function SoapySDRKwargs_clear(args)
    ccall((:SoapySDRKwargs_clear, soapysdr), Cvoid, (Ptr{SoapySDRKwargs},), args)
end

"""
    SoapySDRKwargsList_clear(args, length)

Clear a list of kwargs structures.
This frees all the underlying memory and clears the members.
"""
function SoapySDRKwargsList_clear(args, length)
    ccall((:SoapySDRKwargsList_clear, soapysdr), Cvoid, (Ptr{SoapySDRKwargs}, Csize_t), args, length)
end

"""
    SoapySDRArgInfo_clear(info)

Clear the contents of a argument info structure.
This frees all the underlying memory and clears the members.
"""
function SoapySDRArgInfo_clear(info)
    ccall((:SoapySDRArgInfo_clear, soapysdr), Cvoid, (Ptr{SoapySDRArgInfo},), info)
end

"""
    SoapySDRArgInfoList_clear(info, length)

Clear a list of argument info structures.
This frees all the underlying memory and clears the members.
"""
function SoapySDRArgInfoList_clear(info, length)
    ccall((:SoapySDRArgInfoList_clear, soapysdr), Cvoid, (Ptr{SoapySDRArgInfo}, Csize_t), info, length)
end

"""
    SoapySDR_getAPIVersion()

Get the SoapySDR library API version as a string.
The format of the version string is <b>major.minor.increment</b>,
where the digits are taken directly from <b>SOAPY_SDR_API_VERSION</b>.
"""
function SoapySDR_getAPIVersion()
    ccall((:SoapySDR_getAPIVersion, soapysdr), Ptr{Cchar}, ())
end

"""
    SoapySDR_getABIVersion()

Get the ABI version string that the library was built against.
A client can compare <b>SOAPY_SDR_ABI_VERSION</b> to getABIVersion()
to check for ABI incompatibility before using the library.
If the values are not equal then the client code was
compiled against a different ABI than the library.
"""
function SoapySDR_getABIVersion()
    ccall((:SoapySDR_getABIVersion, soapysdr), Ptr{Cchar}, ())
end

"""
    SoapySDR_getLibVersion()

Get the library version and build information string.
The format of the version string is <b>major.minor.patch-buildInfo</b>.
This function is commonly used to identify the software back-end
to the user for command-line utilities and graphical applications.
"""
function SoapySDR_getLibVersion()
    ccall((:SoapySDR_getLibVersion, soapysdr), Ptr{Cchar}, ())
end

# Skipping MacroDefinition: SOAPY_SDR_HELPER_DLL_IMPORT __attribute__ ( ( visibility ( "default" ) ) )

# Skipping MacroDefinition: SOAPY_SDR_HELPER_DLL_EXPORT __attribute__ ( ( visibility ( "default" ) ) )

# Skipping MacroDefinition: SOAPY_SDR_HELPER_DLL_LOCAL __attribute__ ( ( visibility ( "hidden" ) ) )

# Skipping MacroDefinition: SOAPY_SDR_EXTERN extern

const SOAPY_SDR_TX = 0

const SOAPY_SDR_RX = 1

const SOAPY_SDR_END_BURST = 1 << 1

const SOAPY_SDR_HAS_TIME = 1 << 2

const SOAPY_SDR_END_ABRUPT = 1 << 3

const SOAPY_SDR_ONE_PACKET = 1 << 4

const SOAPY_SDR_MORE_FRAGMENTS = 1 << 5

const SOAPY_SDR_WAIT_TRIGGER = 1 << 6

const SOAPY_SDR_TIMEOUT = -1

const SOAPY_SDR_STREAM_ERROR = -2

const SOAPY_SDR_CORRUPTION = -3

const SOAPY_SDR_OVERFLOW = -4

const SOAPY_SDR_NOT_SUPPORTED = -5

const SOAPY_SDR_TIME_ERROR = -6

const SOAPY_SDR_UNDERFLOW = -7

const SOAPY_SDR_CF64 = "CF64"

const SOAPY_SDR_CF32 = "CF32"

const SOAPY_SDR_CS32 = "CS32"

const SOAPY_SDR_CU32 = "CU32"

const SOAPY_SDR_CS16 = "CS16"

const SOAPY_SDR_CU16 = "CU16"

const SOAPY_SDR_CS12 = "CS12"

const SOAPY_SDR_CU12 = "CU12"

const SOAPY_SDR_CS8 = "CS8"

const SOAPY_SDR_CU8 = "CU8"

const SOAPY_SDR_CS4 = "CS4"

const SOAPY_SDR_CU4 = "CU4"

const SOAPY_SDR_F64 = "F64"

const SOAPY_SDR_F32 = "F32"

const SOAPY_SDR_S32 = "S32"

const SOAPY_SDR_U32 = "U32"

const SOAPY_SDR_S16 = "S16"

const SOAPY_SDR_U16 = "U16"

const SOAPY_SDR_S8 = "S8"

const SOAPY_SDR_U8 = "U8"

const SOAPY_SDR_SSI = SOAPY_SDR_SSI

const SOAPY_SDR_TRUE = "true"

const SOAPY_SDR_FALSE = "false"

const SOAPY_SDR_API_VERSION = 0x00080000

const SOAPY_SDR_ABI_VERSION = "0.8"

