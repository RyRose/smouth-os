const std = @import("std");
const base = @import("build/base.zig");

pub fn build(b: *std.Build) !void {

    // Create a symlink `std -> <zig_lib_dir>/std` at the project root so that
    // embed.zig can @embedFile("std/...") without copying the standard library.
    const stdlib_std_path = b.pathJoin(&.{ b.graph.zig_lib_directory.path orelse ".", "std" });
    const std_link = b.addSystemCommand(&.{ "ln", "-sfn", stdlib_std_path, "std" });

    const prepare = b.step("prepare", "Prepare build inputs.");
    prepare.dependOn(&std_link.step);
    const optimize = b.standardOptimizeOption(.{});
    const module_definitions: []const base.ModuleDefinition = &.{
        .{ .name = "arch", .root_source_file = b.path("src/arch/root.zig") },
        .{ .name = "kernel", .root_source_file = b.path("src/kernel/root.zig") },
        .{ .name = "embed", .root_source_file = b.path("embed.zig"), .source_paths = &.{ "src", stdlib_std_path } },
    };

    const hosted_target = b.standardTargetOptions(.{});
    const hosted_modules = try base.addModules(b, hosted_target, optimize, module_definitions);

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
    const x86_modules = try base.addModules(b, x86_target, optimize, module_definitions);

    // Build the x86 kernel executable and install it as an artifact.
    const x86_exe = b.addExecutable(.{
        .name = "kernel-x86-main",
        .root_module = base.addRootModule(b, x86_target, optimize, b.path("src/main.zig"), x86_modules),
    });
    x86_exe.step.dependOn(prepare);
    x86_exe.setLinkerScript(b.path("src/arch/x86/linker.ld"));
    b.installArtifact(x86_exe);
    const x86_run = base.buildQemu(b, x86_exe);
    b.step("run-x86", "Run the x86 kernel in QEMU.").dependOn(&x86_run.step);

    const x86_test_artifact = b.addTest(.{
        .name = "test-kernel-x86",
        .root_module = try base.getModule(x86_modules, "kernel"),
        .test_runner = .{ .path = b.path("src/main.zig"), .mode = .simple },
    });
    x86_test_artifact.step.dependOn(prepare);
    x86_test_artifact.setLinkerScript(b.path("src/arch/x86/linker.ld"));
    b.installArtifact(x86_test_artifact);
    const x86_test = base.buildQemu(b, x86_test_artifact);
    b.step("test-x86", "Run kernel x86 tests in QEMU.").dependOn(&x86_test.step);

    const arch_test_artifact = b.addTest(.{
        .name = "test-arch-x86",
        .root_module = try base.getModule(x86_modules, "arch"),
        .test_runner = .{ .path = b.path("src/main.zig"), .mode = .simple },
    });
    arch_test_artifact.step.dependOn(prepare);
    arch_test_artifact.setLinkerScript(b.path("src/arch/x86/linker.ld"));
    b.installArtifact(arch_test_artifact);
    const arch_test = base.buildQemu(b, arch_test_artifact);
    b.step("test-arch-x86", "Run arch x86 tests in QEMU.").dependOn(&arch_test.step);

    const unit_test = b.addTest(.{ .root_module = try base.getModule(hosted_modules, "kernel") });
    unit_test.step.dependOn(prepare);
    const run_unit = b.addRunArtifact(unit_test);
    b.step("test", "Run unit tests.").dependOn(&run_unit.step);

    const test_all = b.step("test-all", "Run all tests.");
    test_all.dependOn(&x86_test.step);
    test_all.dependOn(&arch_test.step);
    test_all.dependOn(&run_unit.step);
}
