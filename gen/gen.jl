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
push!(args, "-I$include_dir")

headers = [joinpath(include_dir, "SoapySDR", header) for header in readdir(joinpath(include_dir, "SoapySDR")) if endswith(header, ".h")]
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(clang_dir, args)

filter!(s -> basename(s) != "Logger.h", headers) # ignore Logger as it hangs the build

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)