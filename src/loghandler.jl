"""
Log handler to forward Soapy logs to Julia logs.
"""
function logger_soapy2jl(level, cmessage)
    #SOAPY_SDR_FATAL    = 1 #!< A fatal error. The application will most likely terminate. This is the highest priority.
    #SOAPY_SDR_CRITICAL = 2 #!< A critical error. The application might not be able to continue running successfully.
    #SOAPY_SDR_ERROR    = 3 #!< An error. An operation did not complete successfully, but the application as a whole is not affected.
    #SOAPY_SDR_WARNING  = 4 #!< A warning. An operation completed with an unexpected result.
    #SOAPY_SDR_NOTICE   = 5 #!< A notice, which is an information with just a higher priority.
    #SOAPY_SDR_INFO     = 6 #!< An informational message, usually denoting the successful completion of an operation.
    #SOAPY_SDR_DEBUG    = 7 #!< A debugging message.
    #SOAPY_SDR_TRACE    = 8 #!< A tracing message. This is the lowest priority.
    #SOAPY_SDR_SSI      = 9 #!< Streaming status indicators such as "U" (underflow) and "O" (overflow).

    message = unsafe_string(cmessage)
    level = SoapySDRLogLevel(level)
    if level in (SOAPY_SDR_FATAL, SOAPY_SDR_CRITICAL, SOAPY_SDR_ERROR)
        @error message
    elseif level == SOAPY_SDR_WARNING
        @warn message
    elseif level in (SOAPY_SDR_NOTICE, SOAPY_SDR_INFO)
        @info message
    elseif level in (SOAPY_SDR_DEBUG, SOAPY_SDR_TRACE, SOAPY_SDR_SSI)
        @debug message
    else
        println("SoapySDR_jll: ", message)
    end
end

"""
Initialize the log handler to convert Soapy logs to Julia logs.

This should be called once at the start of a script before doing work.
"""
function register_log_handler()
    julia_log_handler = @cfunction(logger_soapy2jl, Cvoid, (Cint, Cstring))
    SoapySDR_registerLogHandler(julia_log_handler)
end
