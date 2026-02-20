const std = @import("std");

pub const AssetGenError = error{
    NotEnoughArgs,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(allocator);
    // program, input, output
    if (args.len < 3) return AssetGenError.NotEnoughArgs;
    for (args) |arg| {
        std.debug.print("arg: {s}\n", .{arg});
    }

    const io = init.io;
    const assets_dir = args[2];
    const assets = try listAssets(allocator, io, assets_dir);

    const target_gen_dir = args[1];
    try generateCodeFromAssets(
        allocator,
        io,
        assets_dir,
        assets,
        target_gen_dir,
    );
}

fn listAssets(allocator: std.mem.Allocator, io: std.Io, abs_path: []const u8) ![][]const u8 {
    // 1. Open dir at abs_path (with iterate - true)
    const dir = try std.Io.Dir.cwd().openDir(
        io,
        abs_path,
        .{ .iterate = true },
    );
    defer dir.close(io);

    // Create walker
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var asset_gen_list = std.array_list.Managed([]const u8).init(allocator);

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        const rel_path = try allocator.dupe(u8, entry.path);
        std.debug.print("Appending asset: {s}\n", .{rel_path});
        try asset_gen_list.append(rel_path);
    }

    return asset_gen_list.toOwnedSlice();
}

fn generateCodeFromAssets(
    allocator: std.mem.Allocator,
    io: std.Io,
    asset_dir_path: []const u8,
    asset_paths: [][]const u8,
    target_file_path: []const u8,
) !void {
    const target_file = try std.Io.Dir.createFileAbsolute(
        io,
        target_file_path,
        .{},
    );
    defer target_file.close(io);
    var code_list = std.array_list.Managed(u8).init(allocator);

    // Write base struct with holding const declaration
    try code_list.appendSlice(
        \\ pub const AssetGenFile = struct {
        \\     path: []const u8,
        \\     data: []const u8,
        \\ };
        \\ pub const asset_files: []const AssetGenFile = &[_]AssetGenFile{
        \\
    );

    // Add all files from list
    for (asset_paths) |path| {
        try code_list.print(
            \\    .{{ .path = "{s}", .data = @embedFile("../{s}/{s}") }},
            \\
        , .{ path, asset_dir_path, path });
    }

    // Finish declaration
    try code_list.appendSlice(
        \\ };
    );

    const code_slice = try code_list.toOwnedSlice();
    try target_file.writeStreamingAll(io, code_slice);
}
