
cc_library(
  name = "memory",
  srcs = [
    "memory.cc",
  ],
  hdrs = [
    "memory.h",
  ],
  deps = [
    "//kernel/arch:memory",
    "//libc/string"
  ],
)

cc_test(
  name = "memory_test",
  size = "small",
  srcs = [
    "memory_test.cc",
  ],
  deps = [
    "@com_google_googletest//:gtest",
    ":memory",
  ],
)

