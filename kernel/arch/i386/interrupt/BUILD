package(default_visibility = ["//kernel/arch/i386:__subpackages__"])

cc_library(
    name = "descriptor",
    hdrs = [
        "descriptor.h",
    ],
)

cc_test(
    name = "descriptor_test",
    size = "small",
    srcs = [
        "descriptor_test.cc",
    ],
    deps = [
        ":descriptor",
        "@com_google_googletest//:gtest",
    ],
)

cc_library(
    name = "table",
    srcs = [
        "table.cc",
    ],
    hdrs = [
        "table.h",
    ],
    deps = [
        ":descriptor",
        "//kernel/util:status",
    ],
)

cc_test(
    name = "table_test",
    size = "small",
    srcs = [
        "table_test.cc",
    ],
    deps = [
        ":descriptor",
        ":table",
        "@com_google_googletest//:gtest",
    ],
)
