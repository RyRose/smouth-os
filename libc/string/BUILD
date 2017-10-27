
cc_library(
  name = "string",
  deps = [
    ":mem",
    ":str"
  ],
  visibility = ["//visibility:public"],
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
    ]
)
