package(default_visibility = ["//kernel/arch/i386:__subpackages__"])

cc_library(
    name = "tty",
    srcs = [
        "tty.cc",
    ],
    hdrs = [
        "vga.h",
        "//kernel/arch:tty.h",
    ],
    tags = [
        "manual",
    ],
    visibility = ["//kernel/arch:__pkg__"],
    deps = [
        "//libc/string",
    ],
)
