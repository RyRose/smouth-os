const std = @import("std");
const base = @import("build/base.zig");

pub fn build(b: *std.Build) !void {

    // Create a symlink `src/std -> <zig_lib_dir>/std` so source files can be
    // embedded without copying the standard library.
    const stdlib_std_path = b.pathJoin(&.{ b.graph.zig_lib_directory.path orelse ".", "std" });
    const std_link = b.addSystemCommand(&.{ "ln", "-sfn", stdlib_std_path, "src/std" });

    const prepare_freestanding = b.step("prepare-freestanding", "Prepare freestanding build inputs.");
    prepare_freestanding.dependOn(&std_link.step);

    const optimize = b.standardOptimizeOption(.{});
    const source_paths: []const []const u8 = &.{ "src", stdlib_std_path };
    const x86_linker_path = b.path("src/arch/x86/linker.ld");

    const x86_target = b.resolveTargetQuery(.{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
        .abi = .none,
        // Returning structs caused kernel triple faults. soft_float prevents
        // generated memcpy code from using disabled SIMD instructions.
        // See https://wiki.osdev.org/Zig_Bare_Bones.
        .cpu_features_add = std.Target.x86.featureSet(&.{.soft_float}),
        .cpu_features_sub = std.Target.x86.featureSet(&.{ .avx, .avx2, .sse, .sse2, .mmx }),
    });
    const x86_module = try base.createRootModule(b, x86_target, optimize, source_paths);

    // Create the main x86 kernel executable.
    const x86_main_compile = b.addExecutable(.{
        .name = "kernel-main-x86",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = x86_target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "smouth", .module = x86_module },
            },
        }),
    });
    x86_main_compile.step.dependOn(prepare_freestanding);
    x86_main_compile.setLinkerScript(x86_linker_path);
    b.installArtifact(x86_main_compile);
    const x86_main_run = base.addQemuRun(b, x86_main_compile);
    b.step("run-x86", "Run the x86 kernel in QEMU.").dependOn(&x86_main_run.step);

    // Create the x86 kernel test executable and run it in QEMU.
    // This runs all x86-compatible tests in QEMU.
    const x86_test_compile = b.addTest(.{
        .name = "kernel-test-x86",
        .root_module = x86_module,
        .test_runner = .{ .path = b.path("src/main.zig"), .mode = .simple },
    });
    x86_test_compile.step.dependOn(prepare_freestanding);
    x86_test_compile.setLinkerScript(x86_linker_path);
    b.installArtifact(x86_test_compile);
    const x86_test_run = base.addQemuRun(b, x86_test_compile);
    b.step("test-x86", "Run source module tests in QEMU on x86.").dependOn(&x86_test_run.step);

    // Create the hosted unit test executable and run it natively. Source paths
    // are excluded to improve build times since they are only used for stack
    // traces in freestanding environments.
    const hosted_target = b.standardTargetOptions(.{});
    const hosted_module = try base.createRootModule(b, hosted_target, optimize, &.{});
    const unit_test_compile = b.addTest(.{ .root_module = hosted_module });
    const unit_test_run = b.addRunArtifact(unit_test_compile);
    b.step("test", "Run unit tests.").dependOn(&unit_test_run.step);

    const test_all = b.step("test-all", "Run all tests.");
    test_all.dependOn(&x86_test_run.step);
    test_all.dependOn(&unit_test_run.step);
}
