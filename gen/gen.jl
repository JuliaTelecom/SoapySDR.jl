#! /usr/bin/env julia

using soapysdr_jll

using Clang.Generators

include_dir = joinpath(soapysdr_jll.artifact_dir, "include") |> normpath
clang_dir = joinpath(include_dir, "clang-c")

options = load_options(joinpath(@__DIR__, "generator.toml"))

@show options

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()
push!(args, "-I$include_dir")
@show args

headers = [joinpath(include_dir, "SoapySDR", header) for header in readdir(joinpath(include_dir, "SoapySDR")) if endswith(header, ".h")]
@show headers
@show basename.(headers)
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(clang_dir, args)

filter!(s -> basename(s) ∉ ["Config.h"], headers) # Deivce is hand-wrapped and COnfig is not needed

# A few macros that don't translate well, and not applicable
options["general"]["output_ignorelist"] = ["SOAPY_SDR_API", "SOAPY_SDR_LOCAL"]

# create context
@show options
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
