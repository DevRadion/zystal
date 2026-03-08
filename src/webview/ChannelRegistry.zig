const Self = @This();

const std = @import("std");
const EventSink = @import("EventSink.zig");
const WebView = @import("WebView.zig");
const ChannelMark = @import("Channel.zig").ChannelMark;

allocator: std.mem.Allocator,
registered: std.array_list.Managed([]u8),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .allocator = allocator,
        .registered = .init(allocator),
    };
}

pub fn registerChannel(self: *Self, webview: *WebView, ChannelType: type) !ChannelType {
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
    return ChannelType.init(EventSink.init(self.allocator, webview));
}

pub fn deinit(self: *Self) void {
    for (self.registered.items) |registered| self.allocator.free(registered);
    self.registered.deinit();
}
