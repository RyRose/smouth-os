def arch_library(name, **kwargs):
    native.cc_library(
        name = name,
        hdrs = kwargs.pop("hdrs", [name + ".h"]),
        deps = kwargs.pop("deps", []) + select({
            "//tools/toolchain:i386": ["//kernel/arch/i386:" + name],
            "//conditions:default": ["//kernel/arch/common:empty"],
        }),
        **kwargs
    )
