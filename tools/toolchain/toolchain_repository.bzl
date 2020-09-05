# Binary dependencies needed for running the bash commands
DEPS = [
    "make",
    "gcc",
    "makeinfo",
    "sh",
    "pwd",
]


def _report_progress(ctx, state, status):
    ctx.report_progress("step %d of %d: %s" % (state["step"], state["num_steps"], status))
    state["step"] += 1


def _check_dependencies(ctx, state):
    _report_progress(ctx, state, "checking dependencies")
    nondeps = []
    for dep in DEPS:
        if ctx.which(dep) == None:
            nondeps.append(dep)
    if nondeps:
        fail("%s requires %s as dependencies. Please check your PATH." % (ctx.name, nondeps))

_EXECUTION_FAILURE_MESSAGE = """
The command `%s` failed.
Return Code: %d
stdout:
%s
stderr:
%s
"""

_EXECUTION_SUCCESS_MESSAGE = """
The command `%s` succeeded.
Return Code: %d
stdout:
%s
stderr:
%s
"""

def _execute(ctx, cmd, fail_on_error = True, timeout=24 * 60 * 60, **kwargs):
    print("executing shell command:", cmd)
    result = ctx.execute(["time", "sh", "-c", "set -ex; %s" % cmd], timeout=timeout, **kwargs)
    if fail_on_error and result.return_code != 0:
        fail(_EXECUTION_FAILURE_MESSAGE % (cmd, result.return_code, result.stdout, result.stderr))
    print(_EXECUTION_SUCCESS_MESSAGE % (cmd, result.return_code, result.stdout, result.stderr))
    return result

def _build_binutils(ctx, state, prefix):
    _report_progress(ctx, state, "downloading binutils")
    ctx.download_and_extract(
        ctx.attr.binutils_urls,
        output = "binutils",
        sha256 = ctx.attr.binutils_sha256,
        stripPrefix = ctx.attr.binutils_strip_prefix,
    )
    _execute(ctx, "mkdir build-binutils")
    _report_progress(ctx, state, "configuring binutils")
    _execute(
        ctx,
        "cd build-binutils && " +
        "../binutils/configure " +
        "--target=%s " % ctx.attr.target +
        "--prefix=%s " % prefix +
        "--with-sysroot " +
        "--disable-nls " +
        "--disable-werror",
    )
    _report_progress(ctx, state, "making binutils")
    _execute(ctx, "cd build-binutils && make")
    _report_progress(ctx, state, "make installing binutils")
    _execute(ctx, "cd build-binutils && make install")
    _execute(ctx, "rm -rf build-binutils")
    _execute(ctx, "rm -rf binutils")

def _build_gcc(ctx, state, prefix):
    _report_progress(ctx, state, "downloading gcc")
    ctx.download_and_extract(
        ctx.attr.gcc_urls,
        output = "gcc",
        sha256 = ctx.attr.gcc_sha256,
        stripPrefix = ctx.attr.gcc_strip_prefix,
    )
    _execute(ctx, "mkdir build-gcc")
    _report_progress(ctx, state, "downloading gcc prerequisites")
    _execute(ctx, "cd gcc && contrib/download_prerequisites", fail_on_error = False)
    _report_progress(ctx, state, "configuring and making gcc")
    _execute(
        ctx,
        "cd build-gcc && " +
        "../gcc/configure " +
        "--target=%s " % ctx.attr.target +
        "--prefix=%s " % prefix +
        "--disable-nls " +
        "--enable-languages=c,c++ " +
        "--without-headers",
    )
    _report_progress(ctx, state, "making all-gcc (long!)")
    _execute(ctx, "cd build-gcc && make all-gcc")
    _report_progress(ctx, state, "making all-target-gcc")
    _execute(ctx, "cd build-gcc && make all-target-libgcc")
    _report_progress(ctx, state, "making install-gcc")
    _execute(ctx, "cd build-gcc && make install-gcc")
    _report_progress(ctx, state, "making install-target-gcc")
    _execute(ctx, "cd build-gcc && make install-target-libgcc")
    _execute(ctx, "rm -rf gcc")
    _execute(ctx, "rm -rf build-gcc")

def _toolchain_impl(ctx):
    state = {"step": 1, "num_steps": 12}
    _check_dependencies(ctx, state)
    prefix = _execute(ctx, "pwd").stdout.strip()
    _build_binutils(ctx, state, prefix)
    _build_gcc(ctx, state, prefix)
    ctx.symlink(ctx.attr.build_file, "BUILD")

toolchain_repository = repository_rule(
    attrs = {
        "build_file": attr.label(default = "//tools/toolchain:toolchain.BUILD"),
        "binutils_urls": attr.string_list(mandatory = True),
        "binutils_sha256": attr.string() ,
        "binutils_strip_prefix": attr.string(),
        "gcc_urls": attr.string_list(mandatory = True),
        "gcc_sha256": attr.string(),
        "gcc_strip_prefix": attr.string(),
        "target": attr.string(mandatory = True),
    },
    implementation = _toolchain_impl,
)
