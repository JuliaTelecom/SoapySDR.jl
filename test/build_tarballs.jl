# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyLoopback"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaTelecom/SoapyLoopback.git", "97b07744d83f21e031c1e7a7263d8b6c0567b684")
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    BuildDependency(PackageSpec(name="soapysdr_jll", uuid="343a40d9-ed99-5d34-8b56-649aaa4ecee6"))
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyLoopback #if GitSource
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Debug \
      ..
make -j${nproc}
make install
if [[ "${target}" == *-apple-* ]]; then
    # TODO: Rename
    mv ${libdir}/SoapySDR/modules0.8/libsoapyloopback.so  ${libdir}/SoapySDR/modules0.8/libsoapyloopback.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = HostPlatform() #filter!(p -> arch(p) != "armv6l", supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libsoapyloopback", :librtlsdrSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc7 constraint from boost
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
