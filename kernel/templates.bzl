load("//tools/go:builddefs.bzl", "qemu_binaries", "qemu_test")

def crt_file(name, filename, **kwargs):
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
        tags = kwargs.pop("tags", []) + ["arch-only"],
        **kwargs
    )

def kernel_binary(name, **kwargs):
    """A wrapped cc_binary to be booted by a computer.

    Args:
      name: The name of the rule.
      **kwargs: Additional arguments forwarded to the cc_binary rule.
    """

    crtbegin = "%s_crtbegin" % name
    crt_file(crtbegin, "crtbegin.o")

    crtend_file = "%s_crtend_file" % name
    crt_file(crtend_file, "crtend.o")
    crtend = "%s_crtend" % name
    native.cc_library(
        name = crtend,
        alwayslink = True,
        srcs = [crtend_file],
        tags = ["arch-only"],
    )

    crtn = "%s_crtn" % name
    native.cc_library(
        name = crtn,
        alwayslink = True,
        srcs = ["//kernel/arch:crtn"],
        tags = ["arch-only"],
    )

    # Please note the srcs/deps are specifically ordered such that crti/crtbegin/crtend/crtn are as follows:
    #
    # START -> crti -> crtbegin -> ... srcs/deps ... -> crtend -> crtn -> END
    #
    # This ensures we adhere to one of the System V ABI's requirements.
    #
    native.cc_binary(
        name = name,
        srcs = ["//kernel/arch:crti", crtbegin] + kwargs.pop("srcs", []),
        deps = kwargs.pop("deps", []) + ["//cxx", "//kernel/arch:boot", crtend, crtn],
        additional_linker_inputs = kwargs.pop("additional_linker_inputs", []) + ["//kernel/arch:linker.ld"],
        linkopts = kwargs.pop("linkopts", []) + ["-T $(location //kernel/arch:linker.ld)"],
        tags = kwargs.pop("tags", []) + ["arch-only", "i386"],
        **kwargs
    )

def kernel_test(name, timeout = "short", binary_copts = [], **kwargs):
    """A wrapped qemu_test that boots a kernel test binary and verifies it passes."""

    kernel = "%s_kernel_binary" % name
    kernel_binary(
        name = kernel,
        srcs = kwargs.pop("srcs", []),
        deps = kwargs.pop("deps", []),
        copts = binary_copts,
    )

    qemu_binaries(
        name = name + "-",
        kernel = kernel,
    )

    qemu_test(
        name = name,
        kernel = kernel,
        timeout = timeout,
        tags = kwargs.pop("tags", []) + ["arch-only", "i386"],
        **kwargs
    )
