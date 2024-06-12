load("@io_bazel_rules_go//go:def.bzl", "go_binary")

def qemu_binaries(name, kernel, **kwargs):
    kwargs["tags"] = kwargs.pop("tags", []) + ["arch-only"]
    kwargs["embed"] = kwargs.pop("embed", []) + ["//tools/go/cmd/qemu:go_default_library"]

    args = kwargs.pop("args", []) + [
        "--cpu=$(TARGET_CPU)",
        "--kernel=$(rootpath %s)" % kernel,
    ]
    data = kwargs.pop("data", []) + [kernel]

    go_binary(
        name = name + "qemu",
        args = args + ["--output=monitor"],
        data = data,
        **kwargs
    )

    go_binary(
        name = name + "serial",
        args = args + [
            "--output=serial",
            "--log_serial=false",
        ],
        data = data,
        **kwargs
    )

    go_binary(
        name = name + "gdb",
        args = args + [
            "--output=gdb",
            "--workspace_file=$(rootpath //:workspace_name)",
        ],
        data = data + ["//:workspace_name"],
        **kwargs
    )
