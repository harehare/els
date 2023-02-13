const std = @import("std");
const fs = std.fs;
const text = @import("../text.zig");

const Color = @import("../color.zig").Color;

pub fn print(
    writer: anytype,
    err: anytype,
    path: []const u8,
) !void {
    if (err == error.FileNotFound) {
        try writer.print("\"{s}{s}{s}\": No such file or directory.\n", .{
            Color.magenta,
            path,
            text.reset,
        });
    }
}
