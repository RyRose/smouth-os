const std = @import("std");

const Architecture = enum(u2) {
    hosted = 0,
    x86 = 1,
};

const ArchState = struct {
    type: Architecture,
    target: std.Build.ResolvedTarget,
    module: *std.Build.Module = undefined,
};

const Context = struct {
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    archState: [@typeInfo(Architecture).@"enum".fields.len]ArchState,

    fn arch(self: *Context, key: Architecture) *ArchState {
        return &self.archState[@intFromEnum(key)];
    }

    fn createKernelModule(self: *Context, value: Architecture, path: []const u8) *std.Build.Module {
        return self.b.createModule(.{
            .root_source_file = self.b.path(path),
            .target = self.arch(value).target,
            .optimize = self.optimize,
            .imports = &.{.{
                .name = "arch",
                .module = self.arch(value).module,
            }},
        });
    }
};

pub fn build(b: *std.Build) !void {
    var ctx = Context{
        .b = b,
        .optimize = b.standardOptimizeOption(.{}),
        .archState = .{
            .{
                .type = .hosted,
                .target = b.standardTargetOptions(.{}),
            },
            .{
                .type = .x86,
                .target = b.resolveTargetQuery(.{
                    .cpu_arch = .x86,
                    .os_tag = .freestanding,
                    .abi = .none,
                    // I noticed that the kernel was triple-faulting when returning structs from
                    // functions and this seems to fix it. My guess is that it was doing
                    // a memcpy, which used SIMD instructions under the hood.
                    // see: https://wiki.osdev.org/Zig_Bare_Bones
                    .cpu_features_add = std.Target.x86.featureSet(&.{
                        .soft_float,
                    }),
                    .cpu_features_sub = std.Target.x86.featureSet(&.{
                        .avx,
                        .avx2,
                        .sse,
                        .sse2,
                        .mmx,
                    }),
                }),
            },
        },
    };

    ctx.arch(.hosted).module = b.createModule(.{
        .root_source_file = b.path("src/arch/root.zig"),
        .target = ctx.arch(Architecture.hosted).target,
        .optimize = ctx.optimize,
    });

    ctx.arch(.x86).module = b.createModule(.{
        .root_source_file = b.path("src/arch/root.zig"),
        .target = ctx.arch(Architecture.x86).target,
        .optimize = ctx.optimize,
    });
    try addAssembly(&ctx, ctx.arch(.x86).module, .x86);

    try addKernelRun(&ctx, "src/kernel/main.zig", .x86);

    const run_unit_tests = b.addRunArtifact(b.addTest(.{
        .root_module = ctx.createKernelModule(.hosted, "src/kernel/root.zig"),
    }));

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn addKernelRun(ctx: *Context, path: []const u8, arch: Architecture) !void {
    const base = std.fs.path.basename(path);
    const dotIndex = std.mem.indexOf(u8, base, ".");
    const key = if (dotIndex) |i| base[0..i] else base;
    const kernel = try addKernelExecutable(ctx, key, path, arch);

    const qemu_binary_name = switch (arch) {
        .hosted => return error.QEMUUnsupportedForHosted,
        .x86 => "qemu-system-x86_64",
    };

    const kernel_path = kernel.getEmittedBin();
    const run_cmd = ctx.b.addSystemCommand(&[_][]const u8{
        qemu_binary_name,
        // zig fmt: off
        "-serial","mon:stdio",
        // Allows exiting QEMU by writing to I/O port 0xf4 with a
        // non-zero exit code.
        "-device", "isa-debug-exit,iobase=0xf4,iosize=0x04",
        // Enables virtio sound device for audio output.
        // TODO: Make audio device configurable per OS. This assumes macOS.
        // https://www.qemu.org/docs/master/system/devices/virtio/virtio-snd.html#examples
        "-audiodev", "coreaudio,id=snd0",
        "-device", "virtio-sound-pci,audiodev=snd0",
        "-audiodev", "coreaudio,id=speaker",
        "-machine", "pcspk-audiodev=speaker",
        // zig fmt: on
    });
    run_cmd.addArg("-kernel");
    run_cmd.addFileArg(kernel_path);
    run_cmd.step.dependOn(ctx.b.getInstallStep());


    const run_name = try std.fmt.allocPrint(ctx.b.allocator, "run-{s}-{s}", .{ key, @tagName(arch) });
    defer ctx.b.allocator.free(run_name);
    const description = try std.fmt.allocPrint(ctx.b.allocator, "Run the {s} kernel in QEMU", .{key});
    defer ctx.b.allocator.free(description);
    const run_step = ctx.b.step(run_name, description);
    run_step.dependOn(&run_cmd.step);
}

fn addKernelExecutable(ctx: *Context, key: []const u8, path: []const u8, arch: Architecture) !*std.Build.Step.Compile {
    const name = try std.fmt.allocPrint(ctx.b.allocator, "kernel-{s}-{s}", .{ @tagName(arch), key });
    defer ctx.b.allocator.free(name);
    const kernel = ctx.b.addExecutable(.{
        .name = name,
        .root_module = ctx.createKernelModule(arch, path),
    });

    const linkerPath = try std.fmt.allocPrint(ctx.b.allocator, "src/arch/{s}/linker.ld", .{@tagName(arch)});
    defer ctx.b.allocator.free(linkerPath);
    kernel.setLinkerScript(ctx.b.path(linkerPath));
    ctx.b.installArtifact(kernel);
    return kernel;
}

fn addAssembly(ctx: *Context, mod: *std.Build.Module, arch: Architecture) !void {
    const root = switch (arch) {
        .hosted => return error.AssemblyNotSupportedForHosted,
        .x86 => "src/arch/x86",
    };

    var dir = try std.fs.cwd().openDir(root, .{ .iterate = true });
    defer dir.close();
    var it = dir.iterate();
    while (true) {
        const entry = try it.next();
        if (entry == null) break;

        const path = try std.fmt.allocPrint(ctx.b.allocator, "{s}/{s}", .{ root, entry.?.name });
        defer ctx.b.allocator.free(path);
        if (entry.?.kind == .file and std.mem.endsWith(u8, entry.?.name, ".S")) {
            mod.addAssemblyFile(ctx.b.path(path));
        }
    }
}
