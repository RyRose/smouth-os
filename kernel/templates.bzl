_ABI_DEP = "//kernel/cxx:abi"

_NEW_DEP = "//kernel/cxx:new"

def kernel_library(abi = True, new = True, **kwargs):
    deps = []
    if abi:
        deps += [_ABI_DEP]
    if new:
        deps += [_NEW_DEP]

    if "deps" in kwargs:
        kwargs["deps"] += deps
    else:
        kwargs["deps"] = deps
    native.cc_library(
        **kwargs
    )
