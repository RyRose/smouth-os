load("//kernel:templates.bzl", "kernel_library")

def arch_library(name, visibility = None):
    kernel_library(
        name = name,
        hdrs = [name + ".h"],
        visibility = visibility,
        deps = select({
            "//tools/toolchain:i386": ["//kernel/arch/i386/" + name],
            "//conditions:default": [],
        }),
    )
