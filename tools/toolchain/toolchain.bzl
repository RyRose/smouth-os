# Binary dependencies needed for running the bash commands
DEPS = [
    "make",
    "realpath",
    "gcc",
    "makeinfo",
    "sh",
]

def _check_dependency(ctx, dep):
    if ctx.which(dep) == None:
        fail("%s requires %s as a dependency. Please check your PATH." % (ctx.name, dep))

def _check_dependencies(ctx):
    for dep in DEPS:
        _check_dependency(ctx, dep)

_EXECUTION_FAILURE_MESSAGE = """
The command `%s` failed.
Return Code: %d.
stdout: %s.
stderr: %s.
"""

def _execute(ctx, cmd, fail_on_error = True, **kwargs):
    print("executing ", cmd)
    result = ctx.execute(["sh", "-c", """
                        set -ex;
                        %s""" % cmd], **kwargs)
    if fail_on_error and result.return_code != 0:
        fail(_EXECUTION_FAILURE_MESSAGE % (cmd, result.return_code, result.stdout, result.stderr))
    return result

def _build_binutils(ctx, prefix):
    print("downloading binutils...")
    ctx.download_and_extract(
        ctx.attr.binutils_urls,
        output = "binutils",
        sha256 = ctx.attr.binutils_sha256,
        stripPrefix = ctx.attr.binutils_strip_prefix,
    )
    _execute(ctx, "mkdir build-binutils")
    print("configuring and making binutils...")
    _execute(ctx, """
           cd build-binutils && \
           ../binutils/configure \
           --target=%s \
           --prefix=%s \
           --with-sysroot \
           --disable-nls \
           --disable-werror""" % (ctx.attr.target_triplet, prefix))
    _execute(ctx, "cd build-binutils && make")
    _execute(ctx, "cd build-binutils && make install")
    _execute(ctx, "rm -rf build-binutils")
    _execute(ctx, "rm -rf binutils")

def _build_gcc(ctx, prefix):
    print("downloading gcc...")
    ctx.download_and_extract(
        ctx.attr.gcc_urls,
        output = "gcc",
        sha256 = ctx.attr.gcc_sha256,
        stripPrefix = ctx.attr.gcc_strip_prefix,
    )
    _execute(ctx, "mkdir build-gcc")
    _execute(ctx, "cd gcc && contrib/download_prerequisites", timeout = 120, fail_on_error = False)
    print("configuring and making gcc...")
    _execute(ctx, """
           cd build-gcc && \
           ../gcc/configure \
           --target=%s \
           --prefix=%s \
           --disable-nls \
           --enable-languages=c,c++ \
           --without-headers""" % (ctx.attr.target_triplet, prefix))
    _execute(ctx, "cd build-gcc && make all-gcc", timeout = 2000)
    _execute(ctx, "cd build-gcc && make all-target-libgcc")
    _execute(ctx, "cd build-gcc && make install-gcc")
    _execute(ctx, "cd build-gcc && make install-target-libgcc")
    _execute(ctx, "rm -rf gcc")
    _execute(ctx, "rm -rf build-gcc")

def _toolchain_impl(ctx):
    print("checking dependencies...")
    _check_dependencies(ctx)
    print("making toolchain directory...")
    _execute(ctx, "mkdir toolchain")
    prefix = _execute(ctx, "realpath toolchain").stdout.strip()
    print("building binutils...")
    _build_binutils(ctx, prefix)
    print("building gcc...")
    _build_gcc(ctx, prefix)
    ctx.symlink(Label(ctx.attr.build_file), "BUILD")

new_toolchain_repository = repository_rule(
    attrs = {
        "build_file": attr.string(mandatory = True),
        "binutils_urls": attr.string_list(mandatory = True),
        "binutils_sha256": attr.string(),
        "binutils_strip_prefix": attr.string(),
        "gcc_urls": attr.string_list(mandatory = True),
        "gcc_sha256": attr.string(),
        "gcc_strip_prefix": attr.string(),
        "target_triplet": attr.string(mandatory = True),
    },
    local = False,
    implementation = _toolchain_impl,
)
