const Self = @This();
const objc = @import("extern.zig");
const Rect = @import("../../models/Rect.zig");
const Size = @import("../../models/Size.zig");

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

pub fn setTitle(self: *const Self, title: [*:0]const u8) void {
    objc.setTitle(self.handle, title);
}

pub fn getRect(self: *const Self) Rect {
    var rect: Rect = undefined;
    objc.getRect(self.handle, &rect);
    return rect;
}

pub fn setRect(self: *const Self, rect: Rect, animated: bool, display: bool) void {
    objc.setRect(self.handle, &rect, animated, display);
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

// Window constraints
pub fn setMinSize(self: *const Self, size: Size) void {
    objc.setMinSize(self.handle, &size);
}

pub fn setMaxSize(self: *const Self, size: Size) void {
    objc.setMaxSize(self.handle, &size);
}

// Window visibility
pub fn show(self: *const Self) void {
    objc.showWindow(self.handle);
}

pub fn hide(self: *const Self) void {
    objc.hideWindow(self.handle);
}

pub fn focus(self: *const Self) void {
    objc.focusWindow(self.handle);
}

pub fn isVisible(self: *const Self) bool {
    return objc.isWindowVisible(self.handle);
}

// Window state
pub fn minimize(self: *const Self) void {
    objc.minimizeWindow(self.handle);
}

pub fn maximize(self: *const Self) void {
    objc.maximizeWindow(self.handle);
}

pub fn close(self: *const Self) void {
    objc.closeWindow(self.handle);
}

pub fn fullscreen(self: *const Self) void {
    objc.toggleFullScreen(self.handle);
}

pub fn restore(self: *const Self) void {
    objc.restoreWindow(self.handle);
}

// Window level/ordering
pub fn setAlwaysOnTop(self: *const Self, on_top: bool) void {
    objc.setAlwaysOnTop(self.handle, on_top);
}

pub fn orderFront(self: *const Self) void {
    objc.orderWindowFront(self.handle);
}

pub fn orderBack(self: *const Self) void {
    objc.orderWindowBack(self.handle);
}

// Window dragging
pub fn startDragging(self: *const Self) void {
    objc.startDragging(self.handle);
}
