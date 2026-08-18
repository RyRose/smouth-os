const std = @import("std");
const base = @import("build/base.zig");

pub fn build(b: *std.Build) !void {

    // Create a symlink `src/std -> <zig_lib_dir>/std` so source files can be
    // embedded without copying the standard library.
    const stdlib_std_path = b.pathJoin(&.{ b.graph.zig_lib_directory.path orelse ".", "std" });
    const std_link = b.addSystemCommand(&.{ "ln", "-sfn", stdlib_std_path, "src/std" });
    const prepare_freestanding = b.step("prepare-freestanding", "Prepare freestanding build inputs.");
    prepare_freestanding.dependOn(&std_link.step);

    // Path to the root source file for the kernel module.
    // This is the entry point to the kernel as a library.
    const root_path = b.path("src/root.zig");

    // Path to the main source file for the kernel executable.
    // This is used as the entry point to the kernel as an executable.
    const main_path = b.path("src/main.zig");

    // Name of the self-import module for the kernel. This is used to import
    // the kernel into itself.
    const root_import = "os";

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
    const x86_module = try base.createModule(b, .{
        .create = .{
            .root_source_file = root_path,
            .target = x86_target,
            .optimize = optimize,
        },
        .source_paths = source_paths,
        .self_import = root_import,
    });

    // Create the main x86 kernel executable.
    const x86_main_compile = b.addExecutable(.{
        .name = "kernel-main-x86",
        .root_module = try base.createModule(b, .{
            .create = .{
                .root_source_file = main_path,
                .target = x86_target,
                .optimize = optimize,
                .imports = &.{.{ .name = root_import, .module = x86_module }},
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
        .test_runner = .{ .path = main_path, .mode = .simple },
    });
    x86_test_compile.step.dependOn(prepare_freestanding);
    x86_test_compile.setLinkerScript(x86_linker_path);
    b.installArtifact(x86_test_compile);
    const x86_test_run = base.addQemuRun(b, x86_test_compile);
    b.step("test-x86", "Run source module tests in QEMU on x86.").dependOn(&x86_test_run.step);

    // Create the hosted unit test executable and run it natively. Source paths
    // are excluded to improve build times since they are only used for stack
    // traces in freestanding environments.
    const hosted_module = try base.createModule(b, .{
        .create = .{
            .root_source_file = root_path,
            .target = b.standardTargetOptions(.{}),
            .optimize = optimize,
        },
        .self_import = root_import,
    });
    const unit_test_compile = b.addTest(.{ .root_module = hosted_module });
    const unit_test_run = b.addRunArtifact(unit_test_compile);
    b.step("test", "Run unit tests.").dependOn(&unit_test_run.step);

    const test_all = b.step("test-all", "Run all tests.");
    test_all.dependOn(&x86_test_run.step);
    test_all.dependOn(&unit_test_run.step);
}
