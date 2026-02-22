const std = @import("std");
const Io = std.Io;
const Zystal = @import("zystal");

pub const Commands = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    pub fn handleButtonClick(self: *Self, param1: []const u8, param2: u32) void {
        _ = self;
        std.debug.print("Event -> {s} {d}\n", .{ param1, param2 });
    }
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var zystal = try Zystal.init(allocator, .{
        .window = .{
            .window_size = .{ .height = 720, .width = 1280 },
            .window_title = "Zystal",
            .dev_tools = true,
        },
    });

    const commands = Commands.init(allocator);
    try zystal.registerDecls(commands);

    try zystal.start();
}
