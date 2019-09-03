load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
)
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

def _impl(ctx):
    tool_paths = [
        tool_path(
            name = "gcc",
            path = "i686-elf/gcc",
        ),
        tool_path(
            name = "ld",
            path = "i686-elf/ld",
        ),
        tool_path(
            name = "ar",
            path = "i686-elf/ar",
        ),
        tool_path(
            name = "cpp",
            path = "i686-elf/cpp",
        ),
        tool_path(
            name = "gcov",
            path = "i686-elf/gcov",
        ),
        tool_path(
            name = "nm",
            path = "i686-elf/nm",
        ),
        tool_path(
            name = "objdump",
            path = "i686-elf/objdump",
        ),
        tool_path(
            name = "strip",
            path = "i686-elf/strip",
        ),
    ]
    toolchain_all_flags_feature = feature(
        name = "toolchain_i686_elf_all_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cc_flags_make_variable,
                    ACTION_NAMES.clif_match,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_executable,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.lto_indexing,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.strip,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-nostdlib",
                            "-ffreestanding",
                            "-nostartfiles",
                            "-fno-exceptions",
                            "-fno-rtti",
                            "-std=gnu++17",
                            "-lgcc",
                        ],
                    ),
                ],
            ),
        ],
    )
    toolchain_nocached_feature = feature(
        name = "toolchain_i686_elf_nocached",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cc_flags_make_variable,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.linkstamp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-isystem",
                            "external/toolchain-i686-elf/toolchain/lib/gcc/i686-elf/7.2.0/include",
                            "-isystem",
                            "external/toolchain-i686-elf/toolchain/lib/gcc/i686-elf/7.2.0/include-fixed",
                        ],
                    ),
                ],
            ),
        ],
    )
    toolchain_cached_feature = feature(
        name = "toolchain_i686_elf_cached",
        enabled = False,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cc_flags_make_variable,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.linkstamp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-isystem",
                            "external/toolchain_i686_elf_cached/toolchain/lib/gcc/i686-elf/7.2.0/include",
                            "-isystem",
                            "external/toolchain_i686_elf_cached/toolchain/lib/gcc/i686-elf/7.2.0/include-fixed",
                        ],
                    ),
                ],
            ),
        ],
    )
    toolchain_compiler_flags_feature = feature(
        name = "toolchain_i686_elf_compiler_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cc_flags_make_variable,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.linkstamp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-MD",
                            "-lk",
                            # TODO(RyRose): Remove flag when lock/mutex primitives can enforce local static guards.
                            "-fno-threadsafe-statics",
                            "-Wall",
                            "-Wcast-align",
                            "-Wextra",
                            "-Wformat-nonliteral",
                            "-Wformat=2",
                            "-Winvalid-pch",
                            "-Wlogical-op",
                            "-Wmissing-declarations",
                            "-Wmissing-format-attribute",
                            "-Wno-free-nonheap-object",  # has false positives
                            "-Wodr",
                            "-Wold-style-cast",
                            "-Wpedantic",
                            "-Wredundant-decls",
                            "-Wrestrict",
                            "-Wshadow",
                            "-Wswitch-default",
                            "-Wswitch-enum",
                            "-Wunused-but-set-parameter",
                            "-Wuseless-cast",
                            "-fdiagnostics-color=always",
                        ],
                    ),
                ],
            ),
        ],
    )
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "i686-elf",
        host_system_name = "i686-unknown-linux-gnu",
        target_system_name = "i386",
        target_cpu = "i386",
        target_libc = "i386",
        compiler = "g++",
        abi_version = "i386",
        abi_libc_version = "i386",
        tool_paths = tool_paths,
        features = [
            toolchain_all_flags_feature,
            toolchain_cached_feature,
            toolchain_compiler_flags_feature,
            toolchain_nocached_feature,
        ],
    )

toolchain_config = rule(
    implementation = _impl,
    attrs = {},
    provides = [CcToolchainConfigInfo],
)
