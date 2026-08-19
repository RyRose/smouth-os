//! Architecture-neutral kernel initialization sequencing.

const os = @import("os");

/// Initializes common facilities and then the active architecture platform.
pub fn run() !void {
    os.arch.self.serial.init();
    os.arch.self.serial.write("\n");
    try os.arch.self.init.run();
}
