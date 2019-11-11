load("//tools/toolchain:toolchain_config.bzl", "toolchain_config")

def toolchain(name, workspace, target, target_cpu, compiler):
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
        )
        binary_mapping[binary] = ":" + name + "-" + binary

    all_files = name + "-all_files"
    native.filegroup(
        name = all_files,
        srcs = binary_mapping.values() + [
            "@%s//:compiler_pieces" % workspace,
        ],
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
    )

    compiler_files = name + "-compiler_files"
    native.filegroup(
        name = compiler_files,
        srcs = [
            binary_mapping["as"],
            binary_mapping["g++"],
            binary_mapping["gcc"],
            binary_mapping["ld"],
        ],
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
    )

    native.cc_toolchain(
        name = name,
        tags = ["no-ide"],
        all_files = all_files,
        compiler_files = compiler_files,
        dwp_files = empty,
        linker_files = linker_files,
        objcopy_files = binary_mapping["objcopy"],
        strip_files = binary_mapping["strip"],
        supports_param_files = 0,
        toolchain_config = config,
        toolchain_identifier = target,
    )
