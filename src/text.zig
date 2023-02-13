const std = @import("std");

const Item = @import("models/item.zig").Item;
const Kind = @import("models/item.zig").Kind;
const expect = std.testing.expect;

pub const reset = "\x1b[0m";
pub const underline = "\x1b[4m";

pub const Font = struct {
    pub const bold = "\x1b[1m";
};

pub fn toLowercase(s: []const u8) []const u8 {
    var buf: [2 << 8]u8 = undefined;
    const r = buf[0..s.len];

    for (s) |c, i| {
        r[i] = std.ascii.toLower(c);
    }

    return r;
}

test "toLowercase" {
    try expect(std.mem.eql(u8, toLowercase("README.MD"), "readme.md"));
    try expect(std.mem.eql(u8, toLowercase("ReAdMe.Md"), "readme.md"));
}
