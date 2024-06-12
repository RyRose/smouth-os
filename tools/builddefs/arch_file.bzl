def arch_file(name, **kwargs):
    native.filegroup(
        name = name,
        srcs = kwargs.pop("srcs", []) + select({
            "//tools/toolchain:i386": ["//kernel/arch/i386:" + name],
            "//conditions:default": ["//kernel/arch/common:empty.h"],
        }),
        **kwargs
    )
