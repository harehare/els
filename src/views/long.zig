const std = @import("std");

const Datetime = @import("datetime").datetime.Datetime;
const Color = @import("../color.zig").Color;
const Item = @import("../models/item.zig").Item;

const itemView = @import("./item.zig");
const text = @import("../text.zig");
const console = @import("./console.zig");
const option = @import("../option.zig");
const permissions = @import("../models/permissions.zig");

const fs = std.fs;
const math = std.math;
const mem = std.mem;

pub fn print(
    writer: anytype,
    items: std.MultiArrayList(Item),
    long_view_options: option.LongViewOptions,
    display_options: option.DisplayOptions,
) !void {
    const maxLength = struct {
        size: usize,
        user: usize,
        group: usize,
        blocks: usize,

        const Self = @This();

        pub fn init(i: std.MultiArrayList(Item), o: option.LongViewOptions) Self {
            return Self{
                .size = getMaxSizeLength(i, o),
                .user = if (o.noUser and !o.allFields) 0 else if (o.numeric) getMaxUidLength(i) else getMaxUserNameLength(i),
                .group = if (!o.group and !o.allFields) 0 else if (o.numeric) getMaxGidLength(i) else getMaxGroupNameLength(i),
                .blocks = if (o.blocks or o.allFields) getMaxBlocksLength(i) else 0,
            };
        }
    }.init(items, long_view_options);

    if (long_view_options.header or long_view_options.allFields) {
        try printHeader(
            writer,
            long_view_options,
            display_options,
            maxLength,
        );
    }

    for (items.items(.name)) |name, i| {
        const item = items.get(i);

        // inode
        if (long_view_options.inode or long_view_options.allFields) {
            try itemView.inode(writer, item, display_options);
            try console.space(writer);
        }

        // Octal Permission
        if (long_view_options.octalPermissions) {
            try itemView.octalPermission(writer, item, display_options);
            try console.space(writer);

            // permission
        } else if (!long_view_options.noPermissions or long_view_options.allFields) {
            try itemView.kind(writer, item, display_options);
            try console.space(writer);
            try itemView.permission(writer, item, display_options);
            try console.space(writer);
        }

        // links
        if (long_view_options.links or long_view_options.allFields) {
            try console.paddingSpace(writer, if (4 - math.log10(item.stat.links) < 0) 0 else 4 - math.log10(item.stat.links));
            try itemView.links(writer, item, display_options);
            try console.space(writer);
        }

        // size
        if (!long_view_options.noFileSize or long_view_options.allFields) {
            if (item.isDir() or item.isSymLink()) {
                try printNoSize(writer, maxLength.size, display_options);
                try console.space(writer);
            } else {
                try printSize(writer, item, maxLength.size, long_view_options, display_options);
                try console.space(writer);
            }
        }

        // blocks
        if (long_view_options.blocks or long_view_options.allFields) {
            try printBlocks(writer, item, maxLength.blocks, display_options);
            try console.space(writer);
        }

        // user
        if (!long_view_options.noUser or long_view_options.allFields) {
            if (long_view_options.numeric) {
                try printUid(writer, item, maxLength.user, display_options);
                try console.space(writer);
            } else {
                try printUserName(writer, item, maxLength.user, display_options);
                try console.space(writer);
            }
        }

        // group
        if (long_view_options.group or long_view_options.allFields) {
            if (long_view_options.numeric) {
                try printGid(writer, item, maxLength.group, display_options);
                try console.space(writer);
            } else {
                try printGroupName(writer, item, maxLength.group, display_options);
                try console.space(writer);
            }
        }

        // date
        if (!long_view_options.noTime or long_view_options.allFields) {
            try printDatetime(writer, item, long_view_options, display_options);
        }

        // name
        if (item.isSymLink()) {
            // name
            if (display_options.color.isAlways()) {
                try writer.print("{s}{s}{s} -> ", .{ Color.cyan, name, Color.gray });
            } else {
                try writer.print("{s} -> ", .{name});
            }

            if (item.link_item) |link_item| {
                try itemView.linkItem(writer, link_item, display_options);
            }
        } else {
            try itemView.name(writer, item, display_options);
        }

        try console.newLine(writer);
    }
}

fn printHeader(
    writer: anytype,
    long_view_options: option.LongViewOptions,
    display_options: option.DisplayOptions,
    maxLength: anytype,
) !void {
    if (long_view_options.inode or long_view_options.allFields) {
        try console.underline(writer, "inode", display_options);
        try console.paddingSpace(writer, 4);
    } else {
        try writer.print("{s}", .{text.underline});
    }

    if (long_view_options.octalPermissions) {
        try console.underline(writer, "Octal", display_options);
        try console.paddingSpace(writer, 1);
    }

    if (!long_view_options.noPermissions or long_view_options.allFields) {
        try console.paddingSpace(writer, 2);
        try console.underline(writer, "Permissions", display_options);
        try console.paddingSpace(writer, 1);
    }

    if (long_view_options.links or long_view_options.allFields) {
        try console.underline(writer, "Links", display_options);
        try console.paddingSpace(writer, 1);
    }

    try console.paddingSpace(writer, maxLength.size - 4);
    try console.underline(writer, "Size", display_options);
    try console.paddingSpace(writer, 1);

    if (long_view_options.blocks or long_view_options.allFields) {
        try console.paddingSpace(writer, maxLength.blocks - 6);
        try console.underline(writer, "Blocks", display_options);
        try console.paddingSpace(writer, 1);
    }

    if (!long_view_options.noUser or long_view_options.allFields) {
        if (long_view_options.numeric) {
            try console.paddingSpace(writer, maxLength.user - 3);
            try console.underline(writer, "Uid", display_options);
            try console.paddingSpace(writer, 1);
        } else {
            try console.underline(writer, "User", display_options);
            try console.paddingSpace(writer, maxLength.user - 3);
        }
    }

    if (long_view_options.group or long_view_options.allFields) {
        if (long_view_options.numeric) {
            try console.paddingSpace(writer, maxLength.group - 3);
            try console.underline(writer, "Gid", display_options);
            try console.paddingSpace(writer, 1);
        } else {
            try console.underline(writer, "Group", display_options);
            try console.paddingSpace(writer, maxLength.group - 4);
        }
    }

    if (long_view_options.created or long_view_options.allFields) {
        try console.underline(writer, "Date Created", display_options);

        if (long_view_options.timeStyle == option.TimeStyle.LongIso) {
            try console.paddingSpace(writer, 5);
        } else if (long_view_options.timeStyle == option.TimeStyle.Timestamp) {
            try console.paddingSpace(writer, 2);
        } else {
            try console.paddingSpace(writer, 1);
        }
    }

    if (long_view_options.accessed or long_view_options.allFields) {
        try console.underline(writer, "Date Accessed", display_options);

        if (long_view_options.timeStyle == option.TimeStyle.LongIso) {
            try console.paddingSpace(writer, 5);
        } else if (long_view_options.timeStyle == option.TimeStyle.Timestamp) {
            try console.paddingSpace(writer, 1);
        } else {
            try console.paddingSpace(writer, 1);
        }
    }

    if (long_view_options.modified or (!long_view_options.modified and !long_view_options.created and !long_view_options.accessed) or long_view_options.allFields) {
        try console.underline(writer, "Date Modified", display_options);

        if (long_view_options.timeStyle == option.TimeStyle.LongIso) {
            try console.paddingSpace(writer, 5);
        } else if (long_view_options.timeStyle == option.TimeStyle.Timestamp) {
            try console.paddingSpace(writer, 1);
        } else {
            try console.paddingSpace(writer, 1);
        }
    }

    try console.underline(writer, "Name", display_options);
    try console.newLine(writer);
}

fn printDatetime(
    writer: anytype,
    item: Item,
    long_view_options: option.LongViewOptions,
    display_options: option.DisplayOptions,
) !void {
    if (long_view_options.created or long_view_options.allFields) {
        try itemView.created(writer, item, long_view_options, display_options);

        if (long_view_options.timeStyle == option.TimeStyle.Iso) {
            try console.paddingSpace(writer, 2);
        } else if (long_view_options.timeStyle == option.TimeStyle.Iso) {
            // skip
        } else {
            try console.paddingSpace(writer, 1);
        }
    }

    if (long_view_options.accessed or long_view_options.allFields) {
        try itemView.accessed(writer, item, long_view_options, display_options);

        if (long_view_options.timeStyle == option.TimeStyle.Iso) {
            try console.paddingSpace(writer, 3);
        } else if (long_view_options.timeStyle == option.TimeStyle.Iso) {
            // skip
        } else if (long_view_options.timeStyle == option.TimeStyle.Timestamp) {
            try console.paddingSpace(writer, 1);
        } else {
            try console.paddingSpace(writer, 2);
        }
    }

    if (long_view_options.modified or long_view_options.allFields or (!long_view_options.modified and !long_view_options.accessed and !long_view_options.created)) {
        try itemView.modified(writer, item, long_view_options, display_options);

        if (long_view_options.timeStyle == option.TimeStyle.Iso) {
            try console.paddingSpace(writer, 3);
        } else if (long_view_options.timeStyle == option.TimeStyle.Iso) {
            try console.paddingSpace(writer, 1);
        } else if (long_view_options.timeStyle == option.TimeStyle.Timestamp) {
            try console.paddingSpace(writer, 1);
        } else {
            try console.paddingSpace(writer, 2);
        }
    }
}

fn printNoSize(
    writer: anytype,
    maxLength: usize,
    display_options: option.DisplayOptions,
) !void {
    try console.paddingSpace(writer, maxLength - 1);

    if (display_options.color.isAlways()) {
        try writer.print("{s}{s}{s}", .{ Color.gray, "-", text.reset });
    } else {
        try writer.print("{s}", .{"-"});
    }
}

fn printUid(
    writer: anytype,
    item: Item,
    userLength: usize,
    display_options: option.DisplayOptions,
) !void {
    if (userLength > 0) {
        try console.paddingSpace(writer, userLength - math.log10(item.stat.uid) - 1);
    }

    try itemView.uid(writer, item, display_options);
}

fn printGid(
    writer: anytype,
    item: Item,
    groupLength: usize,
    display_options: option.DisplayOptions,
) !void {
    if (groupLength > 0) {
        try console.paddingSpace(writer, groupLength - math.log10(item.stat.gid) - 1);
    }

    try itemView.gid(writer, item, display_options);
}

fn printUserName(
    writer: anytype,
    item: Item,
    userLength: usize,
    display_options: option.DisplayOptions,
) !void {
    try itemView.userName(writer, item, display_options);
    var mutItem = item;

    if (userLength > 0) {
        if (mutItem.getUserName()) |u| {
            try console.paddingSpace(writer, userLength - mem.len(u));
        } else {
            try console.paddingSpace(writer, userLength - 1);
        }
    }
}

fn printGroupName(
    writer: anytype,
    item: Item,
    groupLength: usize,
    display_options: option.DisplayOptions,
) !void {
    try itemView.groupName(writer, item, display_options);
    var mutItem = item;

    if (groupLength > 0) {
        if (mutItem.getGroupName()) |g| {
            try console.paddingSpace(writer, groupLength - mem.len(g));
        } else {
            try console.paddingSpace(writer, groupLength - 1);
        }
    }
}

fn printBlocks(
    writer: anytype,
    item: Item,
    blocksLength: usize,
    display_options: option.DisplayOptions,
) !void {
    if (blocksLength > 0) {
        try console.paddingSpace(writer, blocksLength - (if (item.stat.blocks > 0) math.log10(item.stat.blocks) else 0) - 1);
    }

    try itemView.blocks(writer, item, display_options);
}

pub fn printSize(
    writer: anytype,
    item: Item,
    maxLength: usize,
    long_view_options: option.LongViewOptions,
    display_options: option.DisplayOptions,
) !void {
    if (item.isBlockDevice() or item.isCharacterDevice()) {
        const device_id_len = (if (item.stat.deviceId.?.major == 0) 0 else math.log10(item.stat.deviceId.?.major)) + (if (item.stat.deviceId.?.minor == 0) 0 else math.log10(item.stat.deviceId.?.minor)) + 1;
        try console.paddingSpace(writer, maxLength - device_id_len);
    } else if (long_view_options.bytes) {
        try console.paddingSpace(writer, maxLength - (if (item.stat.byte == 0) 0 else math.log10(item.stat.byte)) - 1);
    } else {
        try console.paddingSpace(writer, maxLength - item.size.len);
    }

    try itemView.size(writer, item, long_view_options, display_options);
}

fn getMaxSizeLength(items: std.MultiArrayList(Item), long_view_options: option.LongViewOptions) usize {
    var max_len: usize = 0;

    for (items.items(.stat)) |s, i| {
        const item = items.get(i);

        if (item.isBlockDevice() or item.isCharacterDevice()) {
            const device_id_len = (if (item.stat.deviceId.?.major == 0) 1 else math.log10(item.stat.deviceId.?.major)) + (if (item.stat.deviceId.?.minor == 0) 1 else math.log10(item.stat.deviceId.?.minor)) + 1;
            max_len = math.max(device_id_len, max_len);
        } else if (long_view_options.bytes) {
            max_len = math.max((if (s.byte == 0) 1 else math.log10(s.byte)) + 1, max_len);
        } else {
            max_len = math.max(item.size.len, max_len);
        }
    }

    return math.max(max_len, 4);
}

fn getMaxBlocksLength(items: std.MultiArrayList(Item)) usize {
    var max_len: usize = 0;

    for (items.items(.stat)) |s| {
        if (s.blocks == 0) {
            continue;
        }
        max_len = math.max(math.log10(s.blocks) + 1, max_len);
    }

    return math.max(max_len, 6);
}

fn getMaxUserNameLength(items: std.MultiArrayList(Item)) usize {
    var max_len: usize = 0;

    for (items.items(.stat)) |_, i| {
        var item = items.get(i);
        if (item.getUserName()) |u| {
            max_len = math.max(mem.len(u), max_len);
        }
    }

    return math.max(max_len, 4);
}

fn getMaxUidLength(items: std.MultiArrayList(Item)) usize {
    var max_len: usize = 0;

    for (items.items(.stat)) |_, i| {
        var item = items.get(i);
        max_len = math.max(math.log10(item.stat.uid), max_len);
    }

    return math.max(max_len, 3);
}

fn getMaxGidLength(items: std.MultiArrayList(Item)) usize {
    var max_len: usize = 0;

    for (items.items(.stat)) |_, i| {
        var item = items.get(i);
        max_len = math.max(math.log10(item.stat.gid), max_len);
    }

    return math.max(max_len, 3);
}

fn getMaxGroupNameLength(items: std.MultiArrayList(Item)) usize {
    var max_len: u64 = 0;

    for (items.items(.stat)) |_, i| {
        var item = items.get(i);

        if (item.getGroupName()) |g| {
            max_len = math.max(mem.len(g), max_len);
        }
    }

    return math.max(max_len, 4);
}
