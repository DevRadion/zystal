const Self = @This();

const builtin = @import("builtin");

const MacosWindow = @import("macos/Window.zig");
const Rect = @import("../models/Rect.zig");
const Size = @import("../models/Size.zig");

pub const PlatformTag = enum {
    macos,
    windows,
    linux,

    pub fn current() PlatformTag {
        return switch (builtin.os.tag) {
            .macos => .macos,
            .windows => .windows,
            .linux => .linux,
            else => @compileError("Unsupported platform"),
        };
    }
};

handle: *anyopaque,

pub fn init(handle: *anyopaque) Self {
    return .{ .handle = handle };
}

pub fn platform(self: *const Self, comptime platform_tag: PlatformTag) ?PlatformWindow(platform_tag) {
    if (comptime PlatformTag.current() == platform_tag) {
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

pub fn setTitle(self: *const Self, title: [*:0]const u8) void {
    if (self.platform(.current())) |plt_wnd| {
        plt_wnd.setTitle(title);
    }
}

pub fn getRect(self: *const Self) ?Rect {
    if (self.platform(.current())) |w|
        return w.getRect();

    return null;
}

pub fn setRect(self: *const Self, rect: Rect, animated: bool, display: bool) void {
    if (self.platform(.current())) |w|
        return w.setRect(rect, animated, display);
}

// Promoted from macOS platform API
pub fn setBackgroundColor(self: *const Self, r: f64, g: f64, b: f64, a: f64) void {
    if (self.platform(.current())) |w|
        w.setBackgroundColor(r, g, b, a);
}

pub fn setTitleVisibility(self: *const Self, is_visible: bool) void {
    if (self.platform(.current())) |w|
        w.setTitleVisibility(is_visible);
}

pub fn setMovableByWindowBackground(self: *const Self, is_movable: bool) void {
    if (self.platform(.current())) |w|
        w.setMovableByWindowBackground(is_movable);
}

pub fn setWebViewTransparent(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.setWebViewTransparent();
}

// Window constraints
pub fn setMinSize(self: *const Self, size: Size) void {
    if (self.platform(.current())) |w|
        w.setMinSize(size);
}

pub fn setMaxSize(self: *const Self, size: Size) void {
    if (self.platform(.current())) |w|
        w.setMaxSize(size);
}

// Window visibility
pub fn show(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.show();
}

pub fn hide(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.hide();
}

pub fn focus(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.focus();
}

pub fn isVisible(self: *const Self) ?bool {
    if (self.platform(.current())) |w|
        return w.isVisible();
    return null;
}

// Window state
pub fn minimize(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.minimize();
}

pub fn maximize(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.maximize();
}

pub fn close(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.close();
}

pub fn fullscreen(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.fullscreen();
}

pub fn restore(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.restore();
}

// Window level/ordering
pub fn setAlwaysOnTop(self: *const Self, on_top: bool) void {
    if (self.platform(.current())) |w|
        w.setAlwaysOnTop(on_top);
}

pub fn orderFront(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.orderFront();
}

pub fn orderBack(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.orderBack();
}

// Window dragging
pub fn startDragging(self: *const Self) void {
    if (self.platform(.current())) |w|
        w.startDragging();
}
