package(default_visibility = ["//visibility:public"])

cc_library(
  name = "memory",
  srcs = [
    "memory.cc"
  ],
  hdrs = [
    "//kernel/arch:memory.h",
  ],
  deps = [
    "//libc/stdio",
    "//kernel/arch/i386/boot:multiboot",
    "//kernel/arch/i386/boot:mmap_manager"
  ],
)
