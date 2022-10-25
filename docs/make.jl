using SoapySDR
using Documenter

DocMeta.setdocmeta!(SoapySDR, :DocTestSetup, :(using SoapySDR); recursive = true)

makedocs(;
    modules = [SoapySDR],
    authors = "JuliaTelecom and contributors",
    repo = "https://github.com/JuliaTelecom/SoapySDR.jl/blob/{commit}{path}#{line}",
    sitename = "SoapySDR.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://JuliaTelecom.github.io/SoapySDR.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "Loading Drivers" => "drivers.md",
        "High Level API" => "highlevel.md",
        "Low Level API" => "lowlevel.md",
        "Troubleshooting" => "troubleshooting.md",
    ],
)

deploydocs(; repo = "github.com/JuliaTelecom/SoapySDR.jl", devbranch = "main")
