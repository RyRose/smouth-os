def arch_library(name, **kwargs):
    deps = kwargs.pop("deps", [])
    deps += select({
        "//tools/toolchain:i386": ["//kernel/arch/i386:" + name],
        "//conditions:default": ["//kernel/arch/mock:" + name],
    })
    native.cc_library(
        name = name,
        hdrs = kwargs.pop("hdrs", [name + ".h"]),
        deps = deps,
        **kwargs
    )

def arch_file(name, **kwargs):
    native.filegroup(
        name = name,
        srcs = select({
            "//tools/toolchain:i386": ["//kernel/arch/i386:" + name],
            "//conditions:default": ["//kernel/arch/mock:" + name],
        }),
        **kwargs
    )
