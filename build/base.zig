//! Base utilities for Zig build configurations.

const std = @import("std");

/// Runs an x86 kernel executable in QEMU.
pub fn addQemuRun(b: *std.Build, exe: *std.Build.Step.Compile) *std.Build.Step.Run {
    const cmd = b.addSystemCommand(&.{"qemu-system-i386"});
    cmd.addArg("-nographic");
    cmd.addArgs(&.{ "-device", "isa-debug-exit,iobase=0xf4,iosize=0x04" });
    cmd.addArgs(&.{ "-device", "virtio-sound-pci,audiodev=snd0" });
    cmd.addArgs(&.{ "-machine", "pcspk-audiodev=snd0" });
    cmd.addArgs(&.{ "-device", "intel-hda" });
    cmd.addArgs(&.{ "-device", "hda-duplex,audiodev=snd0" });

    const audio_backend = switch (b.graph.host.result.os.tag) {
        .macos => "coreaudio",
        else => "none",
    };
    cmd.addArgs(&.{ "-audiodev", b.fmt("{s},id=snd0", .{audio_backend}) });
    cmd.addArg("-kernel");
    cmd.addFileArg(exe.getEmittedBin());
    return cmd;
}

/// Adds the absolute and relative paths of all Zig files below `paths` as options.
fn addSourceFileOptions(b: *std.Build, options: *std.Build.Step.Options, paths: []const []const u8) !void {
    const io = b.graph.io;
    var absolute_paths = try std.ArrayList([]const u8).initCapacity(b.allocator, 10);
    defer absolute_paths.deinit(b.allocator);
    var relative_paths = try std.ArrayList([]const u8).initCapacity(b.allocator, 10);
    defer relative_paths.deinit(b.allocator);

    var buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    for (paths) |path| {
        const length = try std.Io.Dir.cwd().realPathFile(io, path, buffer[0..]);
        const absolute_path = buffer[0..length];
        var directory = try std.Io.Dir.openDirAbsolute(io, absolute_path, .{ .iterate = true });
        defer directory.close(io);
        var walker = try directory.walk(b.allocator);
        defer walker.deinit();
        while (try walker.next(io)) |file| {
            if (file.kind != .file or !std.mem.endsWith(u8, file.basename, ".zig")) continue;
            try absolute_paths.append(b.allocator, b.dupe(b.pathJoin(&.{ absolute_path, file.path })));
            try relative_paths.append(b.allocator, b.dupe(b.pathJoin(&.{ std.fs.path.basename(path), file.path })));
        }
    }
    options.addOption([]const []const u8, "absolute", absolute_paths.items);
    options.addOption([]const []const u8, "relative", relative_paths.items);
}

/// Creates the root smouth module for a build target, optimize mode, and source paths.
pub fn createRootModule(
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
    try addSourceFileOptions(b, options, source_paths);
    module.addOptions("src", options);
    // Allow the module to import itself as "os" so that source files can
    // be compiled with the same root module.
    module.addImport("os", module);
    return module;
}
