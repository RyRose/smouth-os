_BASE_KERNEL_DEPENDENCIES = [
    "//kernel/cxx:abi",
]

def kernel_library(**kwargs):
    if "deps" in kwargs:
        kwargs["deps"] += _BASE_KERNEL_DEPENDENCIES
    else:
        kwargs["deps"] = _BASE_KERNEL_DEPENDENCIES
    native.cc_library(
        **kwargs
    )
