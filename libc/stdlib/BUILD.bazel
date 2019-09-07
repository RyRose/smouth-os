package(default_visibility = ["//libc:__subpackages__"])

cc_library(
    name = "stdlib",
    visibility = ["//visibility:public"],
    deps = [
        ":abort",
        ":arithmetic",
    ],
)

cc_library(
    name = "abort",
    srcs = [
        "abort.cc",
    ],
    hdrs = [
        "abort.h",
    ],
)

cc_library(
    name = "arithmetic",
    srcs = [
        "arithmetic.cc",
    ],
    hdrs = [
        "arithmetic.h",
    ],
)
