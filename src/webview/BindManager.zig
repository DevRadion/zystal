const std = @import("std");
const log = @import("../log.zig");
const webview_c_mod = @import("webview");

const Self = @This();

pub fn BindContext(comptime Owner: type) type {
    return struct {
        owner: *Owner,
        binding_manager: *Self,
    };
}

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
call_arena: std.heap.ArenaAllocator,
webview_c: webview_c_mod.WebView,

pub fn init(allocator: std.mem.Allocator, webview_c: webview_c_mod.WebView) Self {
    return .{
        .allocator = allocator,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .call_arena = std.heap.ArenaAllocator.init(allocator),
        .webview_c = webview_c,
    };
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
    self.call_arena.deinit();
}

pub fn registerDecls(self: *Self, comptime Owner: type, owner: *Owner) !void {
    const type_info = @typeInfo(Owner).@"struct";

    inline for (type_info.decls) |decl| {
        const decl_value = @field(Owner, decl.name);

        if (@typeInfo(@TypeOf(decl_value)) == .@"fn" and comptime shouldRegister(decl.name)) {
            log.debug("{s} - Registering func: {s}", .{ @typeName(Owner), decl.name });
            const trampoline = makeTrampoline(Owner, decl.name);

            const ctx = try self.arena.allocator().create(BindContext(Owner));
            ctx.* = .{ .owner = owner, .binding_manager = self };

            try self.webview_c.bind(decl.name, trampoline, ctx);
        }
    }
}

pub fn registerFunc(self: *Self, func_name: []const u8, comptime handler: anytype) !void {
    const func_name_sentinel: [:0]const u8 = @ptrCast(func_name);
    try self.webview_c.bind(func_name_sentinel, makeTrampoline(handler), self);
}

fn makeTrampoline(comptime Owner: type, comptime func_name: []const u8) webview_c_mod.WebView.BindCallback {
    const Context = BindContext(Owner);

    return struct {
        fn callback(id: [*:0]const u8, args: [*:0]const u8, ctx: ?*anyopaque) callconv(.c) void {
            const ctx_ptr = ctx orelse return;
            const context: *Context = @ptrCast(@alignCast(ctx_ptr));

            _ = context.binding_manager.call_arena.reset(.retain_capacity);

            const result = callFromJson(Owner, func_name, context, std.mem.span(args)) catch {
                // status 1 here means error
                context.binding_manager.webview_c.ret(std.mem.sliceTo(id, 0), 1, "null") catch {};
                return;
            };

            context.binding_manager.webview_c.ret(std.mem.sliceTo(id, 0), 0, result) catch {};
        }
    }.callback;
}

fn callFromJson(
    comptime Owner: type,
    comptime func_name: []const u8,
    ctx: *BindContext(Owner),
    args: []const u8,
) ![:0]const u8 {
    // Here we taking Owner type and getting the func name and params via reflection
    const func = @field(Owner, func_name);
    const params = @typeInfo(@TypeOf(func)).@"fn".params;

    const allocator = ctx.binding_manager.call_arena.allocator();
    const parsed = std.json.parseFromSlice(
        std.json.Value,
        allocator,
        args,
        .{},
    ) catch return error.InvalidJson;
    const arr = parsed.value.array;

    if (arr.items.len < params.len - 1) return error.InvalidArgs;

    var args_tuple: std.meta.ArgsTuple(@TypeOf(func)) = undefined;
    // Assuming first arg is always self
    // It's better to think more about it, maybe there is a way to identify whether should we insert self or not
    args_tuple[0] = ctx.owner;

    // Loop through all params skipping first one - self
    inline for (1..params.len) |i| {
        const Arg = params[i].type orelse continue;
        args_tuple[i] = try jsonCoerce(allocator, Arg, arr.items[i - 1]);
    }

    // Result of the call should be returned to webview
    const call_result = @call(.auto, func, args_tuple);
    // webview expects a json string of the result
    const json_result = try stringifyResult(allocator, call_result);
    return json_result;
}

fn stringifyResult(allocator: std.mem.Allocator, result: anytype) ![:0]const u8 {
    // It seems like that's the best way to return void here
    // maybe we should try undefined as well...
    if (@TypeOf(result) == void) return "null";

    var buffer = std.Io.Writer.Allocating.init(allocator);
    errdefer buffer.deinit();

    try std.json.Stringify.value(result, .{}, &buffer.writer);

    // String should be C style - null terminated
    return buffer.toOwnedSliceSentinel(0);
}

fn jsonCoerce(allocator: std.mem.Allocator, comptime T: type, val: std.json.Value) !T {
    return switch (@typeInfo(T)) {
        .int => switch (val) {
            .integer => |n| @intCast(n),
            .float => |f| @intFromFloat(f),
            else => error.TypeMismatch,
        },
        .float => switch (val) {
            .float => |f| @floatCast(f),
            .integer => |n| @floatFromInt(n),
            else => error.TypeMismatch,
        },
        .bool => switch (val) {
            .bool => |b| b,
            else => error.TypeMismatch,
        },
        .pointer => |ptr| if (ptr.size == .slice and ptr.child == u8)
            switch (val) {
                .string => |s| try allocator.dupe(u8, s),
                else => error.TypeMismatch,
            }
        else
            error.UnsupportedType,
        .optional => |opt| switch (val) {
            .null => null,
            else => @as(T, try jsonCoerce(allocator, opt.child, val)),
        },
        else => error.UnsupportedType,
    };
}

// Temporary solution to exclude init/deinit functions that object might have
// should be replaced with more systematic approach to allow objects control methods they exclude
fn shouldRegister(comptime decl_name: []const u8) bool {
    const excluded_decls = [_][]const u8{ "init", "deinit" };

    inline for (excluded_decls) |exc_decl| {
        if (std.mem.eql(u8, decl_name, exc_decl)) return false;
    }

    return true;
}
