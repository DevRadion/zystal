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
webview_c: webview_c_mod.WebView,

pub fn init(allocator: std.mem.Allocator, webview_c: webview_c_mod.WebView) Self {
    return .{
        .allocator = allocator,
        .webview_c = webview_c,
    };
}

pub fn registerDecls(self: *Self, comptime Owner: type, owner: *Owner) !void {
    const type_info = @typeInfo(Owner).@"struct";

    inline for (type_info.decls) |decl| {
        const decl_value = @field(Owner, decl.name);
        if (@typeInfo(@TypeOf(decl_value)) == .@"fn" and comptime shouldRegister(decl.name)) {
            log.debug("{s} - Registering func: {s}\n", .{ @typeName(Owner), decl.name });
            const trampoline = makeTrampoline(Owner, decl.name);

            const ctx = try self.allocator.create(BindContext(Owner));
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
            _ = id;

            const ctx_ptr = ctx orelse return;
            const context: *Context = @ptrCast(@alignCast(ctx_ptr));

            callFromJson(Owner, func_name, context, std.mem.span(args));
        }
    }.callback;
}

fn callFromJson(
    comptime Owner: type,
    comptime func_name: []const u8,
    ctx: *BindContext(Owner),
    args: []const u8,
) void {
    // Here we taking Owner type and getting the func name and params via reflection
    const func = @field(Owner, func_name);
    const params = @typeInfo(@TypeOf(func)).@"fn".params;

    // To make allocations easier to control, for each call we could use arena for now
    // NOTE: Needs investigation about performance, but looks good for now
    var arena = std.heap.ArenaAllocator.init(ctx.binding_manager.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, args, .{}) catch return;
    const arr = parsed.value.array;

    var args_tuple: std.meta.ArgsTuple(@TypeOf(func)) = undefined;
    args_tuple[0] = ctx.owner;

    inline for (1..params.len) |i| {
        const Arg = params[i].type orelse continue;
        args_tuple[i] = jsonCoerce(allocator, Arg, arr.items[i - 1]) catch return;
    }

    @call(.auto, func, args_tuple);
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
            else => @as(T, try jsonCoerce(opt.child, val, allocator)),
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
