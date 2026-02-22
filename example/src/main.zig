const std = @import("std");
const Io = std.Io;
const Zystal = @import("zystal");

pub const Commands = struct {
    const Self = @This();

    last_count: u32,

    // This function is called from frontend using TS/JS directly
    // Example: handleButtonClick("Count:", 4);
    pub fn handleButtonClick(self: *Self, param1: []const u8, param2: u32) void {
        std.debug.print(
            "Button click -> {s} {d}, last_count: {d}\n",
            .{ param1, param2, self.last_count },
        );
        self.last_count = param2;
    }
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Main object initialization
    var zystal = try Zystal.init(allocator, .{
        // Sets window parameters
        .window = .{
            .window_size = .{ .height = 720, .width = 1280 },
            .window_title = "Zystal",
            // Enable dev tools or not
            .dev_tools = true,
        },
    });

    // Zystal is designed to make registrations automatically
    // So you creating an object, it even could have its own state
    // or dependencies like an allocator, Io, etc
    var commands = Commands{ .last_count = 0 };
    // `registerDecl` accepts the comptime type and the pointer to allocated object
    // it takes all functions of an object and registers them with their name,
    // so you can call them from frontend
    // like an ordinary JavaScript function passing parameters to it
    try zystal.registerDecls(Commands, &commands);

    // Blocking function that runs webview and the asset server in parallel (if release mode)
    try zystal.start();
}
