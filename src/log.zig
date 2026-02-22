const std = @import("std");

pub fn debug(comptime format: []const u8, args: anytype) void {
    std.log.debug(format, args);
}

pub fn err(comptime format: []const u8, args: anytype) void {
    std.log.err(format, args);
}
