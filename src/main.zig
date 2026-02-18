const std = @import("std");
const WebView = @import("webview").WebView;
const http = std.http;
const AssetServer = @import("server/AssetServer.zig");
const WebAssets = @import("server/WebAssets.zig");

const AppHandler = struct {
    pub fn onRequest(self: *AppHandler, req: *std.http.Server.Request) !void {
        try req.respond(self.assets.data, .{
            .status = .ok,
            .extra_headers = &[_]std.http.Header{.{
                .name = "Content-Type",
                .value = "text/plain",
            }},
        });
    }
};

pub fn main(init: std.process.Init) !void {
    var assets = WebAssets{
        .data = "oooooother data",
    };

    const allocator = init.gpa;
    var asset_server = try AssetServer.init(
        allocator,
        "127.0.0.1",
        1337,
        &assets,
    );
    try asset_server.start();

    const w = WebView.create(false, null);
    try w.setSize(1024, 720, .none);
    try w.navigate("http://127.0.0.1:1337");
    try w.setTitle("Zystal");

    try w.run();
    asset_server.wait();
}
