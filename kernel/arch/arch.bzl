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

def arch_file(name, **kwargs):
    native.filegroup(
        name = name,
        srcs = kwargs.pop("srcs", []) + select({
            "//tools/toolchain:i386": ["//kernel/arch/i386:" + name],
            "//conditions:default": ["//kernel/arch/common:empty.h"],
        }),
        **kwargs
    )
