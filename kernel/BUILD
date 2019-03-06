load("//kernel:templates.bzl", "kernel_library")

cc_binary(
    name = "kernel",
    srcs = [
        "kernel.cc",
    ],
    linkopts = select({
        "//tools/toolchain:i386": ["-T $(location //kernel/arch/i386:linker.ld)"],
    }),
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = select({
        "//tools/toolchain:i386": [
            "//kernel/arch/i386:linker.ld",
        ],
    }) + [
        "//libc/stdio",
        "//kernel/arch:boot",
        "//kernel/arch:memory",
        ":crt",
    ],
)

cc_library(
    name = "crt",
    srcs = [
        "crtbegin.o",
        "crtend.o",
        ":crt_files",
    ],
    tags = ["manual"],
)

GENERATE_CRT_FILES_CMD = """
for out in $(OUTS); do
  outname=$$(basename $$out);
  f=$$($(CC) $(CC_FLAGS) -print-file-name=$$outname);
  cp $$f $$out;
done;
"""

genrule(
    name = "crt_files",
    outs = [
        "crtbegin.o",
        "crtend.o",
    ],
    cmd = GENERATE_CRT_FILES_CMD,
    tags = ["manual"],
)
