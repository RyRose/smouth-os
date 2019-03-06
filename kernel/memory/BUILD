package(default_visibility = ["//kernel:__subpackages__"])

load("//kernel:templates.bzl", "kernel_library")

kernel_library(
    name = "memory",
    srcs = [
        "memory.cc",
    ],
    hdrs = [
        "memory.h",
    ],
    new = False,
    deps = [
        "//kernel/arch:memory",
        "//libc/string",
    ],
)

cc_test(
    name = "memory_test",
    size = "small",
    srcs = [
        "memory_test.cc",
    ],
    deps = [
        ":memory",
        "@com_google_googletest//:gtest",
    ],
)
