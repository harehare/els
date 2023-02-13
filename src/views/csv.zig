const std = @import("std");
const Datetime = @import("datetime").datetime.Datetime;

const Item = @import("../models/item.zig").Item;
const Color = @import("../color.zig").Color;

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
    if (long_view_options.header or long_view_options.allFields) {
        try printHeader(
            writer,
            long_view_options,
        );
    }

    for (items.items(.name)) |name, i| {
        const item = items.get(i);

        // inode
        if (long_view_options.inode or long_view_options.allFields) {
            try itemView.inode(writer, item, display_options);
            try separator(writer);
        }

        // Octal Permission
        if (long_view_options.octalPermissions) {
            try itemView.octalPermission(writer, item, display_options);
            try separator(writer);
            // permission
        } else if (!long_view_options.noPermissions or long_view_options.allFields) {
            try itemView.kind(writer, item, display_options);
            try itemView.permission(writer, item, display_options);
            try separator(writer);
        }

        // links
        if (long_view_options.links or long_view_options.allFields) {
            try itemView.links(writer, item, display_options);
        }

        // size
        if (!long_view_options.noFileSize or long_view_options.allFields) {
            if (item.isDir() or item.isSymLink()) {
                try separator(writer);
            } else {
                try itemView.size(writer, item, long_view_options, display_options);
                try separator(writer);
            }
        }

        // blocks
        if (long_view_options.blocks or long_view_options.allFields) {
            try itemView.blocks(writer, item, display_options);
            try separator(writer);
        }

        // user
        if (!long_view_options.noUser or long_view_options.allFields) {
            if (long_view_options.numeric) {
                try itemView.uid(writer, item, display_options);
                try separator(writer);
            } else {
                try itemView.userName(writer, item, display_options);
                try separator(writer);
            }
        }

        // group
        if (long_view_options.group or long_view_options.allFields) {
            if (long_view_options.numeric) {
                try itemView.gid(writer, item, display_options);
                try separator(writer);
            } else {
                try itemView.groupName(writer, item, display_options);
                try separator(writer);
            }
        }

        // date
        if (!long_view_options.noTime or long_view_options.allFields) {
            if (long_view_options.created or long_view_options.allFields) {
                try itemView.created(writer, item, long_view_options, display_options);
            }

            if (long_view_options.accessed or long_view_options.allFields) {
                try itemView.accessed(writer, item, long_view_options, display_options);
            }

            if (long_view_options.modified or long_view_options.allFields or (!long_view_options.modified and !long_view_options.accessed and !long_view_options.created)) {
                try itemView.modified(writer, item, long_view_options, display_options);
            }

            try separator(writer);
        }

        // name
        if (item.isSymLink()) {
            // name
            try writer.print("{s}{s}{s}\t", .{ Color.cyan, name, Color.gray });
            if (item.link_item) |link_item| {
                try itemView.linkItem(writer, link_item, display_options);
            }
        } else {
            try itemView.name(writer, item, display_options);
        }

        try console.newLine(writer);
    }
}

fn separator(writer: anytype) !void {
    try writer.print("{s}", .{","});
}

fn printHeader(
    writer: anytype,
    long_view_options: option.LongViewOptions,
) !void {
    if (long_view_options.inode or long_view_options.allFields) {
        try writer.print("{s}{s}", .{ text.reset, "inode" });
        try separator(writer);
    }

    if (long_view_options.octalPermissions) {
        try writer.print("{s}{s}", .{ text.reset, "octal" });
        try separator(writer);
    }

    if (!long_view_options.noPermissions or long_view_options.allFields) {
        try writer.print("{s}", .{"permissions"});
        try separator(writer);
    }

    if (long_view_options.links or long_view_options.allFields) {
        try writer.print("{s}", .{"links"});
        try separator(writer);
    }

    try writer.print("{s}", .{"size"});
    try separator(writer);

    if (long_view_options.blocks or long_view_options.allFields) {
        try writer.print("{s}", .{"blocks"});
        try separator(writer);
    }

    if (!long_view_options.noUser) {
        if (long_view_options.numeric) {
            try writer.print("{s}", .{"uid"});
            try separator(writer);
        } else {
            try writer.print("{s}", .{"user"});
            try separator(writer);
        }
    }

    if (long_view_options.group) {
        if (long_view_options.numeric) {
            try writer.print("{s}", .{"gid"});
            try separator(writer);
        } else {
            try writer.print("{s}", .{"group"});
            try separator(writer);
        }
    }

    if (long_view_options.created or long_view_options.allFields) {
        try writer.print("{s}", .{"created"});
        try separator(writer);
    }

    if (long_view_options.accessed or long_view_options.allFields) {
        try writer.print("{s}", .{"accessed"});
        try separator(writer);
    }

    if (long_view_options.modified or (!long_view_options.modified and !long_view_options.created and !long_view_options.accessed) or long_view_options.allFields) {
        try writer.print("{s}", .{"modified"});
        try separator(writer);
    }

    try writer.print("{s}{s}\n", .{ "name", text.reset });
}
