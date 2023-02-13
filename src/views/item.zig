const std = @import("std");
const text = @import("../text.zig");
const console = @import("./console.zig");
const option = @import("../option.zig");

const Item = @import("../models/item.zig").Item;
const LinkItem = @import("../models/item.zig").LinkItem;
const Color = @import("../color.zig").Color;
const Icon = @import("../icon.zig").Icon;
const Datetime = @import("datetime").datetime.Datetime;

const fs = std.fs;
const math = std.math;

pub fn name(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    const icon = Icon.detect(item, display_options);
    const n = if (display_options.style == option.DisplayStyle.Classify) item.nameWithTypeIndicator() else if (display_options.path) item.path else item.name;

    if (std.mem.startsWith(u8, text.toLowercase(item.name), "readme")) {
        try console.printWithUnderline(writer, true, icon, Color.yellow2, n, display_options);
        return;
    }

    try console.print(writer, false, icon, Color.colored(item), n, display_options);
}

pub fn fileName(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    const icon = Icon.detect(item, display_options);
    try console.print(writer, true, icon, Color.colored(item), item.name, display_options);
}

pub fn linkItem(
    writer: anytype,
    link_item: LinkItem,
    display_options: option.DisplayOptions,
) !void {
    if (link_item.isDir()) {
        try console.print(writer, true, Icon.none, if (display_options.color.isAlways()) Color.blue else Color.none, link_item.path, display_options);
    } else if (link_item.isBlockDevice() or link_item.isCharacterDevice()) {
        try console.print(writer, true, Icon.none, if (display_options.color.isAlways()) Color.yellow2 else Color.none, link_item.path, display_options);
    } else {
        try console.print(writer, false, Icon.none, if (display_options.color.isAlways()) Color.white else Color.none, link_item.path, display_options);
    }
}

pub fn inode(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        try writer.print("{s}{d: <8}{s}", .{
            Color.magenta,
            item.stat.inode,
            text.reset,
        });
    } else {
        try writer.print("{d: <8}", .{
            item.stat.inode,
        });
    }
}

pub fn kind(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        const is_bold = item.isBlockDevice() or item.isCharacterDevice() or item.isUnixDomainSocket();

        if (is_bold) {
            try writer.print("{s}{s}{u}{s}", .{ Color.colored(item), text.Font.bold, item.toChar(), text.reset });
        } else {
            try writer.print("{s}{u}{s}", .{ Color.colored(item), item.toChar(), text.reset });
        }
    } else {
        try writer.print("{u} ", .{item.toChar()});
    }
}

pub fn path(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        try writer.print("{s}{s}{s}", .{ Color.colored(item), item.path, text.reset });
    } else {
        try writer.print("{s}", .{item.path});
    }
}

pub fn links(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        try writer.print("{s}{d}{s}", .{
            Color.red2,
            item.stat.links,
            text.reset,
        });
    } else {
        try writer.print("{d}", .{
            item.stat.links,
        });
    }
}

pub fn octalPermission(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    const octalPermissionsArray = try item.stat.permissions.toOctalArray();
    try console.char(writer, Color.magenta, octalPermissionsArray[0], display_options);
    try console.char(writer, Color.magenta, octalPermissionsArray[1], display_options);
    try console.char(writer, Color.magenta, octalPermissionsArray[2], display_options);
    try console.char(writer, Color.magenta, octalPermissionsArray[3], display_options);
}

pub fn permission(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    const permissionArray = try item.stat.permissions.toArray();
    const read_color = if (display_options.color.isAlways()) Color.yellow2 else Color.none;
    const write_color = if (display_options.color.isAlways()) Color.red2 else Color.none;
    const execute_color = if (display_options.color.isAlways()) Color.green2 else Color.none;

    try console.char(writer, read_color, permissionArray[0][0], display_options);
    try console.char(writer, write_color, permissionArray[0][1], display_options);
    try console.char(writer, execute_color, permissionArray[0][2], display_options);
    try console.space(writer);

    try console.char(writer, read_color, permissionArray[1][0], display_options);
    try console.char(writer, write_color, permissionArray[1][1], display_options);
    try console.char(writer, execute_color, permissionArray[1][2], display_options);
    try console.space(writer);

    try console.char(writer, read_color, permissionArray[2][0], display_options);
    try console.char(writer, write_color, permissionArray[2][1], display_options);
    try console.char(writer, execute_color, permissionArray[2][2], display_options);
}

pub fn size(
    writer: anytype,
    item: Item,
    long_view_options: option.LongViewOptions,
    display_options: option.DisplayOptions,
) !void {
    if (item.isBlockDevice() or item.isCharacterDevice()) {
        if (display_options.color.isAlways()) {
            try std.fmt.format(writer, "{s}{s}{d},{d}{s}", .{
                text.Font.bold,
                Color.green,
                item.stat.deviceId.?.major,
                item.stat.deviceId.?.minor,
                text.reset,
            });
        } else {
            try std.fmt.format(writer, "{d},{d}", .{
                item.stat.deviceId.?.major,
                item.stat.deviceId.?.minor,
            });
        }
        return;
    }

    if (long_view_options.bytes) {
        if (display_options.color.isAlways()) {
            try std.fmt.format(writer, "{s}{s}{d}{s}", .{
                text.Font.bold,
                Color.green,
                item.stat.byte,
                text.reset,
            });
        } else {
            try std.fmt.format(writer, "{d}", .{
                item.stat.byte,
            });
        }
        return;
    }

    if (display_options.color.isAlways()) {
        try std.fmt.format(writer, "{s}{s}{s}{s}", .{
            text.Font.bold,
            Color.green,
            item.size,
            text.reset,
        });
    } else {
        try std.fmt.format(writer, "{s}", .{
            item.size,
        });
    }
}

pub fn uid(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        try writer.print("{s}{s}{d}{s}", .{
            Color.yellow2,
            text.Font.bold,
            item.stat.uid,
            text.reset,
        });
    } else {
        try writer.print("{d}", .{
            item.stat.uid,
        });
    }
}

pub fn gid(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        try writer.print("{s}{s}{d}{s}", .{
            Color.yellow2,
            text.Font.bold,
            item.stat.gid,
            text.reset,
        });
    } else {
        try writer.print("{d}", .{
            item.stat.gid,
        });
    }
}

pub fn userName(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    var mutItem = item;

    if (mutItem.getUserName()) |u| {
        if (display_options.color.isAlways()) {
            try writer.print("{s}{s}{s}{s}", .{
                Color.yellow2,
                text.Font.bold,
                u,
                text.reset,
            });
        } else {
            try writer.print("{s}", .{
                u,
            });
        }
    } else {
        if (display_options.color.isAlways()) {
            try writer.print("{s}{s}{s}{s}", .{
                Color.yellow2,
                text.Font.bold,
                "-",
                text.reset,
            });
        } else {
            try writer.print("{s}", .{
                "-",
            });
        }
    }
}

pub fn groupName(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    var mutItem = item;
    if (mutItem.getGroupName()) |g| {
        if (display_options.color.isAlways()) {
            try writer.print("{s}{s}{s}{s}", .{
                Color.yellow2,
                text.Font.bold,
                g,
                text.reset,
            });
        } else {
            try writer.print("{s}", .{
                g,
            });
        }
    } else {
        if (display_options.color.isAlways()) {
            try writer.print("{s}{s}{s}{s}", .{
                Color.yellow2,
                text.Font.bold,
                "-",
                text.reset,
            });
        } else {
            try writer.print("{s}", .{
                "-",
            });
        }
    }
}

pub fn blocks(
    writer: anytype,
    item: Item,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        try writer.print("{s}{d}{s}", .{
            Color.cyan,
            item.stat.blocks,
            text.reset,
        });
    } else {
        try writer.print("{d}", .{
            item.stat.blocks,
        });
    }
}

pub fn created(
    writer: anytype,
    item: Item,
    long_view_options: option.LongViewOptions,
    display_options: option.DisplayOptions,
) !void {
    try printDatetime(writer, item.stat.created, long_view_options, display_options);
}

pub fn accessed(
    writer: anytype,
    item: Item,
    long_view_options: option.LongViewOptions,
    display_options: option.DisplayOptions,
) !void {
    try printDatetime(writer, item.stat.accessed, long_view_options, display_options);
}

pub fn modified(
    writer: anytype,
    item: Item,
    long_view_options: option.LongViewOptions,
    display_options: option.DisplayOptions,
) !void {
    try printDatetime(writer, item.stat.modified, long_view_options, display_options);
}

fn printDatetime(
    writer: anytype,
    d: Datetime,
    long_view_options: option.LongViewOptions,
    display_options: option.DisplayOptions,
) !void {
    if (long_view_options.timeStyle == option.TimeStyle.Iso) {
        if (display_options.color.isAlways()) {
            try std.fmt.format(writer, "{s}{s}{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}{s}", .{
                text.reset,
                Color.blue2,
                d.date.month,
                d.date.day,
                d.time.hour,
                d.time.minute,
                text.reset,
            });
        } else {
            try std.fmt.format(writer, "{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}", .{
                d.date.month,
                d.date.day,
                d.time.hour,
                d.time.minute,
            });
        }
    } else if (long_view_options.timeStyle == option.TimeStyle.LongIso) {
        if (display_options.color.isAlways()) {
            try std.fmt.format(writer, "{s}{s}{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}{s}", .{
                text.reset,
                Color.blue2,
                d.date.year,
                d.date.month,
                d.date.day,
                d.time.hour,
                d.time.minute,
                text.reset,
            });
        } else {
            try std.fmt.format(writer, "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}", .{
                d.date.year,
                d.date.month,
                d.date.day,
                d.time.hour,
                d.time.minute,
            });
        }
    } else if (long_view_options.timeStyle == option.TimeStyle.Timestamp) {
        if (display_options.color.isAlways()) {
            try std.fmt.format(writer, "{s}{s}{d}{s}", .{
                text.reset,
                Color.blue2,
                d.date.toTimestamp(),
                text.reset,
            });
        } else {
            try std.fmt.format(writer, "{d}", .{
                d.date.toTimestamp(),
            });
        }
    } else {
        if (display_options.color.isAlways()) {
            try std.fmt.format(writer, "{s}{s}{d: >2} {s} {d:0>2}:{d:0>2}{s}", .{
                text.reset,
                Color.blue2,
                d.date.day,
                d.date.monthName()[0..3],
                d.time.hour,
                d.time.minute,
                text.reset,
            });
        } else {
            try std.fmt.format(writer, "{d: >2} {s} {d:0>2}:{d:0>2}", .{
                d.date.day,
                d.date.monthName()[0..3],
                d.time.hour,
                d.time.minute,
            });
        }
    }
}
