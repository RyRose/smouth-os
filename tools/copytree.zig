//! A simple utility to copy a directory tree. Usage: `copytree <src> <dst>`
//! This is intended to be used in the build system to copy files from the
//! source tree to the build directory, and is not intended to be a
//! general-purpose file copying utility. It does not support copying symbolic
//! links, and will skip files that already exist in the destination
//! directory.

const std = @import("std");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len != 3) {
        std.debug.print("Usage: copytree <src> <dst>\n", .{});
        return;
    }

    var src_dir = try std.fs.cwd().openDir(args[1], .{});
    defer src_dir.close();

    var dest_dir = try std.fs.cwd().makeOpenPath(args[2], .{});
    defer dest_dir.close();

    var walker = try src_dir.walk(gpa);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        switch (entry.kind) {
            .file => {
                entry.dir.copyFile(
                    entry.basename,
                    dest_dir,
                    entry.path,
                    .{},
                ) catch |err| {
                    if (err == error.PathAlreadyExists) {
                        continue;
                    }
                    return err;
                };
            },
            .directory => {
                dest_dir.makeDir(entry.path) catch |err| {
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
