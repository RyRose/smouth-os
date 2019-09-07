load(":toolchain_config.bzl", "toolchain_config")

package(default_visibility = ["//visibility:public"])

config_setting(
    name = "cached",
    values = {"define": "i686-elf-cached=true"},
)

filegroup(
    name = "i686-elf-gcc",
    srcs = [
        "gcc",
    ] + select({
        ":cached": ["@toolchain_i686_elf_cached//:gcc"],
        "//conditions:default": ["@toolchain-i686-elf//:gcc"],
    }),
)

filegroup(
    name = "i686-elf-g++",
    srcs = [
        "g++",
    ] + select({
        ":cached": ["@toolchain_i686_elf_cached//:g++"],
        "//conditions:default": ["@toolchain-i686-elf//:g++"],
    }),
)

filegroup(
    name = "i686-elf-ar",
    srcs = [
        "ar",
    ] + select({
        ":cached": ["@toolchain_i686_elf_cached//:ar"],
        "//conditions:default": ["@toolchain-i686-elf//:ar"],
    }),
)

filegroup(
    name = "i686-elf-ld",
    srcs = [
        "ld",
    ] + select({
        ":cached": ["@toolchain_i686_elf_cached//:ld"],
        "//conditions:default": ["@toolchain-i686-elf//:ld"],
    }),
)

filegroup(
    name = "i686-elf-nm",
    srcs = [
        "nm",
    ] + select({
        ":cached": ["@toolchain_i686_elf_cached//:nm"],
        "//conditions:default": ["@toolchain-i686-elf//:nm"],
    }),
)

filegroup(
    name = "i686-elf-objcopy",
    srcs = [
        "objcopy",
    ] + select({
        ":cached": ["@toolchain_i686_elf_cached//:objcopy"],
        "//conditions:default": ["@toolchain-i686-elf//:objcopy"],
    }),
)

filegroup(
    name = "i686-elf-objdump",
    srcs = [
        "objdump",
    ] + select({
        ":cached": ["@toolchain_i686_elf_cached//:objdump"],
        "//conditions:default": ["@toolchain-i686-elf//:objdump"],
    }),
)

filegroup(
    name = "i686-elf-strip",
    srcs = [
        "strip",
    ] + select({
        ":cached": ["@toolchain_i686_elf_cached//:strip"],
        "//conditions:default": ["@toolchain-i686-elf//:strip"],
    }),
)

filegroup(
    name = "i686-elf-as",
    srcs = [
        "as",
    ] + select({
        ":cached": ["@toolchain_i686_elf_cached//:as"],
        "//conditions:default": ["@toolchain-i686-elf//:as"],
    }),
)

filegroup(
    name = "i686-elf-compiler_pieces",
    srcs = select({
        ":cached": ["@toolchain_i686_elf_cached//:compiler_pieces"],
        "//conditions:default": ["@toolchain-i686-elf//:compiler_pieces"],
    }),
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
        ":i686-elf-compiler_pieces",
    ],
)

filegroup(
    name = "i686-elf-linker_files",
    srcs = [
        ":i686-elf-ar",
        ":i686-elf-g++",
        ":i686-elf-gcc",
        ":i686-elf-ld",
        ":i686-elf-compiler_pieces",
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

filegroup(name = "empty")

toolchain_config(
    name = "toolchain_config",
)

cc_toolchain(
    name = "cc-compiler-i686-elf",
    all_files = ":i686-elf-all_files",
    compiler_files = ":i686-elf-compiler_files",
    dwp_files = ":empty",
    linker_files = ":i686-elf-linker_files",
    objcopy_files = ":i686-elf-objcopy",
    strip_files = ":i686-elf-strip",
    supports_param_files = 0,
    toolchain_config = ":toolchain_config",
    toolchain_identifier = "i686-elf",
)
