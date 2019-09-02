load("//kernel:templates.bzl", "kernel_library")

package(default_visibility = ["//kernel/arch/i386:__subpackages__"])

kernel_library(
    name = "gdt",
    srcs = [
        "gdt.cc",
    ],
    hdrs = [
        "gdt.h",
    ],
)

cc_test(
    name = "gdt_test",
    size = "small",
    srcs = [
        "gdt_test.cc",
    ],
    deps = [
        ":gdt",
        "@googletest//:gtest",
    ],
)

kernel_library(
    name = "gdt_installer",
    srcs = [
        "gdt_flush.S",
        "gdt_installer.cc",
    ],
    hdrs = [
        "gdt_installer.h",
    ],
    tags = [
        "manual",
    ],
    deps = [
        ":gdt",
    ],
)
