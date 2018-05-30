package(default_visibility = ["//libc:__subpackages__"])

cc_library(
    name = "string",
    visibility = ["//visibility:public"],
    deps = [
        ":mem",
        ":str",
    ],
)

cc_library(
    name = "mem",
    srcs = glob(["mem*.cc"]),
    hdrs = [
        "mem.h",
    ],
)

cc_library(
    name = "str",
    srcs = glob(["str*.cc"]),
    hdrs = [
        "str.h",
    ],
)
