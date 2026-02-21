const std = @import("std");

const AssetStore = @import("../assets/AssetStore.zig");
const ServerConfig = @import("../models/ServerConfig.zig");
const server_mod = @import("http_server.zig");

const Self = @This();

const AssetHandler = struct {
    assets: *AssetStore,

    pub fn onRequest(self: *AssetHandler, req: *std.http.Server.Request) !void {
        var path: []const u8 = req.head.target;
        if (std.mem.eql(u8, path, "/")) {
            path = "/index.html";
        }

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
config: ServerConfig,
asset_store: AssetStore,
server_thread: ?std.Thread = null,
is_running: std.atomic.Value(bool),

pub fn init(allocator: std.mem.Allocator, config: ServerConfig, asset_store: AssetStore) !Self {
    return .{
        .allocator = allocator,
        .config = config,
        .asset_store = asset_store,
        .is_running = .init(false),
    };
}

pub fn start(self: *Self) !void {
    self.server_thread = try std.Thread.spawn(
        .{},
        Self.threadMain,
        .{self},
    );
}

pub fn deinit(self: *Self) void {
    self.is_running.store(false, .release);
    std.debug.print("stopping server thread\n", .{});
}

pub fn stop(self: *Self) void {
    self.is_running.store(false, .release);
}

pub fn wait(self: *Self) void {
    self.server_thread.?.join();
}

pub fn threadMain(self: *Self) !void {
    var threaded_io: std.Io.Threaded = .init(self.allocator, .{});
    defer threaded_io.deinit();

    const io = threaded_io.io();

    var handler = AssetHandler{ .assets = &self.asset_store };
    var http_server = try AssetHTTPServer.init(
        io,
        self.config.host,
        self.config.port,
        &handler,
        &self.is_running,
    );
    try http_server.listen();
}
