package(default_visibility = ["//visibility:public"])

cc_library(
  name = "boot",
  alwayslink = True,
  srcs = [
    "pre_kernel_main.cc",
    "boot.S",
    "crti.S",
    "crtn.S",
  ],
  deps = [
    ":gdt_installer",
    ":mmap_manager"
  ],
  tags = [
      "manual"
  ]
)

cc_library(
  name = "mmap_manager",
  srcs = [
    "mmap_manager.cc",
  ],
  hdrs = [
    "mmap_manager.h",
  ],
  deps = [
    ":multiboot",
  ]
)

cc_test(
  name = "mmap_manager_test",
  size = "small",
  srcs = [
    "mmap_manager_test.cc"
  ],
  deps = [
    ":mmap_manager",
    "@com_google_googletest//:gtest"
  ]
)

cc_library(
  name = "multiboot",
  hdrs = [
    "multiboot.h"
  ]
)

cc_library(
  name = "gdt",
  srcs = [
      "gdt.cc"
  ],
  hdrs = [
    "gdt.h"
  ],
  deps = [
    "//kernel/cxx:abi"
  ]
)

cc_test(
    name = "gdt_test",
    size = "small",
    srcs = [
        "gdt_test.cc"
        ],
    deps = [
        ":gdt",
        "@com_google_googletest//:gtest"
        ]
    )

cc_library(
  name = "gdt_installer",
  srcs = [
      "gdt_flush.S",
      "gdt_installer.cc"
  ],
  deps = [
      ":gdt"
  ],
  hdrs = [
      "gdt_installer.h"
  ],
  tags = [
      "manual"
  ]
)

