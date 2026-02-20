const std = @import("std");

const AssetStore = @import("../assets/AssetStore.zig");
const server_mod = @import("http_server.zig");

const Self = @This();

const AssetHandler = struct {
    assets: *AssetStore,

    pub fn onRequest(self: *AssetHandler, req: *std.http.Server.Request) !void {
        var path: []const u8 = req.head.target;
        if (std.mem.eql(u8, path, "/")) {
            path = "/index.html";
        }

        std.debug.print("request resource: {s}\n", .{path});
        const asset = self.assets.getAsset(path) orelse {
            try respondUnknown(req);
            return;
        };

        try req.respond(asset.data, .{
            .status = .ok,
            .extra_headers = &[_]std.http.Header{.{
                .name = "Content-Type",
                // Get real mime type
                .value = asset.mime_type.rawName(),
            }},
        });
    }

    fn respondUnknown(req: *std.http.Server.Request) !void {
        try req.respond("404 Page not found", .{
            .status = .ok,
            .extra_headers = &[_]std.http.Header{.{
                .name = "Content-Type",
                .value = "text/html",
            }},
        });
    }
};

const AssetHTTPServer = server_mod.HTTPServer(AssetHandler);

allocator: std.mem.Allocator,
host: []const u8,
port: u16,
assets: *AssetStore,
server_thread: ?std.Thread = null,

pub fn init(allocator: std.mem.Allocator, host: []const u8, port: u16, assets: *AssetStore) !Self {
    return .{
        .allocator = allocator,
        .host = host,
        .port = port,
        .assets = assets,
    };
}

pub fn start(self: *Self) !void {
    self.server_thread = try std.Thread.spawn(
        .{},
        Self.threadMain,
        .{self},
    );
}

pub fn wait(self: *Self) void {
    self.server_thread.?.join();
}

pub fn threadMain(self: *Self) !void {
    var threaded_io: std.Io.Threaded = .init(self.allocator, .{});
    defer threaded_io.deinit();

    const io = threaded_io.io();

    var handler = AssetHandler{ .assets = self.assets };
    var http_server = try AssetHTTPServer.init(
        io,
        self.host,
        self.port,
        &handler,
    );
    try http_server.listen();
}
