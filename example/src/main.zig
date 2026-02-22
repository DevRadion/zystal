const std = @import("std");
const Io = std.Io;
const Zystal = @import("zystal");

pub const Commands = struct {
    pub fn handleButtonClick(param1: []const u8, param2: u32) void {
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

    try zystal.webview.registerDecls(Commands);

    try zystal.start();
}
