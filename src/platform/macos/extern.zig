pub extern fn insertStyleMask(window_handle: *anyopaque, style_mask: u8) void;
pub extern fn removeStyleMask(window_handle: *anyopaque, style_mask: u8) void;

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
