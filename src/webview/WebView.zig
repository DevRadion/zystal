const Self = @This();

const std = @import("std");
const log = @import("../log.zig");
const webview_c_mod = @import("webview");
const WindowConfig = @import("../models/WindowConfig.zig");
const BindManager = @import("BindManager.zig");

pub const EventHandlerFunc = fn ([]const u8) void;

allocator: std.mem.Allocator,
webview_c: webview_c_mod.WebView,
bind_manager: BindManager,

pub fn build(allocator: std.mem.Allocator, config: WindowConfig) !Self {
    const w = webview_c_mod.WebView.create(config.dev_tools, null);

    // Function to simplify event emit later
    try w.init(
        \\window.__nativeEmit = (name, detailJson) => {
        \\  let detail;
        \\  try { detail = detailJson ? JSON.parse(detailJson) : undefined; }
        \\  catch { detail = detailJson; }
        \\  window.dispatchEvent(new CustomEvent(name, { detail }));
        \\};
    );

    try w.setSize(config.window_size.width, config.window_size.height, .none);
    // Maybe it's better to use dupeZ here to prevent it from crashing from unknown memory layout
    // or just make it null term in Config and pass this problem from here to external side :)
    const null_term_title: [:0]const u8 = @ptrCast(config.window_title);
    try w.setTitle(null_term_title);

    return .{
        .allocator = allocator,
        .webview_c = w,
        .bind_manager = BindManager.init(allocator, w),
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
    std.debug.print("Sending event -> {s}\n", .{json_string});

    try self.webview_c.eval(js_string);
}

pub fn load(self: Self, host: [:0]const u8) !void {
    try self.webview_c.navigate(host);
}

pub fn registerFunc(self: *Self, func_name: []const u8, comptime handler: anytype) !void {
    try self.bind_manager.registerFunc(func_name, handler);
}

pub fn registerDecls(self: *Self, comptime Owner: type, owner: *Owner) !void {
    try self.bind_manager.registerDecls(Owner, owner);
}

pub fn run(self: Self) !void {
    try self.webview_c.run();
}

pub fn deinit(self: *Self) void {
    self.bind_manager.deinit();
    self.webview_c.destroy() catch return;
}
