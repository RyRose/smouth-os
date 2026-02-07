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

/// State for a specific architecture in the build process.
const ArchState = struct {
    /// The architecture type.
    type: Architecture,
    /// The resolved target for this architecture.
    target: std.Build.ResolvedTarget,
    /// Optional path to assembly files for this architecture.
    assembly_path: ?[]const u8 = null,
    /// The list of modules to be created as part of
    /// initializing this architecture state.
    modules: std.ArrayList(std.Build.Module.Import) = undefined,

    /// Initialize the architecture state by creating modules from the
    /// provided libraries.
    pub fn init(
        self: *ArchState,
        ctx: *Context,
        library: []const Library,
    ) !void {
        for (library) |lib| {
            try self.modules.append(ctx.b.allocator, try lib.create(ctx, self));
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

/// A library module to be included in the architecture build.
/// Will be created for each architecture state.
const Library = struct {
    /// The name of the library module.
    name: []const u8,
    /// The path to the root source file of the library.
    path: std.Build.LazyPath,
    /// Whether to include assembly files from the architecture's assembly path.
    include_assembly: bool = false,
    /// Whether to include source files as options in the module.
    include_source_option: bool = false,

    /// Create the library module for the given architecture state.
    pub fn create(
        self: Library,
        ctx: *Context,
        state: *ArchState,
    ) !std.Build.Module.Import {
        const mod = ctx.b.createModule(.{
            .root_source_file = self.path,
            .target = state.target,
            .optimize = ctx.optimize,
        });
        if (self.include_assembly) {
            if (state.assembly_path) |path| {
                try addAssembly(ctx.b, mod, path);
            }
        }
        if (self.include_source_option) {
            const opts = ctx.b.addOptions();
            try addSourceAssetsOption(ctx.b, opts, ctx.source_paths);
            mod.addOptions("src", opts);
        }
        return .{
            .name = self.name,
            .module = mod,
        };
    }
};

/// The overall build context containing global settings and architecture
/// states.
const Context = struct {
    /// The build object.
    b: *std.Build,
    /// The optimization mode for the build.
    optimize: std.builtin.OptimizeMode,
    /// The architecture states for the build.
    arches: [@typeInfo(Architecture).@"enum".fields.len]ArchState,
    /// The source paths to be embedded in the build.
    source_paths: []const []const u8,
    /// Any build step dependencies for this library.
    dependencies: []const *std.Build.Step,

    pub fn init(args: struct {
        b: *std.Build,
        optimize: std.builtin.OptimizeMode,
        libraries: []const Library,
        arches: [@typeInfo(Architecture).@"enum".fields.len]ArchState,
        source_paths: []const []const u8,
        step_dependencies: []const *std.Build.Step = &.{},
    }) !Context {
        var ctx = Context{
            .b = args.b,
            .optimize = args.optimize,
            .arches = args.arches,
            .source_paths = args.source_paths,
            .dependencies = args.step_dependencies,
        };
        for (&ctx.arches) |*state| {
            try state.init(&ctx, args.libraries);
        }
        return ctx;
    }

    pub fn arch(ctx: *Context, key: Architecture) *ArchState {
        return &ctx.arches[@intFromEnum(key)];
    }

    pub fn createKernelModule(
        ctx: *Context,
        value: Architecture,
        path: []const u8,
    ) *std.Build.Module {
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

    // Set up generated source assets directory.
    const wf_step = b.addWriteFiles();
    const embed_path = wf_step.addCopyFile(
        b.path("gen/embed.zig"),
        "embed.zig",
    );
    _ = wf_step.addCopyDirectory(
        b.path("src"),
        "src",
        .{ .include_extensions = &.{"zig"} },
    );
    const rsync_step = b.addSystemCommand(&.{"rsync"});
    rsync_step.setCwd(wf_step.getDirectory());
    rsync_step.addArg("--archive");
    rsync_step.addArg(
        b.pathJoin(&.{ b.graph.zig_lib_directory.path orelse ".", "std" }),
    );
    rsync_step.addArg(".");
    rsync_step.step.dependOn(&wf_step.step);

    var ctx = try Context.init(.{
        .b = b,
        .step_dependencies = &[_]*std.Build.Step{&rsync_step.step},
        .source_paths = &[_][]const u8{
            "src",
            b.pathJoin(&.{ b.graph.zig_lib_directory.path orelse ".", "std" }),
        },
        .optimize = b.standardOptimizeOption(.{}),
        .libraries = &[_]Library{
            .{
                .name = "arch",
                .path = b.path("src/arch/root.zig"),
                .include_assembly = true,
            },
            .{
                .name = "kernel",
                .path = b.path("src/kernel/root.zig"),
            },
            .{
                .name = "stdk",
                .path = b.path("src/stdk/root.zig"),
            },
            .{
                .name = "embed",
                .path = embed_path,
                .include_source_option = true,
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
                    // I noticed that the kernel was triple-faulting when
                    // returning structs from functions and this seems to fix
                    // it. My guess is that it was doing
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
        .root_module = ctx.arch(.hosted).modules.items[1].module,
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
    // zig fmt: off
    const run_cmd = ctx.b.addSystemCommand(&[_][]const u8{
        qemu_binary_name,
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
    });
    // zig fmt: on
    run_cmd.addArg("-kernel");
    run_cmd.addFileArg(kernel_path);
    run_cmd.step.dependOn(ctx.b.getInstallStep());

    const run_step = ctx.b.step(
        ctx.b.fmt("run-{s}-{s}", .{ key, @tagName(arch) }),
        ctx.b.fmt("Run the {s} kernel in QEMU", .{key}),
    );
    run_step.dependOn(&run_cmd.step);
}

fn addKernelExecutable(
    ctx: *Context,
    key: []const u8,
    path: []const u8,
    arch: Architecture,
) !*std.Build.Step.Compile {
    const kernel = ctx.b.addExecutable(.{
        .name = ctx.b.fmt("kernel-{s}-{s}", .{ @tagName(arch), key }),
        .root_module = ctx.createKernelModule(arch, path),
    });
    for (ctx.dependencies) |dep| {
        kernel.step.dependOn(dep);
    }
    kernel.setLinkerScript(
        ctx.b.path(
            ctx.b.pathJoin(&.{ "src/arch", @tagName(arch), "linker.ld" }),
        ),
    );
    ctx.b.installArtifact(kernel);
    return kernel;
}

fn addAssembly(b: *std.Build, mod: *std.Build.Module, root: []const u8) !void {
    var dir = try std.fs.cwd().openDir(root, .{ .iterate = true });
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |file| {
        if (file.kind != .file) {
            continue;
        }
        if (!std.mem.endsWith(u8, file.name, ".S")) {
            continue;
        }
        mod.addAssemblyFile(b.path(b.pathJoin(&.{ root, file.name })));
    }
}

fn addSourceAssetsOption(
    b: *std.Build,
    options: *std.Build.Step.Options,
    in_paths: []const []const u8,
) !void {
    var abs_paths = try std.ArrayList([]const u8).initCapacity(b.allocator, 10);
    defer abs_paths.deinit(b.allocator);
    var rel_paths = try std.ArrayList([]const u8).initCapacity(b.allocator, 10);
    defer rel_paths.deinit(b.allocator);

    var buf: [std.fs.max_path_bytes]u8 = undefined;
    for (in_paths) |in_path| {
        const abs_path = try std.fs.cwd().realpath(in_path, buf[0..]);
        var dir = try std.fs.openDirAbsolute(abs_path, .{ .iterate = true });
        defer dir.close();
        var it = try dir.walk(b.allocator);
        while (try it.next()) |file| {
            if (file.kind != .file) {
                continue;
            }
            if (!std.mem.endsWith(u8, file.basename, ".zig")) {
                continue;
            }

            try abs_paths.append(
                b.allocator,
                b.dupe(b.pathJoin(&.{ abs_path, file.path })),
            );
            try rel_paths.append(
                b.allocator,
                b.dupe(
                    b.pathJoin(&.{ std.fs.path.basename(in_path), file.path }),
                ),
            );
        }
    }
    options.addOption([]const []const u8, "absolute", abs_paths.items);
    options.addOption([]const []const u8, "relative", rel_paths.items);
}
