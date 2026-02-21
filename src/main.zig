const std = @import("std");
const Zystal = @import("Zystal.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    const config = Zystal.Config{
        .window = .{ .window_title = "Zystal", .window_size = .{ .width = 1280, .height = 720 } },
    };
    var zystal = try Zystal.init(allocator, config);

    try zystal.start();
}
