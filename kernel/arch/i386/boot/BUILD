package(default_visibility = ["//kernel/arch/i386:__subpackages__"])

cc_library(
    name = "boot",
    srcs = [
        "boot.S",
        "crti.S",
        "crtn.S",
        "pre_kernel_main.cc",
    ],
    tags = [
        "manual",
    ],
    visibility = ["//kernel/arch:__pkg__"],
    deps = [
        ":gdt_installer",
        ":mmap_manager",
        "//kernel/arch/i386/instructions",
        "//kernel/arch/i386/interrupt:descriptor",
        "//kernel/arch/i386/interrupt:table",
    ],
    alwayslink = True,
)

cc_library(
    name = "mmap_manager",
    srcs = [
        "mmap_manager.cc",
    ],
    hdrs = [
        "mmap_manager.h",
    ],
    deps = [
        ":multiboot",
    ],
)

cc_test(
    name = "mmap_manager_test",
    size = "small",
    srcs = [
        "mmap_manager_test.cc",
    ],
    deps = [
        ":mmap_manager",
        "@com_google_googletest//:gtest",
    ],
)

cc_library(
    name = "multiboot",
    hdrs = [
        "multiboot.h",
    ],
)

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
    ],
)
