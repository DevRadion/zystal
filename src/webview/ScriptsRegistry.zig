const Self = @This();

const std = @import("std");
const log = @import("../Logger.zig").Logger("ScriptsRegistry");

allocator: std.mem.Allocator,
scripts: std.array_list.Managed(u8),

pub fn init(allocator: std.mem.Allocator) Self {
    log.debug("Init", .{});
    return .{
        .allocator = allocator,
        .scripts = .init(allocator),
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

pub fn getAccumulatedZ(self: *const Self, allocator: std.mem.Allocator) ![:0]const u8 {
    return try allocator.dupeZ(u8, self.scripts.items);
}
