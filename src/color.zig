const std = @import("std");

const Item = @import("models/item.zig").Item;

pub const Color = struct {
    pub const none = "";
    pub const black = "\x1b[30m";
    pub const red = "\x1b[31m";
    pub const green = "\x1b[32m";
    pub const yellow = "\x1b[33m";
    pub const blue = "\x1b[34m";
    pub const magenta = "\x1b[35m";
    pub const cyan = "\x1b[36m";
    pub const white = "\x1b[37m";
    pub const gray = "\x1b[90m";
    pub const red2 = "\x1b[91m";
    pub const green2 = "\x1b[92m";
    pub const yellow2 = "\x1b[93m";
    pub const blue2 = "\x1b[94m";
    pub const magenta2 = "\x1b[95m";
    pub const bg_black = "\x1b[40m";
    pub const bg_red = "\x1b[41m";
    pub const bg_green = "\x1b[42m";
    pub const bg_yellow = "\x1b[43m";
    pub const bg_blue = "\x1b[44m";
    pub const bg_magenta = "\x1b[45m";
    pub const bg_cyan = "\x1b[46m";
    pub const bg_white = "\x1b[47m";

    const Self = @This();

    pub fn colored(item: Item) []const u8 {
        if (item.isDir()) {
            return Self.magenta;
        } else if (item.isSymLink()) {
            return Self.cyan;
        } else if (item.isBlockDevice()) {
            return Self.yellow2;
        } else if (item.isCharacterDevice()) {
            return Self.yellow2;
        } else if (item.isUnixDomainSocket()) {
            return Self.red2;
        } else if (item.isNamedPipe()) {
            return Self.yellow;
        }

        if (item.stat.permissions.user.canExecute) {
            return Self.green2;
        } else {
            return Self.none;
        }
    }
};
