cc_binary(
    name = "kernel",
    srcs = select({
        "//tools/toolchain:i386": [
            "kernel/kernel.cc",
        ],
        "//conditions:default": [
            "kernel/kernelstub.cc",
        ],
    }),
    linkopts = select({
        "//tools/toolchain:i386": ["-T $(location //kernel/arch/i386:linker.ld)"],
        "//conditions:default": [],
    }),
    visibility = ["//visibility:public"],
    deps = select({
        "//tools/toolchain:i386": [
            "//kernel/arch/i386:linker.ld",
            "//libc/stdio",
            "//kernel/arch:boot",
            "//kernel/arch:tty",
            "//kernel/arch:memory",
            ":crt",
        ],
        "//conditions:default": [],
    }),
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
