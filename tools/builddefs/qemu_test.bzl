load("@bazel_skylib//lib:shell.bzl", "shell")
load("@io_bazel_rules_go//go:def.bzl", "go_test")

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
