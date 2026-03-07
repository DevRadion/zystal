const Self = @This();

const std = @import("std");
const Logger = @import("../logger.zig").Logger;
const webview_c_mod = @import("webview");
const WindowConfig = @import("../models/WindowConfig.zig");
const BindManager = @import("BindManager.zig");

const log = Logger("WebView");
pub const EventHandlerFunc = fn ([]const u8) void;

allocator: std.mem.Allocator,
webview_c: webview_c_mod.WebView,
bind_manager: BindManager,

pub fn build(allocator: std.mem.Allocator, config: WindowConfig) !Self {
    const w = webview_c_mod.WebView.create(config.dev_tools, null);

    return .{
        .allocator = allocator,
        .webview_c = w,
        .bind_manager = BindManager.init(allocator, w),
    };
}

pub fn load(self: Self, host: [:0]const u8) !void {
    try self.webview_c.navigate(host);
}

pub fn registerDecls(self: *Self, comptime Owner: type, owner: *Owner) !void {
    try self.bind_manager.registerDecls(Owner, owner);
}

pub fn run(self: Self) !void {
    try self.webview_c.run();
}

pub fn getNativeHandle(self: *const Self) ?*anyopaque {
    return self.webview_c.getNativeHandle(.ui_window) orelse null;
}

pub fn deinit(self: *Self) void {
    self.bind_manager.deinit();
    self.webview_c.destroy() catch return;
}
