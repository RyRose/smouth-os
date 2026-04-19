const std = @import("std");

/// Supported architectures for the kernel build.
/// - hosted: The architecture of the host machine.
/// - x86: The x86 architecture for freestanding OS development.
///
/// The index of each architecture in this enum corresponds to its position
/// in the `arches` array in the `Context` struct.
const Architecture = enum { hosted, x86 };

/// State for a specific architecture in the build process.
const ArchState = struct {
    /// The resolved target for this architecture.
    target: std.Build.ResolvedTarget,
    /// The list of modules created as part of initializing this architecture state.
    modules: std.ArrayListUnmanaged(std.Build.Module.Import) = .empty,

    /// Initialize the architecture state by creating modules from the provided libraries.
    pub fn init(self: *ArchState, ctx: *Context, library: []const Library) !void {
        for (library) |lib| try self.modules.append(ctx.b.allocator, try lib.create(ctx, self));
        // Add dependencies between modules.
        // E.g., arch depends on kernel and kernel depends on arch.
        for (self.modules.items) |import| {
            for (self.modules.items) |other| import.module.addImport(other.name, other.module);
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
    /// Whether to include source files as options in the module.
    include_source_option: bool = false,

    /// Create the library module for the given architecture state.
    pub fn create(self: Library, ctx: *Context, state: *ArchState) !std.Build.Module.Import {
        const mod = ctx.b.createModule(.{
            .root_source_file = self.path,
            .target = state.target,
            .optimize = ctx.optimize,
        });
        if (self.include_source_option) {
            const opts = ctx.b.addOptions();
            try addSourceAssetsOption(ctx.b, opts, ctx.source_paths);
            mod.addOptions("src", opts);
        }
        return .{ .name = self.name, .module = mod };
    }
};

/// The overall build context containing global settings and architecture states.
const Context = struct {
    /// The build object.
    b: *std.Build,
    /// The optimization mode for the build.
    optimize: std.builtin.OptimizeMode,
    /// The architecture states for the build.
    arches: [@typeInfo(Architecture).@"enum".fields.len]ArchState,
    /// The source paths to be embedded in the build.
    source_paths: []const []const u8,
    /// Build steps that must complete before compiling any kernel artifact.
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
        for (&ctx.arches) |*state| try state.init(&ctx, args.libraries);
        return ctx;
    }

    pub fn arch(ctx: *Context, key: Architecture) *ArchState {
        return &ctx.arches[@intFromEnum(key)];
    }

    pub fn createKernelModule(ctx: *Context, value: Architecture, path: []const u8) *std.Build.Module {
        const mod = ctx.b.createModule(.{
            .root_source_file = ctx.b.path(path),
            .target = ctx.arch(value).target,
            .optimize = ctx.optimize,
        });
        for (ctx.arch(value).modules.items) |import| mod.addImport(import.name, import.module);
        return mod;
    }

    pub fn moduleByName(ctx: *Context, value: Architecture, name: []const u8) !*std.Build.Module {
        for (ctx.arch(value).modules.items) |import| {
            if (std.mem.eql(u8, import.name, name)) return import.module;
        }
        return error.ModuleNotFound;
    }
};

pub fn build(b: *std.Build) !void {
    const stdlib_std_path = b.pathJoin(&.{ b.graph.zig_lib_directory.path orelse ".", "std" });

    // Create a symlink `std -> <zig_lib_dir>/std` at the project root so that
    // embed.zig can @embedFile("std/...") without copying the standard library.
    const std_link = b.addSystemCommand(&.{ "ln", "-sfn", stdlib_std_path, "std" });

    var ctx = try Context.init(.{
        .b = b,
        .step_dependencies = &.{&std_link.step},
        .source_paths = &.{ "src", stdlib_std_path },
        .optimize = b.standardOptimizeOption(.{}),
        .libraries = &.{
            .{ .name = "arch", .path = b.path("src/arch/root.zig") },
            .{ .name = "kernel", .path = b.path("src/kernel/root.zig") },
            .{ .name = "embed", .path = b.path("embed.zig"), .include_source_option = true },
        },
        .arches = .{
            .{ .target = b.standardTargetOptions(.{}) }, // hosted
            .{
                .target = b.resolveTargetQuery(.{ // x86
                    .cpu_arch = .x86,
                    .os_tag = .freestanding,
                    .abi = .none,
                    // I noticed that the kernel was triple-faulting when returning structs from
                    // functions and this seems to fix it. My guess is that it was doing a memcpy,
                    // which used SIMD instructions under the hood.
                    // see: https://wiki.osdev.org/Zig_Bare_Bones
                    .cpu_features_add = std.Target.x86.featureSet(&.{.soft_float}),
                    .cpu_features_sub = std.Target.x86.featureSet(&.{ .avx, .avx2, .sse, .sse2, .mmx }),
                }),
            },
        },
    });

    const x86_exe = addKernelExecutable(&ctx, "kernel-x86-main", "src/main.zig", .x86);
    b.step("run-x86", "Run the x86 kernel in QEMU.").dependOn(&(try buildQemu(&ctx, x86_exe, .x86)).step);

    const x86_test = try buildQemu(&ctx, addKernelTest(&ctx, "test-kernel-x86", .x86, try ctx.moduleByName(.x86, "kernel")), .x86);
    b.step("test-x86", "Run kernel x86 tests in QEMU.").dependOn(&x86_test.step);

    const arch_test = try buildQemu(&ctx, addKernelTest(&ctx, "test-arch-x86", .x86, try ctx.moduleByName(.x86, "arch")), .x86);
    b.step("test-arch-x86", "Run arch x86 tests in QEMU.").dependOn(&arch_test.step);

    const unit_test = b.addTest(.{ .root_module = try ctx.moduleByName(.hosted, "kernel") });
    unit_test.step.dependOn(&std_link.step);
    const run_unit = b.addRunArtifact(unit_test);
    b.step("test", "Run unit tests.").dependOn(&run_unit.step);

    const test_all = b.step("test-all", "Run all tests.");
    test_all.dependOn(&x86_test.step);
    test_all.dependOn(&arch_test.step);
    test_all.dependOn(&run_unit.step);
}

fn buildQemu(ctx: *Context, exe: *std.Build.Step.Compile, arch: Architecture) !*std.Build.Step.Run {
    const qemu = switch (arch) {
        .hosted => return error.QEMUUnsupportedForHosted,
        // qemu-system-i386 is the standard QEMU executable for emulating 32-bit x86 systems.
        .x86 => "qemu-system-i386",
    };
    const cmd = ctx.b.addSystemCommand(&.{qemu});

    // Disable graphical output and redirect serial to the terminal.
    cmd.addArg("-nographic");

    // Allow exiting QEMU by writing a non-zero exit code to I/O port 0xf4.
    cmd.addArgs(&.{ "-device", "isa-debug-exit,iobase=0xf4,iosize=0x04" });

    // Virtio sound device routed through the audio backend.
    cmd.addArgs(&.{ "-device", "virtio-sound-pci,audiodev=snd0" });

    // PC speaker for basic beep output.
    cmd.addArgs(&.{ "-machine", "pcspk-audiodev=snd0" });

    // Intel HDA for higher-quality audio output.
    cmd.addArgs(&.{ "-device", "intel-hda" });

    // HD Audio duplex for full-duplex input/output streams.
    cmd.addArgs(&.{ "-device", "hda-duplex,audiodev=snd0" });

    // Select audio backend based on host OS.
    const audio_backend = switch (ctx.b.graph.host.result.os.tag) {
        .macos => "coreaudio",
        else => "none",
    };
    cmd.addArgs(&.{ "-audiodev", ctx.b.fmt("{s},id=snd0", .{audio_backend}) });

    // Load the kernel binary directly without a bootloader or disk image.
    cmd.addArg("-kernel");
    cmd.addFileArg(exe.getEmittedBin());

    return cmd;
}

fn addKernelExecutable(ctx: *Context, name: []const u8, path: []const u8, arch: Architecture) *std.Build.Step.Compile {
    return finalizeKernelArtifact(ctx, arch, ctx.b.addExecutable(.{
        .name = name,
        .root_module = ctx.createKernelModule(arch, path),
    }));
}

fn addKernelTest(ctx: *Context, name: []const u8, arch: Architecture, mod: *std.Build.Module) *std.Build.Step.Compile {
    return finalizeKernelArtifact(ctx, arch, ctx.b.addTest(.{
        .name = name,
        .root_module = mod,
        .test_runner = .{ .path = ctx.b.path("src/main.zig"), .mode = .simple },
    }));
}

fn finalizeKernelArtifact(ctx: *Context, arch: Architecture, artifact: *std.Build.Step.Compile) *std.Build.Step.Compile {
    for (ctx.dependencies) |dep| artifact.step.dependOn(dep);
    artifact.setLinkerScript(ctx.b.path(ctx.b.pathJoin(&.{ "src/arch", @tagName(arch), "linker.ld" })));
    ctx.b.installArtifact(artifact);
    return artifact;
}

/// Walks `in_paths`, collects all `.zig` files, and adds their absolute and
/// relative paths as options on the build step under "absolute" and "relative" keys.
fn addSourceAssetsOption(b: *std.Build, options: *std.Build.Step.Options, in_paths: []const []const u8) !void {
    const io = b.graph.io;
    var abs_paths = try std.ArrayList([]const u8).initCapacity(b.allocator, 10);
    defer abs_paths.deinit(b.allocator);
    var rel_paths = try std.ArrayList([]const u8).initCapacity(b.allocator, 10);
    defer rel_paths.deinit(b.allocator);

    var buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
    for (in_paths) |in_path| {
        const n = try std.Io.Dir.cwd().realPathFile(io, in_path, buf[0..]);
        const abs_path = buf[0..n];
        var dir = try std.Io.Dir.openDirAbsolute(io, abs_path, .{ .iterate = true });
        defer dir.close(io);
        var it = try dir.walk(b.allocator);
        defer it.deinit();
        while (try it.next(io)) |file| {
            if (file.kind != .file or !std.mem.endsWith(u8, file.basename, ".zig")) continue;
            try abs_paths.append(b.allocator, b.dupe(b.pathJoin(&.{ abs_path, file.path })));
            try rel_paths.append(b.allocator, b.dupe(b.pathJoin(&.{ std.fs.path.basename(in_path), file.path })));
        }
    }
    options.addOption([]const []const u8, "absolute", abs_paths.items);
    options.addOption([]const []const u8, "relative", rel_paths.items);
}
