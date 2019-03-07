_ABI_DEP = "//kernel/cxx:abi"

_NEW_DEP = "//kernel/cxx:new"

def kernel_library(abi = True, new = True, **kwargs):
    deps = []
    if abi:
        deps += select({
            "//tools/toolchain:local": [],
            "//conditions:default": [_ABI_DEP],
        })
    if new:
        deps += select({
            "//tools/toolchain:local": [],
            "//conditions:default": [_NEW_DEP],
        })

    if "deps" in kwargs:
        kwargs["deps"] += deps
    else:
        kwargs["deps"] = deps
    native.cc_library(
        **kwargs
    )
