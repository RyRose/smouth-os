package(default_visibility=["//visibility:public"])

load("//kernel/arch:arch.bzl", "arch_library")

arch_library(name = "tty")

arch_library(name = "gdt")

cc_library(
  name = "boot",
  deps = select({
    "//tools:i386" : ["//kernel/arch/i386/boot"],
  }),
)
