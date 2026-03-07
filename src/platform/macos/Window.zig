const Self = @This();
const objc = @import("extern.zig");

const DEFAULT_TRAFFIC_LIGHTS_SPACING: f64 = 22;

pub const StyleMask = enum(u8) {
    borderless,
    titled,
    closable,
    miniaturizable,
    resizable,
    unified_title_and_toolbar,
    full_screen,
    full_size_content_view,
};

handle: *anyopaque,

pub fn init(handle: *anyopaque) Self {
    return .{ .handle = handle };
}

pub fn setStyleMask(self: *const Self, style_mask: []const StyleMask) void {
    for (style_mask) |mask| {
        objc.insertStyleMask(self.handle, @intFromEnum(mask));
    }
}

pub fn setTitleVisibility(self: *const Self, is_visible: bool) void {
    objc.setTitleVisibility(self.handle, is_visible);
}

pub fn setTitleBarAppearsTransparent(self: *const Self, is_appears_transparent: bool) void {
    objc.setTitleBarAppearsTransparent(self.handle, is_appears_transparent);
}

pub fn setTrafficLightsPosition(self: *const Self, x: f64, y: f64, spacing: ?f64) void {
    objc.setTrafficLightsPosition(
        self.handle,
        x,
        y,
        spacing orelse DEFAULT_TRAFFIC_LIGHTS_SPACING,
    );
}

pub fn setMovableByWindowBackground(self: *const Self, is_movable: bool) void {
    objc.setMovableByWindowBackground(self.handle, is_movable);
}

pub fn setBackgroundColor(self: *const Self, r: f64, g: f64, b: f64, a: f64) void {
    objc.setWindowBackgroundColor(self.handle, r, g, b, a);
}

pub fn setWebViewTransparent(self: *const Self) void {
    objc.setWebViewTransparent(self.handle);
}
