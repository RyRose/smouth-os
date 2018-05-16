package(default_visibility = ["//visibility:public"])

exports_files(["linker.ld"])

cc_library(
  name = "boot",
  alwayslink = 1,
  srcs = select({
    "//tools/toolchain:i386" : [
    "boot.S",
    "crti.S",
    "crtn.S",
    ],
    "//conditions:default" : [],
  }),
  deps = [
    ":multiboot"
  ]
)

cc_library(
  name = "multiboot",
  srcs = [
    "meminfo.cc",
  ],
  hdrs = [
    "meminfo.h",
    "multiboot.h"
  ]
)
