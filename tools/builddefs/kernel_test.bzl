load("//tools/builddefs:kernel_binary.bzl", "kernel_binary")
load("//tools/builddefs:qemu_binaries.bzl", "qemu_binaries")
load("//tools/builddefs:qemu_test.bzl", "qemu_test")

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
