const std = @import("std");

pub fn Logger(comptime prefix: []const u8) type {
    return struct {
        pub fn debug(comptime format: []const u8, args: anytype) void {
            std.log.debug("{s}: " ++ format, .{prefix} ++ args);
        }

        pub fn err(comptime format: []const u8, args: anytype) void {
            std.log.err("{s}: " ++ format, .{prefix} ++ args);
        }
    };
}
