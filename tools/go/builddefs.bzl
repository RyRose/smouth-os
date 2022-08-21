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
        data = kwargs.pop("data", []) + [kernel],
        tags = kwargs.pop("tags", []) + ["arch-only"],
        **kwargs
    )

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
