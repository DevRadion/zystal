const Self = @This();

const std = @import("std");
const Asset = @import("Asset.zig");

const Error = error{
    CouldNotParseMimeType,
};

assets: std.StringHashMap(Asset),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .assets = .init(allocator),
    };
}

pub fn getAsset(self: Self, path: []const u8) ?Asset {
    return self.assets.get(path);
}

pub fn storeAsset(self: *Self, path: []const u8, data: []const u8) !void {
    const mime_type = try Self.parseMimeType(path);
    const asset = Asset.init(data, mime_type);
    return try self.assets.put(path, asset);
}

pub fn deinit(self: *Self) void {
    self.assets.deinit();
}

fn parseMimeType(path: []const u8) !Asset.MimeType {
    if (std.mem.endsWith(u8, path, ".html")) return .html;
    if (std.mem.endsWith(u8, path, ".css")) return .css;
    if (std.mem.endsWith(u8, path, ".svg")) return .svg;
    if (std.mem.endsWith(u8, path, ".js")) return .javascript;
    if (std.mem.endsWith(u8, path, ".txt")) return .plain;

    // If it's some file with extension, but we couldn't parse it - treat it like a plain text for now
    if (std.mem.containsAtLeast(u8, path, 1, ".")) return .plain;

    // And if we end up here, it means that file has no extension (maybe dir?)
    return Error.CouldNotParseMimeType;
}
