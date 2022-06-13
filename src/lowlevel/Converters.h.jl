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

