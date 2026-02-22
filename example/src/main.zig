const std = @import("std");
const Io = std.Io;
const Zystal = @import("zystal");

pub const Commands = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    last_count: u32,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .last_count = 0,
        };
    }

    pub fn handleButtonClick(self: *Self, param1: []const u8, param2: u32) void {
        std.debug.print("Button click -> {s} {d}, last_count: {d}\n", .{ param1, param2, self.last_count });
        self.last_count = param2;
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

    var commands = Commands.init(allocator);
    try zystal.registerDecls(Commands, &commands);

    try zystal.start();
}
