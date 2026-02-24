const Self = @This();

const std = @import("std");
const EventSink = @import("EventSink.zig");
const ChannelMark = @import("channel.zig").ChannelMark;

allocator: std.mem.Allocator,
sink: EventSink,
// Assuming we'll not have 100k channels, so arrays is ok :)
registered: std.array_list.Managed([]u8),

pub fn init(allocator: std.mem.Allocator, sink: EventSink) Self {
    return .{
        .allocator = allocator,
        .sink = sink,
        .registered = .init(allocator),
    };
}

pub fn registerChannel(self: *Self, ChannelType: type) !ChannelType {
    comptime {
        if (!@hasDecl(ChannelType, "Mark") and ChannelType.Mark != ChannelMark) {
            @compileError("Use Channel type");
        }
    }

    for (self.registered.items) |existing| {
        if (std.mem.eql(u8, existing, @typeName(ChannelType))) {
            std.debug.panic("Tried to register duplicate channel: {s}", .{@typeName(ChannelType)});
        }
    }

    try self.registered.append(try self.allocator.dupe(u8, @typeName(ChannelType)));
    return ChannelType.init(&self.sink);
}

pub fn deinit(self: *Self) void {
    for (self.registered.items) |registered| self.allocator.free(registered);
}
