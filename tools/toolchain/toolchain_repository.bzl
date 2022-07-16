# Binary dependencies needed for running the bash commands
DEPS = [
    "make",
    "gcc",
    "g++",
    "makeinfo",
    "sh",
    "pwd",
    "python3",
]

STATE_STEP = "step"
STATE_NUM_STEPS = "num_steps"
STATE_DRY_RUN = "dry_run"
STATE_PREFIX = "prefix"
STATE_CPU_COUNT = "cpu_count"

def _report_progress(ctx, state, status):
    if not state.get(STATE_DRY_RUN, False):
        ctx.report_progress("step %d of %d: %s" % (state[STATE_STEP], state[STATE_NUM_STEPS], status))
    if STATE_STEP not in state:
        state[STATE_STEP] = 0
    state[STATE_STEP] += 1

def _check_dependencies(ctx):
    nondeps = []
    for dep in DEPS:
        if not ctx.which(dep):
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

def _execute(ctx, state, cmd, fail_on_error = True, timeout = 24 * 60 * 60, **kwargs):
    if state.get(STATE_DRY_RUN, False):
        print("executing shell command in dry-run mode:", cmd)
        return ctx.execute(["true"])
    print("executing shell command:", cmd)
    if ctx.which("time"):
        prefix = ["time"]
    else:
        prefix = []
    result = ctx.execute(prefix+["sh", "-c", "set -ex; %s" % cmd], timeout = timeout, **kwargs)
    if fail_on_error and result.return_code != 0:
        fail(_EXECUTION_FAILURE_MESSAGE % (cmd, result.return_code, result.stdout, result.stderr))
    print(_EXECUTION_SUCCESS_MESSAGE % (cmd, result.return_code, result.stdout, result.stderr))
    return result

def _make(ctx, state, directory, target, **kwargs):
    _report_progress(ctx, state, "making '%s' in %s" % (target, directory))
    return _execute(ctx, state, "cd %s && make -j %d %s" % (directory, state.get(STATE_CPU_COUNT, 1), target))

def _build_binutils(ctx, state):
    _report_progress(ctx, state, "downloading binutils")
    if not state.get(STATE_DRY_RUN, False):
        ctx.download_and_extract(
            ctx.attr.binutils_urls,
            output = "binutils",
            sha256 = ctx.attr.binutils_sha256,
            stripPrefix = ctx.attr.binutils_strip_prefix,
        )
    _execute(ctx, state, "mkdir build-binutils")
    _report_progress(ctx, state, "configuring binutils")
    _execute(
        ctx,
        state,
        "cd build-binutils && " +
        "../binutils/configure " +
        "--target=%s " % ctx.attr.target +
        "--prefix=%s " % ("" if state.get(STATE_DRY_RUN, False) else state[STATE_PREFIX]) +
        "--with-sysroot " +
        "--disable-nls " +
        "--disable-werror",
    )
    _make(ctx, state, "build-binutils", "")
    _make(ctx, state, "build-binutils", "install")
    _execute(ctx, state, "rm -rf build-binutils")
    _execute(ctx, state, "rm -rf binutils")

def _build_gcc(ctx, state):
    _report_progress(ctx, state, "downloading gcc")
    if not state.get(STATE_DRY_RUN, False):
        ctx.download_and_extract(
            ctx.attr.gcc_urls,
            output = "gcc",
            sha256 = ctx.attr.gcc_sha256,
            stripPrefix = ctx.attr.gcc_strip_prefix,
        )
    _execute(ctx, state, "mkdir build-gcc")
    _report_progress(ctx, state, "downloading gcc prerequisites")
    _execute(ctx, state, "cd gcc && contrib/download_prerequisites", fail_on_error = False)
    _report_progress(ctx, state, "configuring gcc")
    _execute(
        ctx,
        state,
        "cd build-gcc && " +
        "../gcc/configure " +
        "--target=%s " % ctx.attr.target +
        "--prefix=%s " % ("" if state.get(STATE_DRY_RUN, False) else state[STATE_PREFIX]) +
        "--disable-nls " +
        "--enable-languages=c,c++ " +
        "--without-headers",
    )
    _make(ctx, state, "build-gcc", "all-gcc")
    _make(ctx, state, "build-gcc", "all-target-libgcc")
    _make(ctx, state, "build-gcc", "install-gcc")
    _make(ctx, state, "build-gcc", "install-target-libgcc")
    _execute(ctx, state, "rm -rf gcc")
    _execute(ctx, state, "rm -rf build-gcc")

def _build(ctx, state):
    _build_binutils(ctx, state)
    _build_gcc(ctx, state)

def _toolchain_impl(ctx):
    _check_dependencies(ctx)
    dry_run_state = {STATE_DRY_RUN: True}
    _build(ctx, dry_run_state)
    _build(ctx, {
        STATE_STEP: 1,
        STATE_NUM_STEPS: dry_run_state[STATE_STEP],
        STATE_CPU_COUNT: int(_execute(
            ctx,
            {},
            "python3 -c 'import multiprocessing; print(multiprocessing.cpu_count())'",
        ).stdout.strip()),
        STATE_PREFIX: _execute(ctx, {}, "pwd").stdout.strip(),
    })
    ctx.symlink(ctx.attr.build_file, "BUILD")

toolchain_repository = repository_rule(
    attrs = {
        "build_file": attr.label(default = "//tools/toolchain:toolchain.BUILD"),
        "binutils_urls": attr.string_list(mandatory = True),
        "binutils_sha256": attr.string(),
        "binutils_strip_prefix": attr.string(),
        "gcc_urls": attr.string_list(mandatory = True),
        "gcc_sha256": attr.string(),
        "gcc_strip_prefix": attr.string(),
        "target": attr.string(mandatory = True),
    },
    implementation = _toolchain_impl,
)
