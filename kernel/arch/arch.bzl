def arch_library(name, **kwargs):
    deps = kwargs.pop("deps", [])
    deps += select({
        "//tools/toolchain:i386": ["//kernel/arch/i386:" + name],
    })

    tags = kwargs.pop("tags", [])
    tags.append("arch-only")
    tags = depset(tags).to_list()  # de-dupe

    native.cc_library(
        name = name,
        hdrs = kwargs.pop("hdrs", [name + ".h"]),
        deps = deps,
        tags = tags,
        **kwargs
    )

def arch_file(name, **kwargs):
    tags = kwargs.pop("tags", [])
    tags.append("arch-only")
    tags = depset(tags).to_list()  # de-dupe

    native.filegroup(
        name = name,
        tags = tags,
        srcs = select({
            "//tools/toolchain:i386": ["//kernel/arch/i386:" + name],
        }),
        **kwargs
    )
