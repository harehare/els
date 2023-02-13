const std = @import("std");
const text = @import("../text.zig");

pub const Permissions = struct {
    user: Permission,
    group: Permission,
    other: Permission,

    const Self = @This();

    pub fn init(mode: usize) Self {
        return Self{ .user = Permission{
            .canRead = mode & std.os.S.IRUSR != 0,
            .canWrite = mode & std.os.S.IWUSR != 0,
            .canExecute = mode & std.os.S.IXUSR != 0,
        }, .group = Permission{
            .canRead = mode & std.os.S.IRGRP != 0,
            .canWrite = mode & std.os.S.IWGRP != 0,
            .canExecute = mode & std.os.S.IWGRP != 0,
        }, .other = Permission{
            .canRead = mode & std.os.S.IROTH != 0,
            .canWrite = mode & std.os.S.IWOTH != 0,
            .canExecute = mode & std.os.S.IXOTH != 0,
        } };
    }

    pub fn default() Self {
        return Self{ .user = Permission{
            .canRead = false,
            .canWrite = false,
            .canExecute = false,
        }, .group = Permission{
            .canRead = false,
            .canWrite = false,
            .canExecute = false,
        }, .other = Permission{
            .canRead = false,
            .canWrite = false,
            .canExecute = false,
        } };
    }

    pub fn toArray(self: @This()) ![3][3]u8 {
        const u = try self.user.toArray();
        const g = try self.group.toArray();
        const o = try self.other.toArray();
        return [_][3]u8{ u, g, o };
    }

    pub fn toOctalArray(self: @This()) ![4]u8 {
        const u = self.user.toOctal();
        const g = self.group.toOctal();
        const o = self.other.toOctal();
        return [4]u8{ '0', u, g, o };
    }
};

pub const Permission = struct {
    canRead: bool,
    canWrite: bool,
    canExecute: bool,

    const Self = @This();

    pub fn toArray(self: Self) ![3]u8 {
        const r = getReadString(self.canRead);
        const w = getWriteString(self.canWrite);
        const e = getExecuteString(self.canExecute);
        return [_]u8{ r, w, e };
    }

    pub fn toOctal(self: Self) u8 {
        if (self.canRead and self.canWrite and self.canExecute) {
            return '7';
        }

        if (self.canRead and self.canWrite and !self.canExecute) {
            return '6';
        }

        if (self.canRead and !self.canWrite and self.canExecute) {
            return '5';
        }

        if (self.canRead and !self.canWrite and !self.canExecute) {
            return '4';
        }

        if (!self.canRead and self.canWrite and self.canExecute) {
            return '3';
        }

        if (!self.canRead and self.canWrite and !self.canExecute) {
            return '2';
        }

        if (!self.canRead and !self.canWrite and self.canExecute) {
            return '1';
        }

        return '0';
    }

    fn getReadString(canRead: bool) u8 {
        if (canRead) {
            return 'r';
        } else {
            return '-';
        }
    }

    fn getWriteString(canWrite: bool) u8 {
        if (canWrite) {
            return 'w';
        } else {
            return '-';
        }
    }

    fn getExecuteString(canExecute: bool) u8 {
        if (canExecute) {
            return 'x';
        } else {
            return '-';
        }
    }
};
