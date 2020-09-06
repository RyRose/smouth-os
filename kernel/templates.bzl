def crt_file(name, filename, visibility = []):
    """A CRT (C RunTime) file provided by the compiler used for the startup routines.

       CRT (C RunTime) files are the necessary startup routines for C binaries. Since
       there is no C runtime environment for this operating system, we disable most of
       it with the "-nostdlib" and "-nostartfiles" flag but copy crtbegin.o and
       crtend.o since they work in any environment and they're required. See
       https://wiki.osdev.org/Calling_Global_Constructors for more details.

       Args:
         name: The name of the rule capturing the CRT file.
         filename: The CRT file to request from the compiler.
    """
    native.genrule(
        name = name,
        visibility = visibility,
        outs = [
            "crtfiles/%s/%s" % (name, filename),
        ],
        toolchains = [
            # Defines CC make variable.
            "@bazel_tools//tools/cpp:current_cc_toolchain",
            # Defines CC_FLAGS make variable.
            "@bazel_tools//tools/cpp:cc_flags",
        ],
        cmd = (
            "mkdir -p $$(dirname $@); " +
            "cp $$($(CC) $(CC_FLAGS) -print-file-name=$$(basename $@)) $@;"
        ),
        tags = ["manual"],
    )

def kernel_binary(name, **kwargs):
    """A wrapped cc_binary to be booted by a computer.

    Args:
      name: The name of the rule.
      **kwargs: Additional arguments forwarded to the cc_binary rule.
    """

    crtbegin = "%s_crtbegin" % name
    crt_file(crtbegin, "crtbegin.o", visibility = ["//visibility:private"])

    crtend_file = "%s_crtend_file" % name
    crt_file(crtend_file, "crtend.o", visibility = ["//visibility:private"])
    crtend = "%s_crtend" % name
    native.cc_library(
        name = crtend,
        alwayslink = True,
        tags = ["manual"],
        srcs = [crtend_file],
    )

    crtn = "%s_crtn" % name
    native.cc_library(
        name = crtn,
        alwayslink = True,
        tags = ["manual"],
        srcs = ["//kernel/arch:crtn"],
    )

    deps = kwargs.pop("deps", [])
    deps.append("//cxx")
    deps = depset(deps).to_list()  # de-dupe

    # Add arch-specific linker file as input and use it.
    additional_linker_inputs = kwargs.pop("additional_linker_inputs", [])
    additional_linker_inputs.append("//kernel/arch:linker.ld")
    additional_linker_inputs = depset(additional_linker_inputs).to_list()  # de-dupe
    linkopts = kwargs.pop("linkopts", [])
    linkopts.append("-T $(location //kernel/arch:linker.ld)")
    linkopts = depset(linkopts).to_list()  # de-dupe

    # # Add `manual` so it's ignored with ... expansion.
    tags = kwargs.pop("tags", [])
    tags.append("manual")
    tags = depset(tags).to_list()  # de-dupe

    # crtbegin, crti, crtend, and crtn are specifically ordered such that the
    # global constructors and destructors are called correctly. crti/crtbegin
    # should be swapped and crtend/crtn should be swapped but for some reason
    # it works.
    # TODO(RyRose): Why does this work?
    native.cc_binary(
        name = name,
        srcs = [crtbegin, "//kernel/arch:crti"] + kwargs.pop("srcs", []),
        deps = deps + [crtend, crtn],
        additional_linker_inputs = additional_linker_inputs,
        tags = tags,
        linkopts = linkopts,
        **kwargs
    )
