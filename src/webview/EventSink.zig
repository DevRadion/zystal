const std = @import("std");

const webview_c_mod = @import("webview");

const Logger = @import("../logger.zig").Logger;

const Self = @This();

const log = Logger("EventSink");

allocator: std.mem.Allocator,
webview_c: webview_c_mod.WebView,

pub fn init(allocator: std.mem.Allocator, webview_c: webview_c_mod.WebView) !Self {
    // Function to simplify event emit later
    try webview_c.init(
        \\window.__nativeEmit = (name, detailJson) => {
        \\  let detail;
        \\  try { detail = detailJson ? JSON.parse(detailJson) : undefined; }
        \\  catch { detail = detailJson; }
        \\  window.dispatchEvent(new CustomEvent(name, { detail }));
        \\};
    );

    return .{
        .allocator = allocator,
        .webview_c = webview_c,
    };
}

pub fn emitEvent(self: *Self, name: []const u8, data: anytype) !void {
    var buffer = std.Io.Writer.Allocating.init(self.allocator);
    defer buffer.deinit();

    try std.json.Stringify.value(data, .{}, &buffer.writer);
    const json_string = try buffer.toOwnedSlice();
    defer self.allocator.free(json_string);

    const js_string = try std.fmt.allocPrintSentinel(
        self.allocator,
        "window.__nativeEmit(\"{s}\", {s});",
        .{ name, json_string },
        0,
    );
    defer self.allocator.free(js_string);

    log.debug("emitEvent -> name: {s}, data: {any}", .{ name, data });

    try self.webview_c.eval(js_string);
}
