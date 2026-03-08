const std = @import("std");
const WebView = @import("WebView.zig");
const Self = @This();
allocator: std.mem.Allocator,
webview: *WebView,

pub fn init(allocator: std.mem.Allocator, webview: *WebView) Self {
    return .{
        .allocator = allocator,
        .webview = webview,
    };
}

pub fn emitEvent(self: *const Self, name: []const u8, data: anytype) !void {
    var buffer = std.Io.Writer.Allocating.init(self.allocator);
    defer buffer.deinit();

    try std.json.Stringify.value(data, .{}, &buffer.writer);
    const json_string = try buffer.toOwnedSlice();
    defer self.allocator.free(json_string);

    try self.webview.emitSerializedEvent(name, json_string);
}
