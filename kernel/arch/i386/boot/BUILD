package(default_visibility = ["//visibility:public"])

cc_library(
  name = "boot",
  srcs = [
    "boot.S",
    "crti.S",
    "crtn.S",
  ],
  deps = [
    ":multiboot",
    "linker.ld"
  ],
  linkopts = [
    "-T $(location linker.ld)"
  ],
  alwayslink = 1,
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
