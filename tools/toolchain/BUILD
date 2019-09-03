package(default_visibility = ["//visibility:public"])

exports_files([
    "toolchain.BUILD",
    "toolchain.bzl",
])

config_setting(
    name = "i386",
    values = {
        "cpu": "i386",
    },
)

config_setting(
    name = "local",
    values = {
        "cpu": "k8",
    },
)

cc_toolchain_suite(
    name = "toolchain",
    toolchains = {
        "darwin|compiler": "@bazel_tools//tools/cpp:cc-compiler-darwin",
        "i386|g++": "//tools/toolchain/i686-elf:cc-compiler-i686-elf",
        "k8": "@bazel_tools//tools/cpp:cc-compiler-local",
        "k8|g++": "@bazel_tools//tools/cpp:cc-compiler-local",
        "local|compiler": "@bazel_tools//tools/cpp:cc-compiler-local",
    },
)

