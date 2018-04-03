package(default_visibility = ["//visibility:public"])

config_setting(
  name = "i386",
  values = {
    "cpu": "i386",
  },
)

config_setting(
  name = "local",
  values = {
    "cpu": "k8",
  },
)

filegroup(
      name = "empty",
      srcs = [],
)

cc_toolchain(
    name = "cc-compiler-local",
    all_files = ":empty",
    compiler_files = ":empty",
    cpu = "local",
    dwp_files = ":empty",
    dynamic_runtime_libs = [":empty"],
    linker_files = ":empty",
    objcopy_files = ":empty",
    static_runtime_libs = [":empty"],
    strip_files = ":empty",
    supports_param_files = 1,
)

cc_toolchain_suite(
    name = "toolchain",
    toolchains = {
        "i386|g++" : ":cc-compiler-i386",
        "local|compiler" : ":cc-compiler-local",
    },
)

filegroup(
      name = "i686-elf-all_files",
      srcs = [
              "//tools/compilers:i686-elf-compiler_pieces",
              "//tools/compilers:i686-elf-compiler_components",
            ],
)

filegroup(
      name = "i686-elf-linker_files",
      srcs = [
              "//tools/compilers:i686-elf-ar",
              "//tools/compilers:i686-elf-compiler_pieces",
              "//tools/compilers:i686-elf-g++",
              "//tools/compilers:i686-elf-gcc",
              "//tools/compilers:i686-elf-ld",
            ],
)

filegroup(
      name = "i686-elf-compiler_files",
      srcs = [
              "//tools/compilers:i686-elf-as",
              "//tools/compilers:i686-elf-g++",
              "//tools/compilers:i686-elf-gcc",
              "//tools/compilers:i686-elf-ld",
            ],
)


cc_toolchain(
     name = "cc-compiler-i386",
     all_files = ":i686-elf-all_files",
     compiler_files = ":i686-elf-compiler_files",
     cpu = "i386",
     dwp_files = ":empty",
     dynamic_runtime_libs = [":empty"],
     linker_files = ":i686-elf-linker_files",
     objcopy_files = "//tools/compilers:i686-elf-objcopy",
     static_runtime_libs = [":empty"],
     strip_files = "//tools/compilers:i686-elf-strip",
     supports_param_files = 1,
)
