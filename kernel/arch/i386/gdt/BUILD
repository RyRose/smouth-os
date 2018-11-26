package(default_visibility = ["//kernel/arch/i386:__subpackages__"])

cc_library(
    name = "gdt",
    srcs = [
        "gdt.cc",
    ],
    hdrs = [
        "gdt.h",
    ],
    deps = [
        "//kernel/cxx:abi",
    ],
)

cc_test(
    name = "gdt_test",
    size = "small",
    srcs = [
        "gdt_test.cc",
    ],
    deps = [
        ":gdt",
        "@com_google_googletest//:gtest",
    ],
)

cc_library(
    name = "gdt_installer",
    srcs = [
        "gdt_flush.S",
        "gdt_installer.cc",
    ],
    hdrs = [
        "gdt_installer.h",
    ],
    tags = [
        "manual",
    ],
    deps = [
        ":gdt",
        "//kernel/cxx:abi",
    ],
)
