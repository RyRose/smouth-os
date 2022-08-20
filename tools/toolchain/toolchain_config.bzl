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
            path = "binaries/%s/%s/%s" % (target, workspace, binary),
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
                            # Disable stdlib and system startup files since they require runtime support.
                            "-nostdlib",
                            "-nostartfiles",
                            # Necessary for internal GCC library subroutines. These are usually made available in
                            # the stdlib but we've disabled it. They don't require runtime support.
                            "-lgcc",
                            # Asserts that the compiler targets freestanding environment. The kernel does not run in a
                            # hosted environment.
                            "-ffreestanding",
                            # Disable exceptions since they require runtime support.
                            "-fno-exceptions",
                            # Disable RTTI since it requires runtime support.
                            "-fno-rtti",
                        ],
                    ),
                ],
            ),
        ],
    )

def compiler_flags(name, workspace, target, gcc_version):
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
                            "-fstack-protector",
                            # TODO(RyRose): Remove flag when lock/mutex primitives can enforce local static guards.
                            "-fno-threadsafe-statics",
                            # Make available system libraries that don't need runtime support.
                            "-isystem",
                            "external/%s/lib/gcc/%s/%s/include" % (workspace, target, gcc_version),
                            "-isystem",
                            "external/%s/lib/gcc/%s/%s/include-fixed" % (workspace, target, gcc_version),
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
            compiler_flags("compiler_flags", ctx.attr.workspace, ctx.attr.target, ctx.attr.gcc_version),
        ],
    )

toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "target": attr.string(mandatory = True),
        "workspace": attr.string(mandatory = True),
        "target_cpu": attr.string(mandatory = True),
        "compiler": attr.string(mandatory = True),
        "gcc_version": attr.string(default = "7.2.0"),
    },
    provides = [CcToolchainConfigInfo],
)
