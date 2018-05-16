
cc_binary (
  name = "kernel",
  srcs = select({
    "//tools/toolchain:i386" : [
      "kernel/kernel.cc"
    ],
    "//conditions:default" : [
      "kernel/kernelstub.cc"
    ]
  }),
  deps = [
    "//libc/stdio",
    "//kernel/arch:boot",
    "//kernel/arch:gdt",
    "//kernel/arch:tty",
    "//kernel/arch:memory",
    ":crt"
  ] +
  select({
    "//tools/toolchain:i386" : ["//kernel/arch/i386:linker.ld"],
    "//conditions:default" : []
  }),
  linkopts = select({
    "//tools/toolchain:i386" : ["-T $(location //kernel/arch/i386:linker.ld)"],
    "//conditions:default" : []
   }),
  visibility = ["//visibility:public"],
)

cc_library (
  name = "crt",
  srcs = select({
    "//tools/toolchain:i386" : [
    "crtbegin.o",
    "crtend.o",
    ":crt_files",
    ],
    "//conditions:default" : [],
  }),
)

GENERATE_CRT_FILES_CMD="""
for out in $(OUTS); do
  outname=$$(basename $$out);
  f=$$($(CC) $(CC_FLAGS) -print-file-name=$$outname);
  cp $$f $$out;
done;
"""

TOUCH_CRT_FILES_CMD="""
for out in $(OUTS); do
  touch $$out;
done;
"""

genrule (
  name = "crt_files",
  outs = [
    "crtbegin.o",
    "crtend.o"
  ],
  cmd = select({
      "//tools/toolchain:i386" : GENERATE_CRT_FILES_CMD,
      "//conditions:default" : TOUCH_CRT_FILES_CMD
  }),
)
