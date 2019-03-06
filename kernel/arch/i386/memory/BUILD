package(default_visibility = ["//kernel/arch/i386:__subpackages__"])

load("//kernel:templates.bzl", "kernel_library")

kernel_library(
    name = "memory",
    srcs = [
        "memory.cc",
    ],
    hdrs = [
        "//kernel/arch:memory.h",
    ],
    visibility = ["//kernel/arch:__pkg__"],
    deps = [
        "//kernel/arch/i386/boot:mmap_manager",
        "//kernel/arch/i386/boot:multiboot",
        "//libc/stdio",
    ],
)
