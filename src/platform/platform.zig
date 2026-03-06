const builtin = @import("builtin");

pub const window = switch (builtin.os.tag) {
    .macos => @import("macos/window.zig"),
    else => @panic("Unsupported platform"),
};
