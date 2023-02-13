const std = @import("std");
const Item = @import("../models/item.zig").Item;
const text = @import("../text.zig");
const console = @import("./console.zig");
const itemView = @import("./item.zig");
const option = @import("../option.zig");

const fs = std.fs;
const mem = std.mem;

pub fn print(
    writer: anytype,
    items: std.MultiArrayList(Item),
    display_options: option.DisplayOptions,
) !void {
    var buf = std.io.bufferedWriter(writer);
    const w = buf.writer();

    for (items.items(.name)) |_, i| {
        try itemView.name(w, items.get(i), display_options);
        try console.newLine(w);
    }

    try buf.flush();
}
