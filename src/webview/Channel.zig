const std = @import("std");
const WebView = @import("WebView.zig");

// Channels should be registered in comptime with comptime known data type
// to make them more predictable, and simplify code gen in future
pub fn Channel(comptime DataType: type) type {
    return struct {
        const Self = @This();

        name: []const u8,
        webview: *WebView,

        pub fn init(name: []const u8, webview: *WebView) Self {
            return .{
                .name = name,
                .webview = webview,
            };
        }

        pub fn postEvent(self: *Self, data: DataType) !void {
            try self.webview.emitEvent(self.name, data);
        }
    };
}
