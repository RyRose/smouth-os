def arch_library(name, visibility = None):
    native.cc_library(
        name = name,
        hdrs = [name + ".h"],
        deps = select({
            "//tools/toolchain:i386": ["//kernel/arch/i386/" + name],
            "//conditions:default": [],
        }),
        visibility = visibility,
    )
