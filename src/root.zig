const std = @import("std");
const build_options = @import("build_options");

const asset_gen = @import("assets_gen");

const AssetStore = @import("assets/AssetStore.zig");
const ServerConfig = @import("models/ServerConfig.zig");
const WindowConfig = @import("models/WindowConfig.zig");
const AssetServer = @import("server/AssetServer.zig");
pub const Channel = @import("webview/channel.zig").Channel;
const EventSink = @import("webview/EventSink.zig");
const WebView = @import("webview/WebView.zig");
const ChannelRegistry = @import("webview/ChannelRegistry.zig");

const Self = @This();

const Logger = @import("Logger.zig").Logger;

const log = Logger("Zystal");

arena: std.heap.ArenaAllocator,
webview: WebView,
server_config: ServerConfig,
asset_server: ?AssetServer,
channel_registry: ChannelRegistry,

pub const Config = struct {
    window: WindowConfig,
};

pub fn init(allocator: std.mem.Allocator, config: Config) !Self {
    const server_config: ServerConfig = switch (build_options.source_type) {
        // Default vite dev server
        .dev_server => .{ .host = "localhost", .port = 5173 },
        // localhost is not supported by std.http, so we should use actual IP (it's okay for webview)
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
    var webview = try WebView.build(allocator, config.window);
    errdefer webview.deinit();

    return .{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .webview = webview,
        .server_config = server_config,
        .asset_server = asset_server,
        .channel_registry = ChannelRegistry.init(
            allocator,
            try EventSink.init(
                allocator,
                webview.webview_c,
            ),
        ),
    };
}

pub fn start(self: *Self) !void {
    if (build_options.source_type == .built_assets) {
        if (self.asset_server) |*server| {
            log.debug("Starting assets server at", .{});
            try server.start();
        }
    }

    var frontend_host_buf: [256]u8 = undefined;
    const frontend_host = try std.fmt.bufPrintZ(
        &frontend_host_buf,
        "http://{s}:{d}",
        .{ self.server_config.host, self.server_config.port },
    );

    log.debug("Loading web page: {s}", .{frontend_host});

    try self.webview.load(frontend_host);
    try self.webview.run();

    if (build_options.source_type == .built_assets) {
        if (self.asset_server) |*server| {
            server.wait();
        }
    }
}

pub fn registerDecls(self: *Self, comptime Owner: type, owner: *Owner) !void {
    try self.webview.registerDecls(Owner, owner);
}

// Accepts Channel type with DataType and name specified
pub fn registerChannel(self: *Self, ChannelType: type) !ChannelType {
    return self.channel_registry.registerChannel(ChannelType);
}

pub fn deinit(self: *Self) void {
    if (self.asset_server) |*server| server.deinit();
    self.channel_registry.deinit();
    self.webview.deinit();
    self.arena.deinit();
}
