const std = @import("std");
const WebView = @import("webview").WebView;

pub fn main() !void {
    const w = WebView.create(false, null);
    try w.setSize(1024, 720, .none);
    try w.navigate("https://ziglang.org");
    try w.run();
}
