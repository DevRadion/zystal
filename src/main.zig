const std = @import("std");
const WebView = @import("webview").WebView;
const http = std.http;
const AssetServer = @import("server/AssetServer.zig");
const AssetStore = @import("assets/AssetStore.zig");
const asset_gen = @import("assets_gen");

fn createWebView() !WebView {
    const w = WebView.create(false, null);
    try w.setSize(1024, 720, .none);
    try w.navigate("http://127.0.0.1:1337");
    try w.setTitle("Zystal");
    return w;
}

fn createAssetServer(allocator: std.mem.Allocator, assets: *AssetStore) !AssetServer {
    return try AssetServer.init(
        allocator,
        "127.0.0.1",
        1337,
        assets,
    );
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    var assets = AssetStore.init(allocator);
    for (asset_gen.asset_files) |asset_file| {
        std.debug.print("Storing: {s}\n", .{asset_file.path});
        try assets.storeAsset(asset_file.path, asset_file.data);
    }

    const webview = try createWebView();
    var server = try createAssetServer(allocator, &assets);
    try server.start();

    try webview.run();
    server.wait();
}
