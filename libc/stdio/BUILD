package(default_visibility = ["//libc:__subpackages__"])

cc_library(
    name = "stdio",
    visibility = ["//visibility:public"],
    deps = [
        ":printf",
        ":putchar",
        ":puts",
    ],
)

cc_library(
    name = "printf",
    srcs = [
        "printf.cc",
    ],
    hdrs = [
        "printf.h",
    ],
    deps = [
        ":putchar",
        "//libc/stdlib:arithmetic",
        "//libc/string:str",
    ],
)

cc_library(
    name = "putchar",
    srcs = [
        "putchar.cc",
    ],
    hdrs = [
        "putchar.h",
    ],
    deps = [
        "//kernel/arch:tty",
    ],
)

cc_library(
    name = "puts",
    srcs = [
        "puts.cc",
    ],
    hdrs = [
        "puts.h",
    ],
    deps = [
        ":printf",
    ],
)

cc_test(
    name = "printf_test",
    size = "small",
    srcs = [
        "printf.cc",
        "printf_test.cc",
    ],
    deps = [
        ":printf",
        "@googletest//:gtest",
    ],
)
