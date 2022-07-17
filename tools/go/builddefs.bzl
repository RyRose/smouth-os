load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_test")
load("@bazel_skylib//lib:shell.bzl", "shell")

def qemu_test(name, kernel, magic_string = None, **kwargs):
    go_test(
        name = name,
        args = kwargs.pop("args", []) + [
            "--sub_test_name=%s" % name,
            "--cpu=$(TARGET_CPU)",
            "--kernel=$(rootpath %s)" % kernel,
        ] + ([] if not magic_string else [
            "--magic_string=%s" % shell.quote(magic_string),
        ]),
        srcs = kwargs.pop("srcs", []) + [
            "//tools/go:qemu_test.go",
        ],
        deps = kwargs.pop("deps", []) + ["//tools/go/qemu:go_default_library"],
        data = kwargs.pop("data", []) + [
            kernel,
        ],
        tags = kwargs.pop("tags", []) + ["arch-only"],
        **kwargs
    )

def qemu_binaries(name, kernel, **kwargs):
    kwargs["tags"] = kwargs.pop("tags", []) + ["arch-only"]
    args = kwargs.pop("args", [])
    data = kwargs.pop("data", [])
    embed = kwargs.pop("embed", [])

    go_binary(
        name = name + "qemu",
        args = [
            "--cpu=$(TARGET_CPU)",
            "--kernel=$(rootpath %s)" % kernel,
            "--output=monitor",
        ] + args,
        data = [
            kernel,
        ] + data,
        embed = ["//tools/go/cmd/qemu:go_default_library"] + embed,
        **kwargs
    )

    go_binary(
        name = name + "serial",
        args = [
            "--cpu=$(TARGET_CPU)",
            "--kernel=$(rootpath %s)" % kernel,
            "--output=serial",
            "--log_serial=false",
        ] + args,
        data = [
            kernel,
        ] + data,
        embed = ["//tools/go/cmd/qemu:go_default_library"] + embed,
        **kwargs
    )

    go_binary(
        name = name + "gdb",
        args = [
            "--cpu=$(TARGET_CPU)",
            "--kernel=$(rootpath %s)" % kernel,
            "--output=gdb",
            "--workspace_file=$(rootpath //:workspace_name)",
        ] + args,
        data = [
            "//:workspace_name",
            kernel,
        ] + data,
        embed = ["//tools/go/cmd/qemu:go_default_library"] + embed,
        **kwargs
    )
