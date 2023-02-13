const std = @import("std");
const Datetime = @import("datetime").datetime.Datetime;

const Item = @import("../models/item.zig").Item;
const itemView = @import("./item.zig");
const text = @import("../text.zig");
const Color = @import("../color.zig").Color;
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
    const len = items.len;

    for (items.items(.name)) |name, i| {
        try startItem(writer, display_options);

        const item = items.get(i);

        // inode
        if (long_view_options.inode or long_view_options.allFields) {
            try itemName(writer, "inode", display_options);
            try itemView.inode(writer, item, display_options);
            try separator(writer, display_options);
            try newLine(writer, display_options);
        }

        // Octal Permission
        if (long_view_options.octalPermissions) {
            try itemName(writer, "octal", display_options);
            try itemView.octalPermission(writer, item, display_options);
            try separator(writer, display_options);
            try newLine(writer, display_options);

            // permission
        } else if (!long_view_options.noPermissions or long_view_options.allFields) {
            try itemName(writer, "permissions", display_options);

            try startString(writer);
            try itemView.kind(writer, item, display_options);
            try itemView.permission(writer, item, display_options);
            try endString(writer);

            try separator(writer, display_options);
            try newLine(writer, display_options);
        }

        // kind
        try itemName(writer, "kind", display_options);

        try startString(writer);
        try itemView.kind(writer, item, display_options);
        try endString(writer);

        try separator(writer, display_options);
        try newLine(writer, display_options);

        // path
        if (display_options.path) {
            try itemName(writer, "path", display_options);

            try startString(writer);
            try itemView.path(writer, item, display_options);
            try endString(writer);

            try separator(writer, display_options);
            try newLine(writer, display_options);
        }

        // links
        if (long_view_options.links or long_view_options.allFields) {
            try itemName(writer, "links", display_options);
            try itemView.links(writer, item, display_options);
            try separator(writer, display_options);
            try newLine(writer, display_options);
        }

        // size
        if (!long_view_options.noFileSize or long_view_options.allFields) {
            try itemName(writer, "size", display_options);
            if (item.isDir() or item.isSymLink()) {
                try nullValue(writer);
                try separator(writer, display_options);
                try newLine(writer, display_options);
            } else {
                if (!long_view_options.bytes) {
                    try startString(writer);
                }

                try itemView.size(writer, item, long_view_options, display_options);

                if (!long_view_options.bytes) {
                    try endString(writer);
                }

                try separator(writer, display_options);
                try newLine(writer, display_options);
            }
        }

        // blocks
        if (long_view_options.blocks or long_view_options.allFields) {
            try itemName(writer, "blocks", display_options);
            try itemView.blocks(writer, item, display_options);
            try separator(writer, display_options);
            try newLine(writer, display_options);
        }

        // user
        if (!long_view_options.noUser or long_view_options.allFields) {
            if (long_view_options.numeric) {
                try itemName(writer, "uid", display_options);
                try itemView.uid(writer, item, display_options);
                try separator(writer, display_options);
                try newLine(writer, display_options);
            } else {
                try itemName(writer, "user", display_options);
                try startString(writer);
                try itemView.userName(writer, item, display_options);
                try endString(writer);
                try separator(writer, display_options);
                try newLine(writer, display_options);
            }
        }

        // group
        if (long_view_options.group or long_view_options.allFields) {
            if (long_view_options.numeric) {
                try itemName(writer, "gid", display_options);
                try itemView.gid(writer, item, display_options);
                try separator(writer, display_options);
                try newLine(writer, display_options);
            } else {
                try itemName(writer, "group", display_options);
                try startString(writer);
                try itemView.groupName(writer, item, display_options);
                try endString(writer);
                try separator(writer, display_options);
                try newLine(writer, display_options);
            }
        }

        // date
        if (!long_view_options.noTime or long_view_options.allFields) {
            if (long_view_options.created or long_view_options.allFields) {
                try itemName(writer, "created", display_options);

                if (long_view_options.timeStyle != option.TimeStyle.Timestamp) {
                    try startString(writer);
                }

                try itemView.created(writer, item, long_view_options, display_options);

                if (long_view_options.timeStyle != option.TimeStyle.Timestamp) {
                    try endString(writer);
                }

                try separator(writer, display_options);
                try newLine(writer, display_options);
            }

            if (long_view_options.accessed or long_view_options.allFields) {
                try itemName(writer, "accessed", display_options);

                if (long_view_options.timeStyle != option.TimeStyle.Timestamp) {
                    try startString(writer);
                }

                try itemView.accessed(writer, item, long_view_options, display_options);

                if (long_view_options.timeStyle != option.TimeStyle.Timestamp) {
                    try endString(writer);
                }

                try separator(writer, display_options);
                try newLine(writer, display_options);
            }

            if (long_view_options.modified or long_view_options.allFields or (!long_view_options.modified and !long_view_options.accessed and !long_view_options.created)) {
                try itemName(writer, "modified", display_options);

                if (long_view_options.timeStyle != option.TimeStyle.Timestamp) {
                    try startString(writer);
                }

                try itemView.modified(writer, item, long_view_options, display_options);

                if (long_view_options.timeStyle != option.TimeStyle.Timestamp) {
                    try endString(writer);
                }

                try separator(writer, display_options);
                try newLine(writer, display_options);
            }
        }

        // name
        if (item.isSymLink()) {
            // name
            try itemName(writer, "symlinkname", display_options);

            if (display_options.color.isAlways()) {
                try writer.print("{s}\"{s}\"{s}{s}", .{ Color.cyan, name, Color.gray, text.reset });
            } else {
                try writer.print("\"{s}\"", .{
                    name,
                });
            }

            if (item.link_item) |link_item| {
                try itemName(writer, "filename", display_options);
                try startString(writer);
                try itemView.linkItem(writer, link_item, display_options);
                try endString(writer);
            }
        } else {
            try itemName(writer, "filename", display_options);
            try startString(writer);
            try itemView.fileName(writer, item, display_options);
            try endString(writer);
        }

        try newLine(writer, display_options);
        try endItem(writer, display_options);

        if (i < len - 1) {
            if (display_options.style == option.DisplayStyle.Json) {
                try separator(writer, display_options);
            }
            try console.newLine(writer);
        }
    }
}

fn startItem(writer: anytype, display_options: option.DisplayOptions) !void {
    if (display_options.style == option.DisplayStyle.Json) {
        try writer.print("  {s}", .{"{"});
    } else {
        try writer.print("{s}", .{"{"});
    }
    try newLine(writer, display_options);
}

fn endItem(writer: anytype, display_options: option.DisplayOptions) !void {
    if (display_options.style == option.DisplayStyle.Json) {
        try writer.print("  {s}", .{"}"});
    } else {
        try writer.print("{s}", .{"}"});
    }
}

fn separator(writer: anytype, display_options: option.DisplayOptions) !void {
    if (display_options.style == option.DisplayStyle.Json) {
        try writer.print("{s}", .{","});
    } else {
        try writer.print("{s} ", .{","});
    }
}

fn startString(writer: anytype) !void {
    try writer.print("{s}", .{"\""});
}

fn endString(writer: anytype) !void {
    try writer.print("{s}", .{"\""});
}

fn nullValue(writer: anytype) !void {
    try writer.print("{s}", .{"null"});
}

fn itemName(writer: anytype, name: []const u8, display_options: option.DisplayOptions) !void {
    if (display_options.style == option.DisplayStyle.Json) {
        try writer.print("    \"{s}\": ", .{name});
    } else {
        try writer.print("\"{s}\": ", .{name});
    }
}

fn newLine(writer: anytype, display_options: option.DisplayOptions) !void {
    if (display_options.style == option.DisplayStyle.Json) {
        try console.newLine(writer);
    }
}
