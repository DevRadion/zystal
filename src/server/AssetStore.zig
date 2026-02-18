const Self = @This();

const std = @import("std");
const Asset = @import("Asset.zig");

assets: std.StringHashMap(Asset),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .assets = .init(allocator),
    };
}

pub fn getAsset(self: Self, path: []const u8) ?Asset {
    return self.assets.get(path);
}

pub fn storeAsset(self: *Self, path: []const u8, asset: Asset) !void {
    return try self.assets.put(path, asset);
}
