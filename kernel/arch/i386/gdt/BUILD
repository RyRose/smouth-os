package(default_visibility = ["//visibility:public"])

cc_library(
  name = "gdt",
  srcs = select({
    "//tools/toolchain:i386" : [
    "gdt.cc",
    "gdt_flush.S"
  ],
    "//conditions:default" : [],
  }),
  deps = [
    "//kernel/util:status"
  ],
  hdrs = [
    "//kernel/arch:gdt.h"
  ]
)
