def crt_file(name, filename, **kwargs):
    """A CRT (C RunTime) file provided by the compiler used for the startup routines.

       CRT (C RunTime) files are the necessary startup routines for C binaries. Since
       there is no C runtime environment for this operating system, we disable most of
       it with the "-nostdlib" and "-nostartfiles" flag but copy crtbegin.o and
       crtend.o since they work in any environment and they're required. See
       https://wiki.osdev.org/Calling_Global_Constructors for more details.

       Args:
         name: The name of the rule capturing the CRT file.
         filename: The CRT file to request from the compiler.
    """
    native.genrule(
        name = name,
        outs = [
            "crtfiles/%s/%s" % (name, filename),
        ],
        toolchains = [
            # Defines CC make variable.
            "@bazel_tools//tools/cpp:current_cc_toolchain",
            # Defines CC_FLAGS make variable.
            "@bazel_tools//tools/cpp:cc_flags",
        ],
        cmd = (
            "mkdir -p $$(dirname $@); " +
            "cp $$($(CC) $(CC_FLAGS) -print-file-name=$$(basename $@)) $@;"
        ),
        tags = kwargs.pop("tags", []) + ["arch-only"],
        **kwargs
    )
