const Self = @This();

const std = @import("std");
const web_view_c_mod = @import("webview");
const WindowConfig = @import("../models/WindowConfig.zig");

pub const EventHandlerFunc = fn ([]const u8) void;

pub const BindingContext = struct {
    handler: *const EventHandlerFunc,
};

allocator: std.mem.Allocator,
// Underlying webview abstraction over C implementation
web_view_c: web_view_c_mod.WebView,
bind_ctxs: std.array_list.Managed(BindingContext),

pub fn build(allocator: std.mem.Allocator, config: WindowConfig) !Self {
    const w = web_view_c_mod.WebView.create(config.dev_tools, null);

    try w.setSize(config.window_size.width, config.window_size.height, .none);
    // Maybe it's better to use dupeZ here to prevent it from crashing from unknown memory layout
    // or just make it null term in Config and pass this problem from here to external side :)
    const null_term_title: [:0]const u8 = @ptrCast(config.window_title);
    try w.setTitle(null_term_title);

    return .{
        .allocator = allocator,
        .web_view_c = w,
        .bind_ctxs = .init(allocator),
    };
}

pub fn load(self: Self, host: []const u8) !void {
    const host_term: [:0]const u8 = @ptrCast(host);
    try self.web_view_c.navigate(host_term);
}

pub fn registerFunc(self: *Self, func_name: []const u8, handler: EventHandlerFunc) !void {
    const func_name_sentinel: [:0]const u8 = @ptrCast(func_name);

    // The naive approach here - is to create a function that would be called for each binding
    // it should get the context and call handler in it, it allows us to create a Zig wrapper over C-style api
    // with argument parsing to make it look and feel like ordinary Zig func.
    const ctx = try self.allocator.create(BindingContext);
    ctx.* = .{ .handler = handler };

    try self.web_view_c.bind(func_name_sentinel, bindTrampoline, ctx);
}

pub fn run(self: Self) !void {
    try self.web_view_c.run();
}

pub fn deinit(self: Self) void {
    for (self.bind_ctxs.items) |*ctx| self.allocator.destroy(ctx);
    self.bind_ctxs.deinit();
    self.web_view_c.destroy() catch return;
}

// Private
fn callFromJson(allocator: std.mem.Allocator, comptime func: anytype, args: []const u8) !void {
    const FuncType = @TypeOf(func);

    const ArgsTuple = std.meta.ArgsTuple(FuncType);
    const parsed = try std.json.parseFromSlice(
        ArgsTuple,
        allocator,
        args,
        .{},
    );
    defer parsed.deinit();

    @call(.auto, func, parsed.value);
}

// just to make C-style API look more like Zig style
fn bindTrampoline(id: [*:0]const u8, args: [*:0]const u8, ctx: ?*anyopaque) callconv(.c) void {
    _ = id;

    const ctx_ptr = ctx orelse return;
    const binding_context: *BindingContext = @ptrCast(@alignCast(ctx_ptr));
    binding_context.handler(std.mem.span(args));
}
