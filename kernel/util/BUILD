package(default_visibility = ["//visibility:public"])

cc_library(
    name = "status",
    srcs = [
        "status.cc",
    ],
    hdrs = [
        "status.h",
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
        "//libc/stdio"
    ]
)
