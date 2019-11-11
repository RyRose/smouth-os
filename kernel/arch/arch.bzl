load("//kernel:templates.bzl", "kernel_library")

def arch_library(name, **kwargs):
    hdrs = kwargs.pop("hdrs", [name + ".h"])
    deps = kwargs.pop("deps", [])
    deps += select({
        "//tools/toolchain:i386": ["//kernel/arch/i386/" + name],
        "//conditions:default": ["//kernel/arch/mock/" + name],
    })
    kernel_library(
        name = name,
        hdrs = hdrs,
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
