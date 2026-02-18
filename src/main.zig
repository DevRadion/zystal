const std = @import("std");
const WebView = @import("webview").WebView;
const http = std.http;
const AssetServer = @import("server/AssetServer.zig");
const AssetStore = @import("server/AssetStore.zig");

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

fn loadTestFrontendAssets(assets: *AssetStore) !void {
    try assets.storeAsset(
        "/index.html",
        .init(@embedFile("frontend/test/dist/index.html"), "text/html; charset=utf-8"),
    );
    try assets.storeAsset(
        "/vite.svg",
        .init(@embedFile("frontend/test/dist/vite.svg"), "image/svg+xml"),
    );
    try assets.storeAsset(
        "/assets/index-BskfniDH.js",
        .init(@embedFile("frontend/test/dist/assets/index-BskfniDH.js"), "text/javascript"),
    );
    try assets.storeAsset(
        "/assets/index-hoDP6v4Q.css",
        .init(@embedFile("frontend/test/dist/assets/index-hoDP6v4Q.css"), "text/css"),
    );
    try assets.storeAsset(
        "/assets/react-CHdo91hT.svg",
        .init(@embedFile("frontend/test/dist/assets/react-CHdo91hT.svg"), "image/svg+xml"),
    );
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    var assets = AssetStore.init(allocator);
    try loadTestFrontendAssets(&assets);
    const webview = try createWebView();
    var server = try createAssetServer(allocator, &assets);
    try server.start();

    try webview.run();
    server.wait();
}
