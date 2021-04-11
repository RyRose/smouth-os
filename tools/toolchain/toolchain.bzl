load("//tools/toolchain:toolchain_config.bzl", "toolchain_config")

def toolchain(name, workspace, target, target_cpu, compiler, **kwargs):
    binaries = [
        "ar",
        "as",
        "g++",
        "gcc",
        "ld",
        "nm",
        "objcopy",
        "objdump",
        "strip",
    ]

    binary_mapping = {}
    for binary in binaries:
        native.filegroup(
            name = name + "-" + binary,
            srcs = [
                "//tools/toolchain/binaries:" + binary,
                "@%s//:%s" % (workspace, binary),
            ],
            **kwargs
        )
        binary_mapping[binary] = ":" + name + "-" + binary

    all_files = name + "-all_files"
    native.filegroup(
        name = all_files,
        srcs = binary_mapping.values() + [
            "@%s//:compiler_pieces" % workspace,
        ],
        **kwargs
    )

    linker_files = name + "-linker_files"
    native.filegroup(
        name = linker_files,
        srcs = [
            binary_mapping["ar"],
            binary_mapping["g++"],
            binary_mapping["gcc"],
            binary_mapping["ld"],
            "@%s//:compiler_pieces" % workspace,
        ],
        **kwargs
    )

    compiler_files = name + "-compiler_files"
    native.filegroup(
        name = compiler_files,
        srcs = [
            binary_mapping["as"],
            binary_mapping["g++"],
            binary_mapping["gcc"],
            binary_mapping["ld"],
            "@%s//:compiler_pieces" % workspace,
        ],
        **kwargs
    )

    empty = name + "-empty"
    native.filegroup(name = empty)

    config = name + "-toolchain_config"
    toolchain_config(
        name = config,
        target = target,
        workspace = workspace,
        target_cpu = target_cpu,
        compiler = compiler,
        **kwargs
    )

    # Update tags to ensure the Bazel CLion plugin picks up the toolchain properly:
    # https://github.com/bazelbuild/intellij/issues/486
    tags = kwargs.pop("tags", [])
    tags.append("no-ide")

    native.cc_toolchain(
        name = name,
        all_files = all_files,
        compiler_files = compiler_files,
        dwp_files = empty,
        as_files = binary_mapping["as"],
        ar_files = binary_mapping["ar"],
        linker_files = linker_files,
        objcopy_files = binary_mapping["objcopy"],
        strip_files = binary_mapping["strip"],
        supports_param_files = 0,
        toolchain_config = config,
        toolchain_identifier = target,
        tags = tags,
        **kwargs
    )
