const std = @import("std");
const EventSink = @import("EventSink.zig");

const Logger = @import("../logger.zig").Logger;

pub const ChannelMark = opaque {};

// Channels should be registered in comptime with comptime known data type
// to make them more predictable, and simplify code gen in future
pub fn Channel(comptime DataType: type, comptime name: []const u8) type {
    return struct {
        const Self = @This();
        pub const Mark = ChannelMark;

        const log = Logger(std.fmt.comptimePrint(
            // Channel(u32) name
            "Channel({s}) {s}",
            .{ @typeName(DataType), name },
        ));

        name: []const u8,
        sink: *EventSink,

        pub fn init(sink: *EventSink) Self {
            return .{
                .name = name,
                .sink = sink,
            };
        }

        pub fn postEvent(self: *Self, data: DataType) !void {
            log.debug("postEvent {any}", .{data});
            try self.sink.emitEvent(self.name, data);
        }
    };
}
