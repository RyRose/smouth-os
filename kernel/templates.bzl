def kernel_binary(name, **kwargs):
    """A wrapped cc_binary to be booted by a computer.

    Args:
      name: The name of the rule.
      **kwargs: Additional arguments forwarded to the cc_binary rule.
    """

    # CRT (C RunTime) files are the necessary startup routines for C binaries. Since
    # there is no C runtime environment for this operating system, we disable most of
    # it with the "-nostdlib" and "-nostartfiles" flag but copy crtbegin.o and
    # crtend.o since they work in any environment and they're required. See
    # https://wiki.osdev.org/Calling_Global_Constructors for more details.
    crt_files = "%s_crt_files" % name
    native.genrule(
        name = crt_files,
        visibility = ["//visibility:private"],
        outs = [
            "crtfiles/%s/crtbegin.o" % name,
            "crtfiles/%s/crtend.o" % name,
        ],
        # For the definition of CC and CC_FLAGS make variables.
        toolchains = [
            "@bazel_tools//tools/cpp:current_cc_toolchain",
            "@bazel_tools//tools/cpp:cc_flags",
        ],
        cmd = (
            "for out in $(OUTS); do " +
            "outname=$$(basename $$out); " +
            "f=$$($(CC) $(CC_FLAGS) -print-file-name=$$outname); " +
            "mkdir -p $$(dirname $$out); " +
            "cp $$f $$out; " +
            "done;"
        ),
        tags = ["manual"],
    )
    crt_library = "%s_crt" % name
    native.cc_library(
        name = crt_library,
        visibility = ["//visibility:private"],
        srcs = [
            ":%s" % crt_files,
        ],
        linkstatic = 1,
        tags = ["manual"],
    )

    # Add CRT files, linker file, and dependency on //kernel/arch:boot so
    # the main is called.
    deps = kwargs.pop("deps", [])
    deps.extend([
        ":%s" % crt_library,
        "//kernel/arch:boot",
    ])
    deps = depset(deps).to_list()  # de-dupe dependencies
    deps += select({
        "//tools/toolchain:i386": [
            "//kernel/arch/i386:linker.ld",
        ],
    })

    # Use arch-specific linker file.
    linkopts = kwargs.pop("linkopts", [])
    linkopts += select({
        "//tools/toolchain:i386": [
            "-T $(location //kernel/arch/i386:linker.ld)",
        ],
    })

    tags = kwargs.pop("tags", [])
    tags.append("manual")  # Add `manual` so it's ignored with ... expansion.
    tags = depset(tags).to_list()  # de-dupe tags

    native.cc_binary(
        name = name,
        deps = deps,
        linkopts = linkopts,
        tags = tags,
        **kwargs
    )

def kernel_library(abi = True, new = True, **kwargs):
    """A wrapped cc_library to be used by the kernel.

    Args:
      abi: Whether or not to include C++ ABI-related functions.
      new: Whether or not to include support for C++ new/delete that integrates
           with the kernel memory allocator.
    """
    deps = kwargs.pop("deps", [])
    if abi:
        deps += select({
            "//tools/toolchain:local": [],
            "//conditions:default": ["//kernel/cxx:abi"],
        })
    if new:
        deps += select({
            "//tools/toolchain:local": [],
            "//conditions:default": ["//kernel/cxx:new"],
        })
    native.cc_library(
        deps = deps,
        **kwargs
    )
