package(default_visibility = ["//visibility:public"])

exports_files(["linker.ld"])

cc_library(
  name = "tty",
  srcs = [
    "tty.cc"
  ],
  hdrs = [
    "vga.h",
    "//kernel/arch:tty.h",
  ],
  deps = [
    "//libc/string",
  ],
)

cc_library(
  name = "gdt",
  srcs = [
    "gdt.cc",
    "gdt_flush.S"
  ],
  deps = [
    "//libc/stdio"
  ],
  hdrs = [
    "//kernel/arch:gdt.h"
  ]
)

cc_library(
  name = "boot",
  srcs = [
    "boot.S",
    "crti.S",
    "crtn.S"
  ],
  alwayslink = 1,
)
