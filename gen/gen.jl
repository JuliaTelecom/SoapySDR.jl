#! /usr/bin/env julia

using Pkg

using soapysdr_jll

using Clang.Generators

include_dir = joinpath(soapysdr_jll.artifact_dir, "include") |> normpath
clang_dir = joinpath(include_dir, "clang-c")

options = load_options(joinpath(@__DIR__, "generator.toml"))

@show options

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()
push!(args, "-isystem$include_dir")
@show args

headers = [joinpath(include_dir, "SoapySDR", header) for header in readdir(joinpath(include_dir, "SoapySDR")) if endswith(header, ".h")]
@show headers
@show basename.(headers)
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(clang_dir, args)

filter!(s -> basename(s) ∉ ["Logger.h", "Config.h"], headers) # ignore Logger as it hangs the build

# A few macros that don't translate well, and not applicable
#options["general"]["output_ignorelist"] = ["SOAPY_SDR_API", "SOAPY_SDR_LOCAL"]

for header in headers

    options["general"]["output_file_path"] = joinpath("../src/lowlevel", basename(header)*".jl")
    # create context
    @show options
    ctx = create_context(String[header], args, options)

    # run generator
    build!(ctx)
end