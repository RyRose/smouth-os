package(default_visibility = ["//visibility:public"])

cc_library(
  name = "gdt",
  srcs = select({
    "//tools:local" : [],
    "//conditions:default" : [
    "gdt.cc",
    "gdt_flush.S"
  ]}),
  deps = [
    "//kernel/util:status"
  ],
  hdrs = [
    "//kernel/arch:gdt.h"
  ]
)
