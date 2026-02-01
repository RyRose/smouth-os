const src = @import("src");
const std = @import("std");

// kv pair type used to fill ComptimeStringMap
const EmbeddedAsset = struct {
    []const u8,
    []const u8,
};

// declare a StaticStringMap and fill it with our filenames and data
pub const srcFiles = std.StaticStringMap([]const u8).initComptime(genMap());

fn genMap() [src.absolute.len]EmbeddedAsset {
    var embassets: [src.absolute.len]EmbeddedAsset = undefined;
    comptime var i = 0;
    inline for (src.absolute, src.relative) |absolute, relative| {
        embassets[i][0] = absolute;
        embassets[i][1] = @embedFile(relative);
        i += 1;
    }
    return embassets;
}
