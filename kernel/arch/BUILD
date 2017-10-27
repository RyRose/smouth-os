package(default_visibility=["//visibility:public"])

exports_files(["tty.h", "gdt.h"])

cc_library(
  name = "tty",
  hdrs = ["tty.h"],
  deps = select({
    "//tools:i386" : ["//kernel/arch/i386:tty"],
    "//conditions:default" : ["//kernel/arch/local:tty"]
  }),
)

cc_library(
  name = "gdt",
  hdrs = ["gdt.h"],
  deps = select({
    "//tools:i386" : ["//kernel/arch/i386:gdt"],
    "//conditions:default" : ["//kernel/arch/local:gdt"]
  }),
)

cc_library(
  name = "boot",
  deps = select({
    "//tools:i386" : ["//kernel/arch/i386:boot"],
  }),
)
