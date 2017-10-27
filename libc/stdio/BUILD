cc_library(
  name = "stdio",
  deps = [
    ":printf",
    ":putchar",
    ":puts"
  ],
  visibility = ["//visibility:public"],
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
    ]
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
      "//kernel/arch:tty"
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
    srcs = [
        "printf_test.cc",
        "printf.cc"
    ],
    deps = [
      "@com_google_googletest//:gtest",
      ":printf",
    ]
)
