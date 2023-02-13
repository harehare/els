const std = @import("std");

const Item = @import("../models/item.zig").Item;
const Window = @import("../models/window.zig").Window;

const itemView = @import("./item.zig");
const text = @import("../../text.zig");
const console = @import("./console.zig");
const option = @import("../option.zig");
const TupleOfUsize = @import("../type.zig").TupleOfUsize;

const fs = std.fs;

pub fn print(writer: anytype, items: std.MultiArrayList(Item), display_options: option.DisplayOptions, window: Window) !void {
    var current_position: usize = 0;
    const info = lengthInfo(items);
    const itemsLen = items.len;
    const len = info.v1;
    const sum = info.v2;

    for (items.items(.name)) |name, i| {
        const item = items.get(i);
        const nameLen = item.name.len;

        if (current_position + nameLen > window.width) {
            if (i + 1 < itemsLen) {
                try console.newLine(writer);
            }
            current_position = 0;
        }

        try itemView.name(writer, item, display_options);

        if (sum <= window.width and i + 1 < itemsLen) {
            try console.space(writer);
            try console.space(writer);
            continue;
        }

        current_position += nameLen;

        if (current_position + (len - nameLen) > window.width) {
            if (i + 1 < itemsLen) {
                try console.newLine(writer);
            }
            current_position = 0;
        } else if (i + 1 < itemsLen) {
            try console.paddingSpace(writer, len - name.len);
            try console.space(writer);
            current_position += len + 1;
        }
    }

    try console.newLine(writer);
}

fn lengthInfo(items: std.MultiArrayList(Item)) TupleOfUsize {
    var maxLen: usize = 0;
    var sum: usize = 0;

    for (items.items(.name)) |name| {
        const l = name.len;
        if (l > maxLen) {
            maxLen = l;
        }
        sum += l + 1;
    }

    return .{ .v1 = maxLen, .v2 = sum };
}
