//! A simple utility to copy a directory tree. Usage: `copytree <src> <dst>`
//! This is intended to be used in the build system to copy files from the
//! source tree to the build directory, and is not intended to be a
//! general-purpose file copying utility. It does not support copying symbolic
//! links, and will skip files that already exist in the destination
//! directory.

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len != 3) {
        std.log.err("Usage: copytree <src> <dst>", .{});
        return;
    }

    var src_dir = try std.Io.Dir.cwd().openDir(io, args[1], .{ .iterate = true });
    defer src_dir.close(io);

    var dest_dir = try std.Io.Dir.cwd().createDirPathOpen(io, args[2], .{});
    defer dest_dir.close(io);

    var walker = try src_dir.walk(gpa);
    defer walker.deinit();

    while (try walker.next(io)) |entry| {
        switch (entry.kind) {
            .file => {
                std.Io.Dir.copyFile(
                    entry.dir,
                    entry.basename,
                    dest_dir,
                    entry.path,
                    io,
                    .{},
                ) catch |err| {
                    if (err == error.PathAlreadyExists) {
                        continue;
                    }
                    return err;
                };
            },
            .directory => {
                dest_dir.createDir(io, entry.path, .default_dir) catch |err| {
                    if (err == error.PathAlreadyExists) {
                        continue;
                    }
                    return err;
                };
            },
            else => return error.UnexpectedEntryKind,
        }
    }
}
