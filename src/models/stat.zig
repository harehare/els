const std = @import("std");
const builtin = @import("builtin");

const os = std.os;

const Datetime = @import("datetime").datetime.Datetime;
const Permissions = @import("permissions.zig").Permissions;
const Permission = @import("permissions.zig").Permission;

const c = if (builtin.os.tag == .linux) @cImport({
    @cInclude("sys/sysmacros.h");
}) else @cImport({
    @cInclude("sys/stat.h");
    @cInclude("sys/types.h");
});

pub const StatError = error{
    FileNotFound,
};

pub const Kind = std.fs.File.Kind;

fn stModeToKind(mode: u32) Kind {
    if (std.c.S.ISDIR(mode)) {
        return Kind.Directory;
    }

    if (std.c.S.ISCHR(mode)) {
        return Kind.CharacterDevice;
    }

    if (std.c.S.ISBLK(mode)) {
        return Kind.BlockDevice;
    }

    if (std.c.S.ISFIFO(mode)) {
        return Kind.NamedPipe;
    }

    if (std.c.S.ISLNK(mode)) {
        return Kind.SymLink;
    }

    if (std.c.S.ISSOCK(mode)) {
        return Kind.UnixDomainSocket;
    }

    if (std.c.S.ISSOCK(mode)) {
        return Kind.UnixDomainSocket;
    }

    return Kind.File;
}

const DeviceId = struct {
    major: usize,
    minor: usize,
};

pub const Stat = struct {
    inode: usize,
    uid: usize,
    gid: usize,
    byte: usize,
    blocks: usize,
    links: usize,
    kind: Kind,
    deviceId: ?DeviceId,
    permissions: Permissions,
    created: Datetime,
    modified: Datetime,
    accessed: Datetime,

    const Self = @This();

    pub fn init(path: [*:0]const u8) !Self {
        if (builtin.os.tag == .linux) {
            var s: os.linux.Stat = undefined;

            if (os.linux.lstat(path, &s) != 0) {
                if (std.c._errno().* == 2) {
                    return error.FileNotFound;
                }
                return error.Unknown;
            }

            const kind = stModeToKind(s.mode);

            return Self{
                .inode = s.ino,
                .uid = s.uid,
                .gid = s.gid,
                .byte = if (s.size < 0) 0 else @intCast(usize, s.size),
                .blocks = if (s.blocks < 0) 0 else @intCast(usize, s.blocks),
                .links = @intCast(usize, s.nlink),
                .kind = kind,
                .deviceId = if (kind == Kind.BlockDevice or kind == Kind.CharacterDevice) DeviceId{
                    .major = @intCast(usize, c.major(s.rdev)),
                    .minor = @intCast(usize, c.minor(s.rdev)),
                } else null,
                .permissions = Permissions.init(s.mode),
                .accessed = if (s.atim.tv_sec < 0) Datetime.fromTimestamp(0) else Datetime.fromTimestamp(s.atim.tv_sec * 1000),
                .modified = if (s.mtim.tv_sec < 0) Datetime.fromTimestamp(0) else Datetime.fromTimestamp(s.mtim.tv_sec * 1000),
                .created = if (s.ctim.tv_sec < 0) Datetime.fromTimestamp(0) else Datetime.fromTimestamp(s.ctim.tv_sec * 1000),
            };
        } else if (builtin.os.tag == .macos) {
            var s: c.struct_stat = undefined;

            if (switch (builtin.cpu.arch) {
                .x86_64 => c.lstat64(path, @ptrToInt(&s)),
                else => c.lstat(path, @ptrToInt(&s)),
            } != 0) {
                if (std.c._errno().* == 2) {
                    return error.FileNotFound;
                }
                return error.Unknown;
            }

            const kind = stModeToKind(s.st_mode);

            return Self{
                .inode = s.st_ino,
                .uid = s.st_uid,
                .gid = s.st_gid,
                .byte = if (s.st_size < 0) 0 else @intCast(usize, s.st_size),
                .blocks = if (s.st_blocks < 0) 0 else @intCast(usize, s.st_blocks),
                .links = @intCast(usize, s.st_nlink),
                .kind = kind,
                .deviceId = if (kind == Kind.BlockDevice or kind == Kind.CharacterDevice) DeviceId{
                    .major = @intCast(usize, c.major(s.st_rdev)),
                    .minor = @intCast(usize, c.minor(s.st_rdev)),
                } else null,
                .permissions = Permissions.init(s.st_mode),
                .accessed = if (s.st_atimespec.tv_sec < 0) Datetime.fromTimestamp(0) else Datetime.fromTimestamp(s.st_atimespec.tv_sec * 1000),
                .modified = if (s.st_mtimespec.tv_sec < 0) Datetime.fromTimestamp(0) else Datetime.fromTimestamp(s.st_mtimespec.tv_sec * 1000),
                .created = if (s.st_ctimespec.tv_sec < 0) Datetime.fromTimestamp(0) else Datetime.fromTimestamp(s.st_ctimespec.tv_sec * 1000),
            };
        } else {
            @compileError("Unsupported OS");
        }
    }
};
