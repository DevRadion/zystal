const std = @import("std");
const WebView = @import("webview").WebView;
const http = std.http;
const AssetReader = @import("assets/AssetReader.zig");
const AssetServer = @import("server/AssetServer.zig");
const AssetStore = @import("assets/AssetStore.zig");

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

    // src/frontend/test/dist

    var assets = AssetStore.init(allocator);
    const webview = try createWebView();
    var server = try createAssetServer(allocator, &assets);
    try server.start();

    try webview.run();
    server.wait();
}
