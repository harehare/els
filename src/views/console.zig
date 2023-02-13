const std = @import("std");
const text = @import("../text.zig");
const option = @import("../option.zig");

const io = std.io;
const fs = std.fs;

pub fn print(
    writer: anytype,
    is_bold: bool,
    icons: []const u8,
    color: []const u8,
    value: []const u8,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        if (is_bold) {
            try writer.print("{s}{s}{s}{s}{s}", .{ text.Font.bold, color, icons, value, text.reset });
        } else {
            try writer.print("{s}{s}{s}{s}", .{ color, icons, value, text.reset });
        }
    } else {
        try writer.print("{s}{s}", .{ icons, value });
    }
}

pub fn printWithUnderline(
    writer: anytype,
    is_bold: bool,
    icons: []const u8,
    color: []const u8,
    value: []const u8,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        if (is_bold) {
            try writer.print("{s}{s}{s}", .{ text.Font.bold, color, icons });
        } else {
            try writer.print("{s}{s}", .{ color, icons });
        }
    }

    try underline(writer, value, display_options);
}

pub fn char(
    writer: anytype,
    color: []const u8,
    value: u8,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        try writer.print("{s}{c}{s}", .{ color, value, text.reset });
    } else {
        try writer.print("{c}", .{value});
    }
}

pub fn space(writer: anytype) !void {
    try writer.print(" ", .{});
}

pub fn newLine(writer: anytype) !void {
    try writer.print("\n", .{});
}

pub fn underline(
    writer: anytype,
    value: []const u8,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.color.isAlways()) {
        try writer.print("{s}{s}{s}", .{ text.underline, value, text.reset });
    } else {
        try writer.print("{s}", .{
            value,
        });
    }
}

pub fn paddingSpace(
    writer: anytype,
    length: usize,
) !void {
    var i: usize = 0;
    while (i < length) {
        i += 1;
        try writer.print("{s}", .{" "});
    }
}
