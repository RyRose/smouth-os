load("//tools/builddefs:crt_file.bzl", "crt_file")

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
