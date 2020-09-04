def _premade_toolchain_repository_impl(ctx):
    for path in ctx.attr.paths:
        ctx.extract(path)
    ctx.symlink(ctx.attr.build_file, "BUILD")

premade_toolchain_repository = repository_rule(
    attrs = {
        "build_file": attr.label(default = "//tools/toolchain:toolchain.BUILD"),
        "paths": attr.label_list(mandatory = True),
    },
    implementation = _premade_toolchain_repository_impl,
)
