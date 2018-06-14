package(default_visibility = ["//kernel:__subpackages__"])

cc_library(
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

cc_library(
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

cc_library(
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
