
cc_binary (
  name = "kernel",
  srcs = select({
    "//tools/toolchain:local" : [
      "kernel/kernelstub.cc"
    ],
    "//conditions:default" : [
      "kernel/kernel.cc"
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
    "//tools/toolchain:local" : [],
    "//conditions:default" : [
    "crtbegin.o",
    "crtend.o",
    ":crt_files",
    ]
  }),
)

genrule (
  name = "crt_files",
  outs = [
    "crtbegin.o",
    "crtend.o"
  ],
  cmd = "for out in $(OUTS); do outname=$$(basename $$out); f=$$($(CC) $(CC_FLAGS) -print-file-name=$$outname); cp $$f $$out; done;"
)
