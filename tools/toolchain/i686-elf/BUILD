package(default_visibility = ["//visibility:public"])

filegroup(
    name = "i686-elf-gcc",
    srcs = [
        "gcc",
        "@toolchain-i686-elf//:gcc",
    ],
)

filegroup(
    name = "i686-elf-g++",
    srcs = [
        "g++",
        "@toolchain-i686-elf//:g++",
    ],
)

filegroup(
    name = "i686-elf-ar",
    srcs = [
        "ar",
        "@toolchain-i686-elf//:ar",
    ],
)

filegroup(
    name = "i686-elf-ld",
    srcs = [
        "ld",
        "@toolchain-i686-elf//:ld",
    ],
)

filegroup(
    name = "i686-elf-nm",
    srcs = [
        "nm",
        "@toolchain-i686-elf//:nm",
    ],
)

filegroup(
    name = "i686-elf-objcopy",
    srcs = [
        "objcopy",
        "@toolchain-i686-elf//:objcopy",
    ],
)

filegroup(
    name = "i686-elf-objdump",
    srcs = [
        "objdump",
        "@toolchain-i686-elf//:objdump",
    ],
)

filegroup(
    name = "i686-elf-strip",
    srcs = [
        "strip",
        "@toolchain-i686-elf//:strip",
    ],
)

filegroup(
    name = "i686-elf-as",
    srcs = [
        "as",
        "@toolchain-i686-elf//:as",
    ],
)

filegroup(
    name = "i686-elf-compiler_components",
    srcs = [
        ":i686-elf-ar",
        ":i686-elf-as",
        ":i686-elf-g++",
        ":i686-elf-gcc",
        ":i686-elf-ld",
        ":i686-elf-nm",
        ":i686-elf-objcopy",
        ":i686-elf-objdump",
        ":i686-elf-strip",
    ],
)

filegroup(
    name = "i686-elf-all_files",
    srcs = [
        ":i686-elf-compiler_components",
        "@toolchain-i686-elf//:compiler_pieces",
    ],
)

filegroup(
    name = "i686-elf-linker_files",
    srcs = [
        ":i686-elf-ar",
        ":i686-elf-g++",
        ":i686-elf-gcc",
        ":i686-elf-ld",
        "@toolchain-i686-elf//:compiler_pieces",
    ],
)

filegroup(
    name = "i686-elf-compiler_files",
    srcs = [
        ":i686-elf-as",
        ":i686-elf-g++",
        ":i686-elf-gcc",
        ":i686-elf-ld",
    ],
)

filegroup(
    name = "empty",
    srcs = [],
)

cc_toolchain(
    name = "cc-compiler-i686-elf",
    all_files = ":i686-elf-all_files",
    compiler_files = ":i686-elf-compiler_files",
    cpu = "i686-elf",
    dwp_files = ":empty",
    dynamic_runtime_libs = [":empty"],
    linker_files = ":i686-elf-linker_files",
    objcopy_files = ":i686-elf-objcopy",
    static_runtime_libs = [":empty"],
    strip_files = ":i686-elf-strip",
    supports_param_files = True,
)
