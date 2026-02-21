const Self = @This();

const web_view_c_mod = @import("webview");
const WindowConfig = @import("../models/WindowConfig.zig");

// Underlying webview abstraction over C implementation
web_view_c: web_view_c_mod.WebView,

pub fn build(config: WindowConfig) !Self {
    const w = web_view_c_mod.WebView.create(false, null);

    try w.setSize(config.window_size.width, config.window_size.height, .none);
    // Maybe it's better to use dupeZ here to prevent it from crashing from unknown memory layout
    // or just make it null term in Config and pass this problem from here to external side :)
    const null_term_title: [:0]const u8 = @ptrCast(config.window_title);
    try w.setTitle(null_term_title);

    return .{ .web_view_c = w };
}

pub fn load(self: Self, host: []const u8) !void {
    const host_term: [:0]const u8 = @ptrCast(host);
    try self.web_view_c.navigate(host_term);
}

pub fn run(self: Self) !void {
    try self.web_view_c.run();
}

pub fn deinit(self: Self) void {
    self.web_view_c.destroy() catch return;
}
