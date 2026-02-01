const std = @import("std");

/// Supported architectures for the kernel build.
/// - hosted: The architecture of the host machine.
/// - x86: The x86 architecture for freestanding OS development.
///
/// The index of each architecture in this enum corresponds to its position
/// in the `arches` array in the `Context` struct.
const Architecture = enum(u8) {
    hosted = 0,
    x86 = 1,
};

const ArchState = struct {
    type: Architecture,
    target: std.Build.ResolvedTarget,
    assembly_path: ?[]const u8 = null,
    modules: std.ArrayList(std.Build.Module.Import) = undefined,

    pub fn init(
        self: *ArchState,
        ctx: *Context,
        library: []const ArchLibrary,
    ) !void {
        for (library) |lib| {
            try self.modules.append(ctx.b.allocator, .{
                .name = lib.name,
                .module = ctx.b.createModule(.{
                    .root_source_file = ctx.b.path(lib.path),
                    .target = self.target,
                    .optimize = ctx.optimize,
                }),
            });
            if (self.assembly_path) |path| {
                if (lib.include_assembly) {
                    try addAssembly(ctx.b, self.modules.items[self.modules.items.len - 1].module, path);
                }
            }
        }
        // Add dependencies between modules.
        // E.g., arch depends on kernel and kernel depends on arch.
        for (0.., self.modules.items) |i, import| {
            for (0.., self.modules.items) |j, other| {
                if (i == j) {
                    continue;
                }
                import.module.addImport(other.name, other.module);
            }
        }
    }
};

const ArchLibrary = struct {
    name: []const u8,
    path: []const u8,
    include_assembly: bool = false,
};

const Context = struct {
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    arches: [@typeInfo(Architecture).@"enum".fields.len]ArchState,

    pub fn init(args: struct {
        b: *std.Build,
        optimize: std.builtin.OptimizeMode,
        modules: []const ArchLibrary,
        arches: [@typeInfo(Architecture).@"enum".fields.len]ArchState,
    }) !Context {
        var ctx = Context{
            .b = args.b,
            .optimize = args.optimize,
            .arches = args.arches,
        };

        for (&ctx.arches) |*state| {
            try state.init(&ctx, args.modules);
        }
        return ctx;
    }

    pub fn arch(ctx: *Context, key: Architecture) *ArchState {
        return &ctx.arches[@intFromEnum(key)];
    }

    pub fn createKernelModule(ctx: *Context, value: Architecture, path: []const u8) *std.Build.Module {
        var mod = ctx.b.createModule(.{
            .root_source_file = ctx.b.path(path),
            .target = ctx.arch(value).target,
            .optimize = ctx.optimize,
        });
        for (ctx.arch(value).modules.items) |import| {
            mod.addImport(import.name, import.module);
        }
        return mod;
    }
};

pub fn build(b: *std.Build) !void {
    var ctx = try Context.init(.{
        .b = b,
        .optimize = b.standardOptimizeOption(.{}),
        .modules = &[_]ArchLibrary{
            .{
                .name = "arch",
                .path = "src/arch/root.zig",
                .include_assembly = true,
            },
            .{
                .name = "kernel",
                .path = "src/kernel/root.zig",
            },
            .{
                .name = "stdk",
                .path = "src/stdk/root.zig",
            },
        },
        .arches = .{
            .{
                .type = .hosted,
                .target = b.standardTargetOptions(.{}),
            },
            .{
                .type = .x86,
                .assembly_path = "src/arch/x86",
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
    });

    try addKernelRun(&ctx, "src/main.zig", .x86);

    const run_unit_tests = b.addRunArtifact(b.addTest(.{
        .root_module = ctx.arches[@intFromEnum(Architecture.hosted)].modules.items[1].module,
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
        "-nographic",
        // "-serial","mon:stdio",
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

fn addAssembly(b: *std.Build, mod: *std.Build.Module, root: []const u8) !void {
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
