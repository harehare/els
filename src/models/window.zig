const std = @import("std");
const builtin = @import("builtin");

const c = std.c;
const os = std.os;

pub const Window = struct {
    width: usize,
    height: usize,

    const Self = @This();

    pub fn init() !Self {
        if (builtin.os.tag == .linux) {
            var size: os.linux.winsize = undefined;
            const ret = os.linux.ioctl(0, os.linux.T.IOCGWINSZ, @ptrToInt(&size));

            if (ret != 0) {
                return error.WinsizeSyscallFailure;
            }

            return Self{
                .width = size.ws_col,
                .height = size.ws_row,
            };
        } else if (builtin.os.tag == .macos) {
            var size: c.winsize = undefined;
            const ret = c.ioctl(0, c.T.IOCGWINSZ, &size);

            if (ret != 0) {
                return error.WinsizeSyscallFailure;
            }

            return Self{
                .width = size.ws_col,
                .height = size.ws_row,
            };
        } else {
            @compileError("Unsupported OS");
        }
    }
};
