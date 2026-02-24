# Zystal

Zystal is a lightweight Tauri/Electron alternative built with Zig.

It allows you to build desktop apps with web tech on the frontend and Zig on the backend, while using the system webview implementation without bundling Chromium for each user.

Right now, the result binary in -Doptimize=ReleaseSmall is 717kb in size with example frontend 🤪

**In development**  
This project is actively evolving, and things may change substantially.

# Example
![Zystal Example](resources/zystal_example.png)

```zig
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
```

```tsx
import { useEffect, useState } from "react";

declare function handleButtonClick(param1: string): Promise<number>;

function App() {
    const [count, setCount] = useState(0);

    const handleButton: () => void = async () => {
        const result = await handleButtonClick("Count");
        setCount(result);
    };

    useEffect(() => {
        const testEventHandler = (event: Event) => console.log(event);

        window.addEventListener("test-channel", testEventHandler);
        return () =>
            window.removeEventListener("test-channel", testEventHandler);
    }, []);

    return (
        <main className="min-h-screen px-6 py-10 grid place-items-center select-none">
            <section className="w-full max-w-3xl text-center">
                <h1 className="m-0 text-7xl font-bold">Zystal</h1>
                <p className="mx-auto mt-4 max-w-[56ch] text-lg font-medium">
                    Cross-platform self-contained web applications in Zig
                </p>

                <button
                    type="button"
                    className="..."
                    onClick={handleButton}
                >
                    Count: {count}
                </button>
            </section>
        </main>
    );
}

export default App;
```

## TODO

- [X] Enable communication from Zig to the frontend
- [ ] Support running the app with a single command across npm, bun, and other package managers
- [ ] Build a bundler that packages the executable into installable apps (icons, metadata, etc.)
- [ ] ...
