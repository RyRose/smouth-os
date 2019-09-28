def arch_library(name, hdrs = None, **kwargs):
    if hdrs == None:
        hdrs = [name + ".h"]
    native.cc_library(
        name = name,
        hdrs = hdrs,
        deps = select({
            "//tools/toolchain:i386": ["//kernel/arch/i386/" + name],
            "//conditions:default": [],
        }),
        **kwargs
    )

def arch_file(name, **kwargs):
    native.filegroup(
        name = name,
        srcs = select({
            "//tools/toolchain:i386": ["//kernel/arch/i386:" + name],
            "//conditions:default": [],
        }),
        **kwargs
    )
