const std = @import("std");
const fs = std.fs;
const option = @import("./option.zig");

const String = @import("zig-string").String;
const Datetime = @import("datetime").datetime.Datetime;
const Item = @import("./models/item.zig").Item;
const Kind = @import("./models/item.zig").Kind;
const Window = @import("./models/window.zig").Window;
const Stat = @import("./models/stat.zig").Stat;
const Permissions = @import("./models/permissions.zig").Permissions;
const text = @import("./text.zig");
const main = @import("./main.zig");

const mem = std.mem;
const tmpDir = std.testing.tmpDir;
const expect = std.testing.expect;

const Pattern = std.meta.Tuple(&.{ option.DisplayOptions, option.LongViewOptions, []const u8 });
const tmp_file_name1 = "temp_test_file1.txt";
const tmp_file_name2 = "temp_file2.txt";

fn getWindow() Window {
    return Window{
        .width = 100,
        .height = 100,
    };
}

fn createFile(dir: fs.Dir, name: []const u8) !void {
    var file = try dir.createFile(name, .{});
    defer file.close();
}

fn createItem(name: []const u8) Item {
    const stat = Stat.init("") catch Stat{
        .inode = 0,
        .uid = 0,
        .gid = 0,
        .byte = 1000,
        .blocks = 0,
        .links = 0,
        .kind = Kind.Unknown,
        .deviceId = null,
        .permissions = Permissions.default(),
        .accessed = Datetime.fromTimestamp(0),
        .modified = Datetime.fromTimestamp(0),
        .created = Datetime.fromTimestamp(0),
    };

    return Item{
        .dir = "dir",
        .name = name,
        .path = name,
        .kind = stat.kind,
        .link_item = null,
        .size = "",
        .stat = stat,
        .user_name = null,
        .group_name = null,
    };
}

fn printTest(display_options: option.DisplayOptions, long_view_options: option.LongViewOptions, want: []const u8) !void {
    var tmp = tmpDir(.{});
    defer tmp.cleanup();

    {
        try createFile(tmp.dir, tmp_file_name1);
        try createFile(tmp.dir, tmp_file_name2);
    }

    var result = String.init(std.testing.allocator);
    defer result.deinit();

    const item1 = createItem(tmp_file_name1);
    const item2 = createItem(tmp_file_name2);
    var items = std.MultiArrayList(Item){};
    defer items.deinit(std.testing.allocator);

    {
        try items.append(std.testing.allocator, item1);
        try items.append(std.testing.allocator, item2);
    }

    try main.print(result.writer(), items, display_options, long_view_options, getWindow());

    try expect(result.cmp(want));

    {
        try tmp.dir.deleteFile(tmp_file_name1);
        try tmp.dir.deleteFile(tmp_file_name2);
    }
}

test "grid test" {
    const tests = [_]Pattern{
        .{ option.DisplayOptions{
            .style = option.DisplayStyle.Grid,
            .recurse = false,
            .icons = option.IconStyle.None,
            .path = false,
            .color = option.Color.None,
        }, option.LongViewOptions.default(), "temp_test_file1.txt  temp_file2.txt\n" },
        .{ option.DisplayOptions{
            .style = option.DisplayStyle.Grid,
            .recurse = false,
            .icons = option.IconStyle.None,
            .path = true,
            .color = option.Color.None,
        }, option.LongViewOptions.default(), "temp_test_file1.txt  temp_file2.txt\n" },
    };

    for (tests) |t| {
        try printTest(t.@"0", t.@"1", t.@"2");
    }
}

test "json test" {
    const tests = [_]Pattern{
        .{
            option.DisplayOptions{
                .style = option.DisplayStyle.Json,
                .recurse = false,
                .icons = option.IconStyle.None,
                .path = true,
                .color = option.Color.None,
            },
            option.LongViewOptions.default(),
            \\  {
            \\    "permissions": ". --- --- ---",
            \\    "kind": ". ",
            \\    "path": "temp_test_file1.txt",
            \\    "size": "",
            \\    "user": "root",
            \\    "modified": " 1 Jan 00:00",
            \\    "filename": "temp_test_file1.txt"
            \\  },
            \\  {
            \\    "permissions": ". --- --- ---",
            \\    "kind": ". ",
            \\    "path": "temp_file2.txt",
            \\    "size": "",
            \\    "user": "root",
            \\    "modified": " 1 Jan 00:00",
            \\    "filename": "temp_file2.txt"
            \\  }
        },
    };

    for (tests) |t| {
        try printTest(t.@"0", t.@"1", t.@"2");
    }
}

test "jsonl test" {
    const tests = [_]Pattern{
        .{
            option.DisplayOptions{
                .style = option.DisplayStyle.Jsonl,
                .recurse = false,
                .icons = option.IconStyle.None,
                .path = false,
                .color = option.Color.None,
            },
            option.LongViewOptions.default(),
            \\{"permissions": ". --- --- ---", "kind": ". ", "size": "", "user": "root", "modified": " 1 Jan 00:00", "filename": "temp_test_file1.txt"}
            \\{"permissions": ". --- --- ---", "kind": ". ", "size": "", "user": "root", "modified": " 1 Jan 00:00", "filename": "temp_file2.txt"}
        },
        .{
            option.DisplayOptions{
                .style = option.DisplayStyle.Jsonl,
                .recurse = false,
                .icons = option.IconStyle.None,
                .path = true,
                .color = option.Color.None,
            },
            option.LongViewOptions.default(),
            \\{"permissions": ". --- --- ---", "kind": ". ", "path": "temp_test_file1.txt", "size": "", "user": "root", "modified": " 1 Jan 00:00", "filename": "temp_test_file1.txt"}
            \\{"permissions": ". --- --- ---", "kind": ". ", "path": "temp_file2.txt", "size": "", "user": "root", "modified": " 1 Jan 00:00", "filename": "temp_file2.txt"}
        },
    };

    for (tests) |t| {
        try printTest(t.@"0", t.@"1", t.@"2");
    }
}

test "long test" {
    const tests = [_]Pattern{
        .{
            option.DisplayOptions{
                .style = option.DisplayStyle.Long,
                .recurse = false,
                .icons = option.IconStyle.None,
                .path = true,
                .color = option.Color.None,
            },
            option.LongViewOptions.default(),
            \\.  --- --- ---      root  1 Jan 00:00  temp_test_file1.txt
            \\.  --- --- ---      root  1 Jan 00:00  temp_file2.txt
            \\
        },
    };

    for (tests) |t| {
        try printTest(t.@"0", t.@"1", t.@"2");
    }
}

test "oneline test" {
    const tests = [_]Pattern{
        .{
            option.DisplayOptions{
                .style = option.DisplayStyle.Oneline,
                .recurse = false,
                .icons = option.IconStyle.None,
                .path = true,
                .color = option.Color.None,
            },
            option.LongViewOptions.default(),
            \\temp_test_file1.txt
            \\temp_file2.txt
            \\
        },
    };

    for (tests) |t| {
        try printTest(t.@"0", t.@"1", t.@"2");
    }
}

test "csv test" {
    const tests = [_]Pattern{
        .{
            option.DisplayOptions{
                .style = option.DisplayStyle.Csv,
                .recurse = false,
                .icons = option.IconStyle.None,
                .path = true,
                .color = option.Color.None,
            },
            option.LongViewOptions.default(),
            \\. --- --- ---,,root, 1 Jan 00:00,temp_test_file1.txt
            \\. --- --- ---,,root, 1 Jan 00:00,temp_file2.txt
            \\
        },
    };

    for (tests) |t| {
        try printTest(t.@"0", t.@"1", t.@"2");
    }
}
