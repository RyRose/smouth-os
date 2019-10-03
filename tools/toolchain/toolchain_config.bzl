load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
)
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

def tool_paths(workspace, target):
    return [
        tool_path(
            name = binary,
            path = "binaries/" + binary,
        )
        for binary in ["gcc", "ld", "ar", "cpp", "gcov", "nm", "objdump", "strip"]
    ]

def all_flags(name):
    return feature(
        name = name,
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

def compiler_flags(name, workspace, target):
    return feature(
        name = name,
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
                            "-g",
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
                            "-isystem",
                            "external/%s/lib/gcc/%s/7.2.0/include" % (workspace, target),
                            "-isystem",
                            "external/%s/lib/gcc/%s/7.2.0/include-fixed" % (workspace, target),
                        ],
                    ),
                ],
            ),
        ],
    )

def _impl(ctx):
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = ctx.attr.target,
        host_system_name = "N/A",
        target_system_name = "N/A",
        target_cpu = ctx.attr.target_cpu,
        target_libc = "N/A",
        compiler = ctx.attr.compiler,
        abi_version = "N/A",
        abi_libc_version = "N/A",
        tool_paths = tool_paths(ctx.attr.workspace, ctx.attr.target),
        features = [
            all_flags("all_flags"),
            compiler_flags("compiler_flags", ctx.attr.workspace, ctx.attr.target),
        ],
    )

toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "target": attr.string(mandatory = True),
        "workspace": attr.string(mandatory = True),
        "target_cpu": attr.string(mandatory = True),
        "compiler": attr.string(mandatory = True),
    },
    provides = [CcToolchainConfigInfo],
)
