const std = @import("std");
const net = std.Io.net;

// Basic abstraction layer over std.http to make it easier to use
pub fn HTTPServer(comptime Handler: type) type {
    return struct {
        const Self = @This();

        io: std.Io,
        address: net.IpAddress,
        server_handle: net.Server,
        handler: *Handler,
        is_running: *std.atomic.Value(bool),

        pub fn init(
            io: std.Io,
            host: []const u8,
            port: u16,
            handler: *Handler,
            is_running: *std.atomic.Value(bool),
        ) !Self {
            return .{
                .io = io,
                .address = try net.IpAddress.parseIp4(host, port),
                .server_handle = undefined,
                .handler = handler,
                .is_running = is_running,
            };
        }

        pub fn deinit(self: *Self) void {
            self.server_handle.deinit(self.io);
        }

        pub fn listen(self: *Self) !void {
            self.server_handle = try net.IpAddress.listen(
                self.address,
                self.io,
                net.IpAddress.ListenOptions{},
            );

            self.is_running.store(true, .release);
            while (self.is_running.load(.acquire)) {
                try self.handleConnection();
            }
            std.debug.print("Server is stopped\n", .{});
        }

        fn handleConnection(self: *Self) !void {
            const stream = try self.server_handle.accept(self.io);
            defer stream.close(self.io);

            var rbuf: [4096]u8 = undefined;
            var reader = stream.reader(self.io, &rbuf);

            var wbuf: [4096]u8 = undefined;
            var writer = stream.writer(self.io, &wbuf);

            var server = std.http.Server.init(&reader.interface, &writer.interface);

            // For now - just return, forget about it...
            var req = server.receiveHead() catch return;

            try self.handler.onRequest(&req);
        }
    };
}
