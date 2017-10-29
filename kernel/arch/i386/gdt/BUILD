package(default_visibility = ["//visibility:public"])

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
