def _premade_toolchain_repository_impl(ctx):
    ctx.extract(ctx.attr.path)
    ctx.symlink(ctx.attr.build_file, "BUILD")

premade_toolchain_repository = repository_rule(
    attrs = {
        "build_file": attr.label(default = "//tools/toolchain:toolchain.BUILD"),
        "path": attr.label(mandatory = True),
    },
    implementation = _premade_toolchain_repository_impl,
)
