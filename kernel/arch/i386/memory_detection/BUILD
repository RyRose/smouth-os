package(default_visibility = ["//visibility:public"])

cc_library(
  name = "memory_detection",
  srcs = [
    "memory_detection.cc"
  ],
  deps = [
    "//libc/stdio",
    "//kernel/arch/i386/boot:multiboot"
  ],
  hdrs = [
    "//kernel/arch:memory_detection.h",
  ]
)
