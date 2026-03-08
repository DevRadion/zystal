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
scripts_registry: ScriptsRegistry,
window_instance: ?Window,
is_drag_region_initialized: bool,

pub fn init(allocator: std.mem.Allocator, dev_tools: bool) !Self {
    const w = webview_c_mod.WebView.create(dev_tools, null);

    var self = Self{
        .allocator = allocator,
        .webview_c = w,
        .bind_manager = BindManager.init(allocator, w),
        .scripts_registry = ScriptsRegistry.init(allocator),
        .window_instance = null,
        .is_drag_region_initialized = false,
    };
    errdefer self.deinit();

    try self.addInitScript(
        \\window.__nativeEmit = (name, detailJson) => {
        \\  let detail;
        \\  try { detail = detailJson ? JSON.parse(detailJson) : undefined; }
        \\  catch { detail = detailJson; }
        \\  window.dispatchEvent(new CustomEvent(name, { detail }));
        \\};
    );

    return self;
}

pub fn addInitScript(self: *Self, js: []const u8) !void {
    try self.scripts_registry.registerScript(js);
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

pub fn emitEvent(self: *Self, name: []const u8, data: anytype) !void {
    var buffer = std.Io.Writer.Allocating.init(self.allocator);
    defer buffer.deinit();

    try std.json.Stringify.value(data, .{}, &buffer.writer);
    const json_string = try buffer.toOwnedSlice();
    defer self.allocator.free(json_string);

    try self.emitSerializedEvent(name, json_string);
}

pub fn emitSerializedEvent(self: *Self, name: []const u8, json_string: []const u8) !void {
    const js_string = try std.fmt.allocPrintSentinel(
        self.allocator,
        "window.__nativeEmit(\"{s}\", {s});",
        .{ name, json_string },
        0,
    );
    defer self.allocator.free(js_string);

    log.debug("emitEvent -> name: {s}", .{name});

    try self.webview_c.eval(js_string);
}

pub fn window(self: *Self) ?*Window {
    if (self.window_instance == null) {
        const handle = self.getNativeHandle() orelse return null;
        self.window_instance = Window.init(handle);
    }

    return &self.window_instance.?;
}

pub fn start(self: *Self, url: [:0]const u8) !void {
    try self.initDragRegion();

    const scripts = try self.scripts_registry.getAccumulatedZ(self.allocator);
    defer self.allocator.free(scripts);

    try self.webview_c.init(scripts);
    try self.load(url);
    try self.run();
}

pub fn getNativeHandle(self: *const Self) ?*anyopaque {
    return self.webview_c.getNativeHandle(.ui_window) orelse null;
}

pub fn deinit(self: *Self) void {
    if (self.window()) |cached_window| {
        cached_window.deinit();
    }
    self.scripts_registry.deinit();
    self.bind_manager.deinit();
    self.webview_c.destroy() catch return;
}

fn initDragRegion(self: *Self) !void {
    if (self.is_drag_region_initialized) return;

    try self.addInitScript(
        \\document.addEventListener('mousedown', function(e) {
        \\  if (e.button !== 0) return;
        \\  var el = e.target;
        \\  while (el) {
        \\    if (el.hasAttribute) {
        \\      if (el.hasAttribute('data-zystal-no-drag')) return;
        \\      var tag = el.tagName;
        \\      if (tag === 'BUTTON' || tag === 'INPUT' || tag === 'SELECT' ||
        \\          tag === 'TEXTAREA' || tag === 'A' || el.isContentEditable) return;
        \\      if (el.hasAttribute('data-zystal-draggable')) {
        \\        e.preventDefault();
        \\        __zystal_startDrag();
        \\        return;
        \\      }
        \\    }
        \\    el = el.parentElement;
        \\  }
        \\});
    );

    const startDragFn = struct {
        fn callback(id: [*:0]const u8, _: [*:0]const u8, ctx: ?*anyopaque) callconv(.c) void {
            const self_ptr: *Self = @ptrCast(@alignCast(ctx orelse return));
            const cached_window = self_ptr.window() orelse return;
            cached_window.startDragging();
            self_ptr.webview_c.ret(std.mem.sliceTo(id, 0), 0, "null") catch {};
        }
    }.callback;

    try self.webview_c.bind("__zystal_startDrag", startDragFn, self);
    self.is_drag_region_initialized = true;
}
