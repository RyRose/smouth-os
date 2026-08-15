//! Compile-time embedded source files and binary assets.

const src = @import("src");
const std = @import("std");

/// A source file embedded in the kernel image.
const EmbeddedSource = struct {
    []const u8,
    []const u8,
};

/// Source files keyed by their absolute build-time paths for DWARF lookup.
pub const source_files = std.StaticStringMap([]const u8).initComptime(genSourceFiles());

/// The startup audio clip embedded in the kernel image.
pub const smouth_wav: []const u8 = @embedFile("assets/smouth.wav");

/// Generates the source path-to-contents map used by DWARF lookup.
fn genSourceFiles() [src.absolute.len]EmbeddedSource {
    var sources: [src.absolute.len]EmbeddedSource = undefined;
    comptime var i = 0;
    inline for (src.absolute, src.relative) |absolute, relative| {
        const path = if (comptime relative[0] == 's' and relative[1] == 'r' and relative[2] == 'c' and relative[3] == '/')
            relative["src/".len..]
        else
            relative;
        sources[i][0] = absolute;
        sources[i][1] = @embedFile(path);
        i += 1;
    }
    return sources;
}
