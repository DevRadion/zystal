const Self = @This();

data: []const u8,
mime_type: []const u8,

pub fn init(data: []const u8, mime_type: []const u8) Self {
    return .{
        .data = data,
        .mime_type = mime_type,
    };
}
