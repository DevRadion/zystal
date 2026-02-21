const Self = @This();

const std = @import("std");
const asset_gen = @import("assets_gen");
const build_options = @import("build_options");
const WebView = @import("webview/WebView.zig");
const AssetServer = @import("server/AssetServer.zig");
const AssetStore = @import("assets/AssetStore.zig");
const WindowConfig = @import("models/WindowConfig.zig");
const ServerConfig = @import("models/ServerConfig.zig");

allocator: std.mem.Allocator,
webview: WebView,
server_config: ServerConfig,
asset_server: ?AssetServer,

pub const Config = struct {
    window: WindowConfig,
};

pub fn init(
    allocator: std.mem.Allocator,
    config: Config,
) !Self {
    const server_config: ServerConfig = switch (build_options.source_type) {
        // Default vite dev server
        // localhost is not supported by std.http, so we should use actual IP
        .dev_server => .{ .host = "127.0.0.1", .port = 5173 },
        .built_assets => .{ .host = "127.0.0.1", .port = 1337 },
    };

    var asset_server: ?AssetServer = null;
    if (build_options.source_type == .built_assets) {
        var asset_store = AssetStore.init(allocator);
        for (asset_gen.asset_files) |asset_file| {
            try asset_store.storeAsset(asset_file.path, asset_file.data);
        }
        asset_server = try AssetServer.init(
            allocator,
            server_config,
            asset_store,
        );
    }

    return .{
        .allocator = allocator,
        .webview = try WebView.build(config.window),
        .server_config = server_config,
        .asset_server = asset_server,
    };
}

pub fn start(self: *Self) !void {
    if (build_options.source_type == .built_assets) {
        if (self.asset_server) |*server| {
            try server.start();
        }
    }

    const frontend_host = try std.fmt.allocPrintSentinel(
        self.allocator,
        "http://{s}:{d}",
        .{ self.server_config.host, self.server_config.port },
        0,
    );
    const front_host_term: [:0]const u8 = @ptrCast(frontend_host);

    try self.webview.load(front_host_term);
    try self.webview.run();

    if (build_options.source_type == .dev_server) {
        try self.asset_server.wait();
    }
}

pub fn deinit(self: *Self) void {
    self.asset_server.deinit();
    self.webview.deinit();
}
