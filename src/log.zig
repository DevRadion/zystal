const std = @import("std");

pub fn debug(comptime format: []const u8, args: anytype) void {
    std.log.debug(format, args);
}
