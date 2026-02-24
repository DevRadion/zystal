const std = @import("std");
const Io = std.Io;
const Zystal = @import("zystal");
const Channel = Zystal.Channel;

const TestEvent = struct {
    greeting: []const u8,
};

// Channel DataType and name baked into type,
// so you can declare them and use consistently and type-safe, duplicate registrations are checked.
const TestChannel = Channel(TestEvent, "test-channel");

pub const Commands = struct {
    const Self = @This();

    last_count: u32 = 0,
    test_channel: TestChannel,

    // This function is called from frontend using TS/JS directly
    // Example: handleButtonClick("Count");
    pub fn handleButtonClick(self: *Self, param1: []const u8) u32 {
        std.debug.print(
            "Button click -> {s} {d}\n",
            .{ param1, self.last_count },
        );
        self.last_count += 1;
        self.test_channel.postEvent(
            TestEvent{ .greeting = "Hello world!" },
        ) catch return self.last_count;

        return self.last_count;
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
    defer zystal.deinit();

    const test_event_channel = try zystal.registerChannel(TestChannel);

    // Zystal is designed to make registrations automatically
    // So you creating an object, it even could have its own state
    // or dependencies like an allocator, Io, etc
    var commands = Commands{ .last_count = 0, .test_channel = test_event_channel };

    // `registerDecl` accepts the comptime type and the pointer to allocated object
    // it takes all functions of an object and registers them with their name,
    // so you can call them from frontend
    // like an ordinary JavaScript function passing parameters to it
    try zystal.registerDecls(Commands, &commands);

    // Blocking function that runs webview and the asset server in parallel (if release mode)
    try zystal.start();
}
