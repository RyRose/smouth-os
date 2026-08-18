const os = @import("os");
const std = @import("std");

const log = std.log.scoped(.kmain);

pub fn run() !void {
    log.debug("Starting kernel main", .{});

    try os.kernel.virtio_sound.play(os.embed.smouth_wav);
}
