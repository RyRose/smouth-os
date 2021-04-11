package(default_visibility = ["//visibility:public"])

filegroup(
    name = "gcc",
    srcs = glob(["bin/*-gcc"]),
)

filegroup(
    name = "g++",
    srcs = glob(["bin/*-g++"]),
)

filegroup(
    name = "ar",
    srcs = glob(["bin/*-ar"]),
)

filegroup(
    name = "as",
    srcs = glob(["bin/*-as"]),
)

filegroup(
    name = "ld",
    srcs = glob(["bin/*-ld"]),
)

filegroup(
    name = "nm",
    srcs = glob(["bin/*-nm"]),
)

filegroup(
    name = "objcopy",
    srcs = glob(["bin/*-objcopy"]),
)

filegroup(
    name = "objdump",
    srcs = glob(["bin/*-objdump"]),
)

filegroup(
    name = "strip",
    srcs = glob(["bin/*-strip"]),
)

filegroup(
    name = "compiler_pieces",
    srcs = glob([
        "libexec/**",
        "lib/gcc/**/**",
        "lib/gcc/**/**/include/*.h",
        "**/**",
    ]),
)
