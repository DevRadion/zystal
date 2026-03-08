const Self = @This();

const std = @import("std");
const webview_c_mod = @import("webview");
const log = @import("../Logger.zig").Logger("ScriptsRegistry");

allocator: std.mem.Allocator,
webview_c: webview_c_mod.WebView,
scripts: std.array_list.Managed(u8),
is_injected: bool,

pub fn init(allocator: std.mem.Allocator, webview_c: webview_c_mod.WebView) Self {
    log.debug("Init", .{});
    return .{
        .allocator = allocator,
        .webview_c = webview_c,
        .scripts = .init(allocator),
        .is_injected = false,
    };
}

pub fn deinit(self: *Self) void {
    log.debug("Deinit", .{});
    self.scripts.deinit();
}

pub fn registerScript(self: *Self, js_script: []const u8) !void {
    log.debug("Register script: {s}", .{js_script});
    try self.scripts.appendSlice(js_script);
}

pub fn inject(self: *Self) !void {
    const scripts_slice: [:0]const u8 = try self.allocator.dupeZ(u8, self.scripts.items);
    try self.webview_c.init(scripts_slice);

    log.debug("Injected: is_injected: {any}", .{self.is_injected});

    self.allocator.free(scripts_slice);
    self.is_injected = true;
}
