const std = @import("std");
const Io = std.Io;
const Zystal = @import("zystal");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var zystal = try Zystal.init(allocator, .{
        .window = .{
            .window_size = .{ .height = 720, .width = 1280 },
            .window_title = "Demo",
            .dev_tools = true,
        },
    });

    try zystal.webview.registerFunc("some", handler);

    try zystal.start();
}

fn handler(args: []const u8) void {
    std.debug.print("Event -> {s}\n", .{args});
}
