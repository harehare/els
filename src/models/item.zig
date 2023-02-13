const std = @import("std");

const Datetime = @import("datetime").datetime.Datetime;
const Stat = @import("./stat.zig").Stat;
const Permissions = @import("permissions.zig").Permissions;
const Permission = @import("permissions.zig").Permission;

const text = @import("../text.zig");

const fmt = std.fmt;
const mem = std.mem;
const fs = std.fs;
const os = std.os;

const kb_float = 1000.0;
const mb_float = kb_float * 1000.0;
const gb_float = mb_float * 1000.0;

const c = @cImport({
    @cInclude("grp.h");
    @cInclude("pwd.h");
});

const nano_second = 100 * 100 * 100;

pub const Kind = fs.IterableDir.Entry.Kind;
pub const Item = struct {
    dir: []const u8,
    name: []const u8,
    path: []const u8,
    link_item: ?LinkItem,
    kind: Kind,
    size: []u8,
    stat: Stat,
    user_name: ?[*]u8,
    group_name: ?[*]u8,

    const Self = @This();

    pub const Field = enum {
        Name,
        Kind,
        Inode,
        Size,
        Created,
        Modified,
        Accessed,
        Extension,
        None,
        pub fn fromString(x: []const u8) Field {
            if (std.mem.eql(u8, x, "name")) {
                return Field.Name;
            }

            if (std.mem.eql(u8, x, "kind")) {
                return Field.Kind;
            }

            if (std.mem.eql(u8, x, "inode")) {
                return Field.Inode;
            }

            if (std.mem.eql(u8, x, "size")) {
                return Field.Size;
            }

            if (std.mem.eql(u8, x, "created")) {
                return Field.Created;
            }

            if (std.mem.eql(u8, x, "modified")) {
                return Field.Modified;
            }

            if (std.mem.eql(u8, x, "accessed")) {
                return Field.Accessed;
            }

            if (std.mem.eql(u8, x, "extension")) {
                return Field.Extension;
            }

            return Field.None;
        }
    };

    pub const SortContext = struct {
        reverse: bool,
        groupDirectoriesFirst: bool,
        sort_field: Field,
        items: std.MultiArrayList(Item),

        pub fn lessThan(self: @This(), a_index: usize, b_index: usize) bool {
            const a = self.items.get(a_index);
            const b = self.items.get(b_index);

            if (self.groupDirectoriesFirst) {
                if (@enumToInt(a.kind) != @enumToInt(b.kind)) {
                    if (@enumToInt(a.kind) < @enumToInt(b.kind)) {
                        return true;
                    } else {
                        return false;
                    }
                }
            }

            if (self.sort_field == Field.Name) {
                if (self.reverse) {
                    return !std.mem.lessThan(u8, a.name, b.name);
                } else {
                    return std.mem.lessThan(u8, a.name, b.name);
                }
            }

            if (self.sort_field == Field.Inode) {
                if (self.reverse) {
                    return a.stat.inode < b.stat.inode or !std.mem.lessThan(u8, a.name, b.name);
                } else {
                    return a.stat.inode > b.stat.inode or std.mem.lessThan(u8, a.name, b.name);
                }
            }

            if (self.sort_field == Field.Size) {
                if (self.reverse) {
                    return a.stat.byte < b.stat.byte or !std.mem.lessThan(u8, a.name, b.name);
                } else {
                    return a.stat.byte > b.stat.byte or std.mem.lessThan(u8, a.name, b.name);
                }
            }

            if (self.sort_field == Field.Created) {
                if (self.reverse) {
                    return a.stat.created.toSeconds() < b.stat.created.toSeconds() or !std.mem.lessThan(u8, a.name, b.name);
                } else {
                    return a.stat.created.toSeconds() > b.stat.created.toSeconds() or std.mem.lessThan(u8, a.name, b.name);
                }
            }

            if (self.sort_field == Field.Modified) {
                if (self.reverse) {
                    return a.stat.modified.toSeconds() < b.stat.modified.toSeconds() or !std.mem.lessThan(u8, a.name, b.name);
                } else {
                    return a.stat.modified.toSeconds() > b.stat.modified.toSeconds() or std.mem.lessThan(u8, a.name, b.name);
                }
            }

            if (self.sort_field == Field.Accessed) {
                if (self.reverse) {
                    return a.stat.accessed.toSeconds() < b.stat.accessed.toSeconds() or !std.mem.lessThan(u8, a.name, b.name);
                } else {
                    return a.stat.accessed.toSeconds() > b.stat.accessed.toSeconds() or std.mem.lessThan(u8, a.name, b.name);
                }
            }

            if (self.sort_field == Field.Extension) {
                if (self.reverse) {
                    return !std.mem.lessThan(u8, a.ext(), b.ext());
                } else {
                    return std.mem.lessThan(u8, a.ext(), b.ext());
                }
            }

            if (self.reverse) {
                return !std.mem.lessThan(u8, a.name, b.name);
            } else {
                return std.mem.lessThan(u8, a.name, b.name);
            }
        }
    };

    pub fn nameWithTypeIndicator(self: Self) []const u8 {
        var buf: [2 << 19]u8 = undefined;
        const canExecute = self.stat.permissions.user.canExecute;
        const execute = if (canExecute) "*" else "";

        return switch (self.kind) {
            Kind.Directory => std.fmt.bufPrint(&buf, "{s}{s}", .{ self.name, "/" }) catch self.name,
            Kind.SymLink => std.fmt.bufPrint(&buf, "{s}{s}", .{ self.name, "@" }) catch self.name,
            Kind.NamedPipe => std.fmt.bufPrint(&buf, "{s}{s}", .{ self.name, "|" }) catch self.name,
            Kind.Door => std.fmt.bufPrint(&buf, "{s}{s}", .{ self.name, ">" }) catch self.name,
            Kind.UnixDomainSocket => std.fmt.bufPrint(&buf, "{s}{s}", .{ self.name, "=" }) catch self.name,
            else => std.fmt.bufPrint(&buf, "{s}{s}", .{ self.name, execute }) catch self.name,
        };
    }

    pub fn getGroupName(self: *Self) ?[*c]u8 {
        if (self.group_name) |g| {
            return g;
        } else {
            const g: ?*c.group = c.getgrgid(@intCast(c_uint, self.stat.gid));

            if (g) |group| {
                self.group_name = group.gr_name;
                return self.group_name.?;
            } else {
                return null;
            }
        }
    }

    pub fn getUserName(self: *Self) ?[*c]u8 {
        if (self.user_name) |u| {
            return u;
        } else {
            const u: ?*c.passwd = c.getpwuid(@intCast(c_uint, self.stat.uid));

            if (u) |user| {
                self.user_name = user.pw_name;
                return self.user_name.?;
            } else {
                return null;
            }
        }
    }

    pub fn ext(self: Self) []const u8 {
        return fs.path.extension(self.path);
    }

    pub fn isDotFile(name: []const u8) bool {
        return name[0] == '.';
    }

    pub fn isDir(self: Self) bool {
        return self.kind == Kind.Directory;
    }

    pub fn isSymLink(self: Self) bool {
        return self.kind == Kind.SymLink;
    }

    pub fn isBlockDevice(self: Self) bool {
        return self.kind == Kind.BlockDevice;
    }

    pub fn isCharacterDevice(self: Self) bool {
        return self.kind == Kind.CharacterDevice;
    }

    pub fn isUnixDomainSocket(self: Self) bool {
        return self.kind == Kind.UnixDomainSocket;
    }

    pub fn isNamedPipe(self: Self) bool {
        return self.kind == Kind.NamedPipe;
    }

    pub fn isUnknown(self: Self) bool {
        return self.kind == Kind.Unknown;
    }

    pub fn toChar(self: Self) u8 {
        if (self.isDir()) {
            return 'd';
        } else if (self.isSymLink()) {
            return 'l';
        } else if (self.isBlockDevice()) {
            return 'b';
        } else if (self.isCharacterDevice()) {
            return 'c';
        } else if (self.isUnixDomainSocket()) {
            return 's';
        } else if (self.isNamedPipe()) {
            return '|';
        }
        return '.';
    }

    fn getSize(allocator: std.mem.Allocator, byte: usize) ![]u8 {
        const b = @intToFloat(f64, byte);
        const kb = b / kb_float;
        const mb = b / mb_float;
        const gb = b / gb_float;

        if (gb >= 1.0) {
            return try std.fmt.allocPrint(allocator, "{d: >.1}G", .{
                gb,
            });
        } else if (mb >= 1.0) {
            return try std.fmt.allocPrint(allocator, "{d: >.1}M", .{
                mb,
            });
        } else if (kb >= 1.0) {
            return try std.fmt.allocPrint(allocator, "{d: >.1}K", .{
                kb,
            });
        }
        return try std.fmt.allocPrint(allocator, "{d}", .{
            byte,
        });
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.dir);
        allocator.free(self.path);
        allocator.free(self.size);

        if (self.link_item) |link| {
            link.deinit(allocator);
        }
    }

    pub fn init(
        allocator: std.mem.Allocator,
        dir_name: []const u8,
        name: []const u8,
        kind: Kind,
    ) !Self {
        const relative_path = try fs.path.joinZ(allocator, &[_][]const u8{ dir_name, name });
        errdefer {
            allocator.free(relative_path);
        }

        const stat = try Stat.init(relative_path);
        const link: ?LinkItem = if (kind == Kind.SymLink) try LinkItem.init(allocator, relative_path) else null;

        const alloc_name = try allocator.alloc(u8, name.len);
        errdefer {
            allocator.free(alloc_name);
        }
        std.mem.copy(u8, alloc_name, name);

        const alloc_dir = try allocator.alloc(u8, dir_name.len);
        std.mem.copy(u8, alloc_dir, dir_name);
        errdefer {
            allocator.free(alloc_dir);
        }

        return Self{
            .dir = alloc_dir,
            .name = alloc_name,
            .path = relative_path,
            .kind = if (kind == Kind.Unknown) stat.kind else kind,
            .link_item = link,
            .size = try getSize(allocator, stat.byte),
            .stat = stat,
            .user_name = null,
            .group_name = null,
        };
    }
};

fn getDenyAllPermission() Permissions {
    return Permissions{ .user = Permission{
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

fn getPermission(metadata: fs.File.Metadata) !Permissions {
    const permission = metadata.permissions();
    return getPermissionUnix(permission.inner);
}

fn getPermissionWindows(_: fs.File.PermissionsWindows) !Permissions {
    return Permissions{
        .user = Permission{ .read = false, .write = false, .execute = false },
        .group = Permission{ .read = false, .write = false, .execute = false },
        .other = Permission{ .read = false, .write = false, .execute = false },
    };
}

fn getPermissionUnix(permission: fs.File.PermissionsUnix) !Permissions {
    return Permissions{ .user = Permission{
        .canRead = permission.unixHas(fs.File.PermissionsUnix.Class.user, fs.File.PermissionsUnix.Permission.read),
        .canWrite = permission.unixHas(fs.File.PermissionsUnix.Class.user, fs.File.PermissionsUnix.Permission.write),
        .canExecute = permission.unixHas(fs.File.PermissionsUnix.Class.user, fs.File.PermissionsUnix.Permission.execute),
    }, .group = Permission{
        .canRead = permission.unixHas(fs.File.PermissionsUnix.Class.group, fs.File.PermissionsUnix.Permission.read),
        .canWrite = permission.unixHas(fs.File.PermissionsUnix.Class.group, fs.File.PermissionsUnix.Permission.write),
        .canExecute = permission.unixHas(fs.File.PermissionsUnix.Class.group, fs.File.PermissionsUnix.Permission.execute),
    }, .other = Permission{
        .canRead = permission.unixHas(fs.File.PermissionsUnix.Class.other, fs.File.PermissionsUnix.Permission.read),
        .canWrite = permission.unixHas(fs.File.PermissionsUnix.Class.other, fs.File.PermissionsUnix.Permission.write),
        .canExecute = permission.unixHas(fs.File.PermissionsUnix.Class.other, fs.File.PermissionsUnix.Permission.execute),
    } };
}

pub const LinkItem = struct {
    path: []const u8,
    stat: Stat,

    const Self = @This();

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        allocator.free(self.path);
    }

    pub fn init(allocator: std.mem.Allocator, path: []u8) !LinkItem {
        const link = try readlink(path);
        const alloc_link = try allocator.alloc(u8, link.len);
        std.mem.copy(u8, alloc_link, link);

        errdefer {
            allocator.free(alloc_link);
        }

        const relative_path = if (fs.path.isAbsolute(link)) try fs.path.joinZ(
            allocator,
            &[_][]const u8{ link, "" },
        ) else try fs.path.joinZ(
            allocator,
            &[_][]const u8{
                fs.path.dirname(path) orelse "", link,
            },
        );
        defer {
            allocator.free(relative_path);
        }

        const stat = Stat.init(relative_path) catch Stat{
            .inode = 0,
            .uid = 0,
            .gid = 0,
            .byte = 0,
            .blocks = 0,
            .links = 0,
            .kind = Kind.Unknown,
            .deviceId = null,
            .permissions = Permissions.default(),
            .accessed = Datetime.fromTimestamp(0),
            .modified = Datetime.fromTimestamp(0),
            .created = Datetime.fromTimestamp(0),
        };

        return LinkItem{
            .path = alloc_link,
            .stat = stat,
        };
    }

    pub fn isDir(self: Self) bool {
        return self.stat.kind == Kind.Directory;
    }

    pub fn isBlockDevice(self: Self) bool {
        return self.stat.kind == Kind.BlockDevice;
    }

    pub fn isCharacterDevice(self: Self) bool {
        return self.stat.kind == Kind.CharacterDevice;
    }

    fn readlink(path: []u8) ![]u8 {
        if (fs.path.isAbsolute(path)) {
            var b: [2 << 19]u8 = undefined;
            return try os.readlink(path, b[0..]);
        } else {
            var b: [2 << 19]u8 = undefined;
            return try fs.cwd().realpath(path, b[0..]);
        }
    }
};
