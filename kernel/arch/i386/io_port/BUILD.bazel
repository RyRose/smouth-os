load("//kernel:templates.bzl", "kernel_library")

package(default_visibility = ["//kernel/arch/i386:__subpackages__"])

kernel_library(
    name = "io_port",
    srcs = [
        "io_port.cc",
    ],
    hdrs = [
        "//kernel/arch:io_port.h",
    ],
    visibility = ["//kernel/arch:__pkg__"],
)
