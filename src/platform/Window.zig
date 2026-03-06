const Self = @This();

const builtin = @import("builtin");

const MacosWindow = @import("macos/Window.zig");

pub const PlatformTag = enum {
    macos,
    windows,
    linux,
};

handle: *anyopaque,

pub fn init(handle: *anyopaque) Self {
    return .{ .handle = handle };
}

pub fn platform(self: *const Self, comptime platform_tag: PlatformTag) ?PlatformWindow(platform_tag) {
    if (comptime isCurrentPlatform(platform_tag)) {
        return PlatformWindow(platform_tag).init(self.handle);
    }

    return null;
}

pub fn PlatformWindow(comptime platform_tag: PlatformTag) type {
    return switch (platform_tag) {
        .macos => MacosWindow,
        else => @compileError("Unsupported platform"),
    };
}

// Private

fn isCurrentPlatform(comptime platform_tag: PlatformTag) bool {
    return switch (platform_tag) {
        .macos => builtin.os.tag == .macos,
        .windows => builtin.os.tag == .windows,
        .linux => builtin.os.tag == .linux,
    };
}
