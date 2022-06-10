# SoapySDR Binding generation via Clang.jl

Instructions:

```
] activate .
] instantiate
] up
include("gen.jl")
```

This generates the files in `src/lowlevel/<header>.h.jl`. Files in lowlevel without this extension are maintained by hand.