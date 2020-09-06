load("@io_bazel_rules_go//go:def.bzl", "go_test")

def qemu_test(name, kernel, **kwargs):
    tags = kwargs.pop("tags", [])
    tags.append("arch-only")
    go_test(
        name = name,
        args = [
            "--cpu=$(TARGET_CPU)",
            "--kernel=$(rootpath %s)" % kernel,
        ],
        srcs = [
            "//tools/go:qemu_test.go",
        ],
        deps = ["//tools/go/qemu:go_default_library"],
        data = [
            kernel,
        ],
        tags = tags,
        **kwargs
    )
