const std = @import("std");

const Architecture = enum {
    x86,
};

pub fn build(b: *std.Build) !void {
    try addArch(b, "src/main.zig", .x86);
}

fn addArch(b: *std.Build, path: []const u8, arch: Architecture) !void {
    const base = std.fs.path.basename(path);
    const dotIndex = std.mem.indexOf(u8, base, ".");
    const key = if (dotIndex) |i| base[0..i] else base;
    const kernel = try addKernelExecutable(b, key, path, arch);

    const qemu_binary_name = switch (arch) {
        .x86 => "qemu-system-x86_64",
    };

    const kernel_path = kernel.getEmittedBin();
    const run_cmd = b.addSystemCommand(&[_][]const u8{
        qemu_binary_name,
        // zig fmt: off
        "-serial","mon:stdio",
        "-device", "isa-debug-exit,iobase=0xf4,iosize=0x04"
        // zig fmt: on
    });
    run_cmd.addArg("-kernel");
    run_cmd.addFileArg(kernel_path);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_name = try std.fmt.allocPrint(b.allocator, "run-{s}-{s}", .{ key, @tagName(arch) });
    defer b.allocator.free(run_name);
    const description = try std.fmt.allocPrint(b.allocator, "Run the {s} kernel in QEMU", .{key});
    defer b.allocator.free(description);
    const run_step = b.step(run_name, description);
    run_step.dependOn(&run_cmd.step);
}

fn addKernelExecutable(b: *std.Build, key: []const u8, path: []const u8, arch: Architecture) !*std.Build.Step.Compile {
    const Target = std.Target.x86;
    const target = b.resolveTargetQuery(.{
        .cpu_arch = switch (arch) {
            .x86 => .x86,
        },
        .os_tag = .freestanding,
        .abi = .none,
        // I noticed that the kernel was triple-faulting when returning structs from
        // functions and this seems to fix it. My guess is that it was doing
        // a memcpy, which used SIMD instructions under the hood.
        // see: https://wiki.osdev.org/Zig_Bare_Bones
        .cpu_features_add = Target.featureSet(&.{.soft_float}),
        .cpu_features_sub = Target.featureSet(&.{ .avx, .avx2, .sse, .sse2, .mmx }),
    });
    const optimize = b.standardOptimizeOption(.{});

    const name = try std.fmt.allocPrint(b.allocator, "kernel-{s}-{s}", .{ @tagName(arch), key });
    defer b.allocator.free(name);
    const kernel = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
        }),
    });
    try addAssembly(b, kernel.root_module, arch);

    const linkerPath = try std.fmt.allocPrint(b.allocator, "src/arch/{s}/linker.ld", .{@tagName(arch)});
    defer b.allocator.free(linkerPath);
    kernel.setLinkerScript(b.path(linkerPath));
    b.installArtifact(kernel);
    return kernel;
}

fn addAssembly(b: *std.Build, mod: *std.Build.Module, arch: Architecture) !void {
    const root = switch (arch) {
        .x86 => "src/arch/x86",
    };

    var dir = try std.fs.cwd().openDir(root, .{ .iterate = true });
    defer dir.close();
    var it = dir.iterate();
    while (true) {
        const entry = try it.next();
        if (entry == null) break;

        const path = try std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ root, entry.?.name });
        defer b.allocator.free(path);
        if (entry.?.kind == .file and std.mem.endsWith(u8, entry.?.name, ".S")) {
            mod.addAssemblyFile(b.path(path));
        }
    }
}
