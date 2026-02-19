const Self = @This();

pub const MimeType = enum {
    // Text
    plain,
    javascript,
    html,
    css,
    // Images
    svg,

    pub fn rawName(self: MimeType) []const u8 {
        return switch (self) {
            // Text
            .plain => "text/plain",
            .javascript => "text/javascript",
            .html => "text/html",
            .css => "text/css",
            // Images
            .svg => "image/svg+xml",
        };
    }
};

data: []const u8,
mime_type: MimeType,

pub fn init(data: []const u8, mime_type: MimeType) Self {
    return .{
        .data = data,
        .mime_type = mime_type,
    };
}
