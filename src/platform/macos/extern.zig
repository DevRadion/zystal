const Rect = @import("../../models/Rect.zig");
const Size = @import("../../models/Size.zig");

pub extern fn insertStyleMask(window_handle: *anyopaque, style_mask: u8) void;
pub extern fn removeStyleMask(window_handle: *anyopaque, style_mask: u8) void;

pub extern fn setTitle(window_handle: *anyopaque, title: [*:0]const u8) void;

pub extern fn getRect(window_handle: *anyopaque, out: *Rect) void;
pub extern fn setRect(window_handle: *anyopaque, rect: *const Rect, animated: bool, display: bool) void;

// titleVisibility
// NSWindowTitleVisible
// NSWindowTitleHidden
pub extern fn setTitleVisibility(window_handle: *anyopaque, is_visible: bool) void;

// titlebarAppearsTransparent
pub extern fn setTitleBarAppearsTransparent(window_handle: *anyopaque, is_appears_transparent: bool) void;

pub extern fn setTrafficLightsPosition(window_handle: *anyopaque, x: f64, y: f64, spacing: f64) void;

pub extern fn setMovableByWindowBackground(window_handle: *anyopaque, is_movable: bool) void;

pub extern fn setWindowBackgroundColor(window_handle: *anyopaque, r: f64, g: f64, b: f64, a: f64) void;
pub extern fn setWebViewTransparent(window_handle: *anyopaque) void;

// Window constraints
pub extern fn setMinSize(window_handle: *anyopaque, size: *const Size) void;
pub extern fn setMaxSize(window_handle: *anyopaque, size: *const Size) void;

// Window visibility
pub extern fn showWindow(window_handle: *anyopaque) void;
pub extern fn hideWindow(window_handle: *anyopaque) void;
pub extern fn focusWindow(window_handle: *anyopaque) void;
pub extern fn isWindowVisible(window_handle: *anyopaque) bool;

// Window state
pub extern fn minimizeWindow(window_handle: *anyopaque) void;
pub extern fn maximizeWindow(window_handle: *anyopaque) void;
pub extern fn closeWindow(window_handle: *anyopaque) void;
pub extern fn toggleFullScreen(window_handle: *anyopaque) void;
pub extern fn restoreWindow(window_handle: *anyopaque) void;

// Window level/ordering
pub extern fn setAlwaysOnTop(window_handle: *anyopaque, on_top: bool) void;
pub extern fn orderWindowFront(window_handle: *anyopaque) void;
pub extern fn orderWindowBack(window_handle: *anyopaque) void;

// Window dragging
pub extern fn startDragging(window_handle: *anyopaque) void;
