package(default_visibility = ["//visibility:public"])

cc_library(
  name = "boot",
  srcs = [
    "boot.S",
    "crti.S",
    "crtn.S"
  ],
  deps = [
    ":multiboot",
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
  ],
  alwayslink = 1,
)
