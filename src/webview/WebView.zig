const Self = @This();

const std = @import("std");
const Logger = @import("../logger.zig").Logger;
const webview_c_mod = @import("webview");
const BindManager = @import("BindManager.zig");
const ScriptsRegistry = @import("ScriptsRegistry.zig");
const Window = @import("../platform/Window.zig");

const log = Logger("WebView");
pub const EventHandlerFunc = fn ([]const u8) void;

allocator: std.mem.Allocator,
webview_c: webview_c_mod.WebView,
bind_manager: BindManager,

pub fn init(allocator: std.mem.Allocator, dev_tools: bool) !Self {
    const w = webview_c_mod.WebView.create(dev_tools, null);

    return .{
        .allocator = allocator,
        .webview_c = w,
        .bind_manager = BindManager.init(allocator, w),
    };
}

pub fn initDragRegion(self: *Self, scripts_registry: *ScriptsRegistry) !void {
    try scripts_registry.registerScript(
        \\document.addEventListener('mousedown', function(e) {
        \\  if (e.button !== 0) return;
        \\  let el = e.target;
        \\  while (el) {
        \\    if (el.hasAttribute && el.hasAttribute('data-zystal-no-drag')) return;
        \\    if (el.hasAttribute && el.hasAttribute('data-zystal-draggable')) {
        \\      e.preventDefault();
        \\      __zystal_startDrag();
        \\      return;
        \\    }
        \\    el = el.parentElement;
        \\  }
        \\});
    );

    const DragCtx = struct {
        webview: *Self,
    };

    const startDragFn = struct {
        fn callback(id: [*:0]const u8, _: [*:0]const u8, ctx: ?*anyopaque) callconv(.c) void {
            const drag_ctx: *DragCtx = @ptrCast(@alignCast(ctx orelse return));
            const handle = drag_ctx.webview.getNativeHandle() orelse return;
            const window = Window.init(handle);
            window.startDragging();
            drag_ctx.webview.webview_c.ret(std.mem.sliceTo(id, 0), 0, "null") catch {};
        }
    }.callback;

    const ctx = try self.allocator.create(DragCtx);
    ctx.* = .{ .webview = self };

    try self.webview_c.bind("__zystal_startDrag", startDragFn, ctx);
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
