const std = @import("std");
const base = @import("build/base.zig");

pub fn build(b: *std.Build) !void {

    // Create a symlink `src/std -> <zig_lib_dir>/std` so source files can be
    // embedded without copying the standard library.
    const stdlib_std_path = b.pathJoin(&.{ b.graph.zig_lib_directory.path orelse ".", "std" });
    const std_link = b.addSystemCommand(&.{ "ln", "-sfn", stdlib_std_path, "src/std" });

    const prepare = b.step("prepare", "Prepare build inputs.");
    prepare.dependOn(&std_link.step);
    const optimize = b.standardOptimizeOption(.{});
    const source_paths: []const []const u8 = &.{ "src", stdlib_std_path };

    const hosted_target = b.standardTargetOptions(.{});
    const hosted_smouth = try addSmouthModule(b, hosted_target, optimize, source_paths);

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
    const x86_smouth = try addSmouthModule(b, x86_target, optimize, source_paths);

    // Build the x86 kernel executable and install it as an artifact.
    const x86_main = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = x86_target,
        .optimize = optimize,
    });
    x86_main.addImport("smouth", x86_smouth);
    const x86_exe = b.addExecutable(.{
        .name = "kernel-x86-main",
        .root_module = x86_main,
    });
    x86_exe.step.dependOn(prepare);
    x86_exe.setLinkerScript(b.path("src/arch/x86/linker.ld"));
    b.installArtifact(x86_exe);
    const x86_run = base.buildQemu(b, x86_exe);
    b.step("run-x86", "Run the x86 kernel in QEMU.").dependOn(&x86_run.step);

    const x86_test_artifact = b.addTest(.{
        .name = "test-smouth-x86",
        .root_module = x86_smouth,
        .test_runner = .{ .path = b.path("src/main.zig"), .mode = .simple },
    });
    x86_test_artifact.step.dependOn(prepare);
    x86_test_artifact.setLinkerScript(b.path("src/arch/x86/linker.ld"));
    b.installArtifact(x86_test_artifact);
    const x86_test = base.buildQemu(b, x86_test_artifact);
    b.step("test-x86", "Run source module tests in QEMU on x86.").dependOn(&x86_test.step);

    const unit_test = b.addTest(.{ .root_module = hosted_smouth });
    unit_test.step.dependOn(prepare);
    const run_unit = b.addRunArtifact(unit_test);
    b.step("test", "Run unit tests.").dependOn(&run_unit.step);

    const test_all = b.step("test-all", "Run all tests.");
    test_all.dependOn(&x86_test.step);
    test_all.dependOn(&run_unit.step);
}

/// Creates the smouth source module for a build target.
fn addSmouthModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    source_paths: []const []const u8,
) !*std.Build.Module {
    const module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const options = b.addOptions();
    try base.addSourceFileOptions(b, options, source_paths);
    module.addOptions("src", options);
    module.addImport("smouth", module);
    return module;
}
