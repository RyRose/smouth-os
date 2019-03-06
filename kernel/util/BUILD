load("//kernel:templates.bzl", "kernel_library")
package(default_visibility = ["//kernel:__subpackages__"])

kernel_library(
    name = "status",
    srcs = [
        "status.cc",
    ],
    hdrs = [
        "status.h",
    ],
    deps = [
        ":either",
    ],
)

cc_test(
    name = "status_test",
    size = "small",
    srcs = [
        "status_test.cc",
    ],
    deps = [
        ":status",
        "@com_google_googletest//:gtest",
    ],
)

kernel_library(
    name = "panic",
    srcs = [
        "panic.cc",
    ],
    hdrs = [
        "panic.h",
    ],
    deps = [
        "//libc/stdio",
    ],
)

kernel_library(
    name = "either",
    hdrs = [
        "either.h",
    ],
)

cc_test(
    name = "either_test",
    size = "small",
    srcs = [
        "either_test.cc",
    ],
    deps = [
        ":either",
        "@com_google_googletest//:gtest",
    ],
)
