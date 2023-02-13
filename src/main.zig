const clap = @import("clap");
const std = @import("std");

const Regex = @import("regex").Regex;

const Item = @import("models/item.zig").Item;
const Kind = @import("models/item.zig").Kind;
const Window = @import("models/window.zig").Window;
const Stat = @import("models/stat.zig").Stat;
const Color = @import("color.zig").Color;

const text = @import("text.zig");
const grid = @import("views/grid.zig");
const oneline = @import("views/oneline.zig");
const long = @import("views/long.zig");
const csv = @import("views/csv.zig");
const json = @import("views/json.zig");
const errorView = @import("views/error.zig");
const console = @import("views/console.zig");
const option = @import("option.zig");

const fs = std.fs;
const io = std.io;
const process = std.process;
const testing = std.testing;

test "els" {
    testing.refAllDecls(@This());
}

const version = "0.0.1";
const help =
    \\Usage:
    \\  els [options] [files...]
    \\
    \\-h, --help       Display this help and exit.
    \\-v, --version    Output version information and exit.
    \\
    \\DISPLAY OPTIONS
    \\  -1, --oneline    Display one entry per line.
    \\  -l, --long       Display extended file metadata as a table.
    \\  -G, --grid       Display entries as a grid (default).
    \\  -F, --classify   Display type indicator by file names
    \\  -c, --csv        Display entries as csv
    \\  -j, --json       Display entries as json
    \\  -J, --jsonl      Display entries as jsonl
    \\  -p, --path       Display full path
    \\  -R, --recurse    Recurse into directories
    \\  --color COLOR    Use terminal colours (always, never)
    \\  --icons ICONS    Display icons (nerd, unicode)
    \\  --no-dir-name    Don't display dir name
    \\
    \\FILTERING AND SORTING OPTIONS
    \\  -a, --all                 Show hidden and 'dot' files.
    \\  -r, --reverse             Reverse the sort order
    \\  -s, --sort SORT_FIELD     Which field to sort by (choices: name, extension, size, modified, accessed, created, inode)
    \\  -L, --level DEPTH         Limit the depth of recursion
    \\  -D, --only-dirs           List only directories
    \\  -e  --exclude EXCLUDE     Do not show files that match the given regular expression
    \\  -o  --only    ONLY        Only show files that match the given regular expression
    \\  --group-directories-first list directories before other files
    \\
    \\LONG VIEW, CSV AND JSON OPTIONS
    \\  -B, --bytes          List file sizes in bytes
    \\  -g, --group          List each file's group
    \\  -i, --inode          List each file's inode number
    \\  -H, --header         Add a header row to each column
    \\  -U, --created        Use the created timestamp field
    \\  -u, --accessed       Use the accessed timestamp field
    \\  -m, --modified       Use the modified timestamp field
    \\  -n, --numeric        List numeric user and group IDs
    \\  --all-fields         Show all fields
    \\  --blocks             Show number of file system blocks
    \\  --links              List each file’s number of hard links
    \\  --no-permissions     Suppress the permissions field
    \\  --no-filesize        Suppress the filesize field
    \\  --no-user            Suppress the user field
    \\  --no-time            Suppress the time field
    \\  --time-style         How to format timestamps (default, iso, long-iso, timestamp)
    \\  --octal-permissions  List each file's permission in octal format
;

pub fn main() anyerror!void {
    const params = comptime clap.parseParamsComptime(
        \\-B, --bytes                    list file sizes in bytes
        \\-h, --help                     Display this help and exit.
        \\-1, --oneline                  Display one entry per line.
        \\-l, --long                     Display extended file metadata as a table.
        \\-D, --only-dirs                List only directories
        \\-G, --grid                     Display entries as a grid (default).
        \\-F, --classify                 Display type indicator by file names
        \\-a, --all                      Show hidden and 'dot' files.
        \\-r, --reverse                  Reverse the sort order
        \\-s, --sort <str>               Which field to sort by
        \\-i, --inode                    List each file's inode number
        \\-g, --group                    List each file's group
        \\-H, --header                   Add a header row to each column
        \\-U, --created                  Use the created timestamp field
        \\-u, --accessed                 Use the accessed timestamp field
        \\-R, --recurse                  Recurse into directories
        \\-L, --level <usize>            Limit the depth of recursion
        \\-n, --numeric                  List numeric user and group IDs
        \\-p, --path                     Display full path
        \\-m, --modified                 Use the modified timestamp field
        \\-c, --csv                      Display entries as csv
        \\-j, --json                     Display entries as json
        \\-J, --jsonl                    Display entries as jsonl
        \\--color <str>                  Use terminal colours (always, never)
        \\--dirs                         Show directories in the output
        \\--files                        Show directories in the output
        \\--blocks                       Show number of file system blocks
        \\--links                        List each file’s number of hard links
        \\--icons <str>                  Display icons
        \\--no-permissions               Suppress the permissions field
        \\--no-filesize                  Suppress the filesize field
        \\--no-user                      Suppress the user field
        \\--no-time                      Suppress the time field
        \\--octal-permissions            List each file's permission in octal format
        \\--time-style <str>             How to format timestamps (default, iso, long-iso)
        \\--no-dir-name                  Don't display dir name
        \\--all-fields                   Show all fields
        \\--group-directories-first      List directories before other files
        \\-v, --version                  Output version information and exit.
        \\-e, --exclude <str>            Do not show files that match the given regular expression
        \\-o, --only     <str>            Only show files that match the given regular expression
        \\<str>...
        \\
    );

    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(stderr, err) catch {};
        return;
    };
    defer res.deinit();

    if (res.args.help) {
        try stdout.print("{s}", .{help});
        return;
    }

    if (res.args.version) {
        try stdout.print("els {s}{s}\n", .{ Color.yellow, version });
        return;
    }

    var env_map = try process.getEnvMap(allocator);
    defer env_map.deinit();

    var filtering_and_sorting_options = option.FiltringAndSortingOptions.fromEnv(env_map).updateFromArgs(res.args) catch |err| {
        if (err == option.OptionError.InvalidSortField) {
            try stderr.print("{s}Option --sort (-s) has no \"{s}\" (choices: name, extension, size, modified, accessed, created, inode){s}\n", .{
                Color.red,
                res.args.sort.?,
                text.reset,
            });
        }
        return;
    };
    var display_options = option.DisplayOptions.fromEnv(env_map).updateFromArgs(res.args) catch |err| {
        if (err == option.OptionError.InvalidColor) {
            try stderr.print("{s}Option --color has no \"{s}\" (choices: always, never{s}\n", .{
                Color.red,
                res.args.color.?,
                text.reset,
            });
        }

        if (err == option.OptionError.InvalidIcons) {
            try stderr.print("{s}Option --icons has no \"{s}\" (choices: nerd, unicode{s}\n", .{
                Color.red,
                res.args.icons.?,
                text.reset,
            });
        }
        return;
    };
    var long_view_options = option.LongViewOptions.fromEnv(env_map).updateFromArgs(res.args) catch |err| {
        if (err == option.OptionError.InvalidTimeStyle) {
            try stderr.print("{s}Option --time-style has no \"{s}\" (choices: default, iso, long-iso{s}\n", .{
                Color.red,
                res.args.@"time-style".?,
                text.reset,
            });
        }
        return;
    };

    const window = Window.init() catch Window{ .width = 128, .height = 128 };
    var path_list = std.ArrayList([]const u8).init(allocator);
    defer path_list.deinit();

    for (res.positionals) |pos| {
        try path_list.append(pos);
    }

    try start(stdout, display_options);

    if (path_list.items.len == 0) {
        const current_path = if (display_options.path) try std.fs.cwd().realpathAlloc(allocator, ".") else ".";
        defer {
            if (display_options.path) {
                allocator.free(current_path);
            }
        }
        try path_list.append(current_path);
        run(
            allocator,
            stdout,
            path_list,
            filtering_and_sorting_options,
            display_options,
            long_view_options,
            window,
            display_options.recurse,
            0,
            0,
        );
    } else if (path_list.items.len > 1) {
        var dir_map = try groupByDir(allocator, path_list);
        defer dir_map.deinit();

        var dir_iterator = dir_map.valueIterator();
        var order: usize = 0;

        while (dir_iterator.next()) |value| {
            var sub_path_list = value.*;
            defer {
                value.deinit();
                sub_path_list.deinit();
            }

            run(
                allocator,
                stdout,
                sub_path_list,
                filtering_and_sorting_options,
                display_options,
                long_view_options,
                window,
                true,
                order,
                0,
            );
            order += 1;
        }
    } else {
        run(
            allocator,
            stdout,
            path_list,
            filtering_and_sorting_options,
            display_options,
            long_view_options,
            window,
            display_options.recurse,
            0,
            0,
        );
    }

    try end(stdout, display_options);
}

fn start(
    writer: fs.File.Writer,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.style == option.DisplayStyle.Json) {
        try writer.print("{s}\n", .{"["});
    }
}

fn end(
    writer: fs.File.Writer,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.style == option.DisplayStyle.Json) {
        try writer.print("\n{s}\n", .{"]"});
    }
}

fn startSubItem(
    writer: anytype,
    display_options: option.DisplayOptions,
) !void {
    if (display_options.style == option.DisplayStyle.Json) {
        try writer.print(",\n", .{});
    }
}

fn run(
    allocator: std.mem.Allocator,
    writer: fs.File.Writer,
    path_list: std.ArrayList([]const u8),
    filtering_and_sorting_options: option.FiltringAndSortingOptions,
    display_options: option.DisplayOptions,
    long_view_options: option.LongViewOptions,
    window: Window,
    print_path: bool,
    order: usize,
    level: usize,
) void {
    if (level > filtering_and_sorting_options.level) {
        return;
    }

    var buf = std.io.bufferedWriter(writer);
    const w = buf.writer();
    const head = path_list.items[0];

    var items = if (path_list.items.len == 1) getItems(allocator, head) catch |err| {
        errorView.print(w, err, head) catch {};
        buf.flush() catch {};
        return;
    } else files(allocator, path_list) catch |err| {
        errorView.print(w, err, head) catch {};
        buf.flush() catch {};
        return;
    };

    defer {
        for (items.items(.name)) |_, i| {
            items.get(i).deinit(allocator);
        }
        items.deinit(allocator);
    }

    var filterd_items = filterFiles(allocator, items, filtering_and_sorting_options) catch items;
    defer filterd_items.deinit(allocator);

    if (filterd_items.len == 0) {
        return;
    }

    if (level > 0) {
        startSubItem(w, display_options) catch {};
    }

    const is_print_path = print_path and !std.mem.eql(u8, head, ".") and display_options.style != option.DisplayStyle.Csv and display_options.style != option.DisplayStyle.Json;

    if (is_print_path) {
        if (!long_view_options.noDirName) {
            if (level > 0 or order > 0) {
                console.newLine(w) catch {};
            }

            if (path_list.items.len == 1) {
                w.print("{s}{s}:\n", .{ text.reset, head }) catch {};
            } else {
                if (fs.path.dirname(head)) |p| {
                    w.print("{s}{s}:\n", .{ text.reset, p }) catch {};
                }
            }
        }
    }

    sortItems(filtering_and_sorting_options, filterd_items);
    print(w, filterd_items, display_options, long_view_options, window) catch {};

    buf.flush() catch {};

    if (filterd_items.len > 0) {
        for (filterd_items.items(.name)) |_, i| {
            const sub_item = items.get(i);

            if (display_options.recurse and sub_item.isDir()) {
                var sub_path_list = std.ArrayList([]const u8).init(allocator);
                defer sub_path_list.deinit();
                sub_path_list.append(sub_item.path) catch {};

                run(
                    allocator,
                    writer,
                    sub_path_list,
                    filtering_and_sorting_options,
                    display_options,
                    long_view_options,
                    window,
                    print_path,
                    order,
                    level + 1,
                );
            }
        }
    }
}

fn sortItems(filter_options: option.FiltringAndSortingOptions, items: std.MultiArrayList(Item)) void {
    if (filter_options.reverse) {
        const sottContext = Item.SortContext{
            .reverse = true,
            .groupDirectoriesFirst = filter_options.groupDirectoriesFirst,
            .items = items,
            .sort_field = filter_options.sort,
        };
        items.sort(sottContext);
    } else {
        const sottContext = Item.SortContext{
            .reverse = false,
            .groupDirectoriesFirst = filter_options.groupDirectoriesFirst,
            .items = items,
            .sort_field = filter_options.sort,
        };
        items.sort(sottContext);
    }
}

fn getItems(allocator: std.mem.Allocator, path: []const u8) !std.MultiArrayList(Item) {
    if (try isFile(allocator, path)) {
        if (fs.path.dirname(path)) |dir_name| {
            return try entryFile(allocator, dir_name, fs.path.basename(path));
        } else {
            return try entryFile(allocator, ".", fs.path.basename(path));
        }
    } else {
        var dir = try getIteratorbleDir(path);
        return try entryFiles(allocator, path, dir);
    }
}

fn isFile(allocator: std.mem.Allocator, path: []const u8) !bool {
    const relative_path = try fs.path.joinZ(allocator, &[_][]const u8{ path, "" });
    defer {
        allocator.free(relative_path);
    }
    const stat = try Stat.init(relative_path);
    return stat.kind != Kind.Directory;
}

fn getIteratorbleDir(path: []const u8) !fs.IterableDir {
    if (fs.path.isAbsolute(path)) {
        return try fs.openIterableDirAbsolute(path, .{});
    } else {
        return try fs.cwd().openIterableDir(path, .{});
    }
}

pub fn print(
    writer: anytype,
    items: std.MultiArrayList(Item),
    display_options: option.DisplayOptions,
    long_view_options: option.LongViewOptions,
    window: Window,
) !void {
    if (display_options.style == option.DisplayStyle.Oneline) {
        try oneline.print(writer, items, display_options);
        return;
    }

    if (display_options.style == option.DisplayStyle.Long) {
        try long.print(writer, items, long_view_options, display_options);
        return;
    }

    if (display_options.style == option.DisplayStyle.Csv) {
        try csv.print(writer, items, long_view_options, display_options);
        return;
    }

    if (display_options.style == option.DisplayStyle.Json or display_options.style == option.DisplayStyle.Jsonl) {
        try json.print(writer, items, long_view_options, display_options);
        return;
    }

    try grid.print(writer, items, display_options, window);
}

fn entryFiles(allocator: std.mem.Allocator, dir_name: []const u8, dir: fs.IterableDir) !std.MultiArrayList(Item) {
    var dir_iterate = dir.iterate();
    var items = std.MultiArrayList(Item){};

    while (try dir_iterate.next()) |entry| {
        if (Item.init(allocator, dir_name, entry.name, entry.kind)) |item| {
            try items.append(allocator, item);
            errdefer item.deinit();
        } else |err| {
            return err;
        }
    }

    return items;
}

fn files(allocator: std.mem.Allocator, path_list: std.ArrayList([]const u8)) !std.MultiArrayList(Item) {
    var items = std.MultiArrayList(Item){};

    for (path_list.items) |path| {
        if (Item.init(allocator, fs.path.dirname(path) orelse ".", fs.path.basename(path), Kind.Unknown)) |item| {
            try items.append(allocator, item);
        } else |err| {
            return err;
        }
    }

    return items;
}

fn groupByDir(allocator: std.mem.Allocator, path_list: std.ArrayList([]const u8)) !std.StringHashMap(std.ArrayList([]const u8)) {
    var dir_map = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);

    for (path_list.items) |path| {
        var dirName = fs.path.dirname(path) orelse ".";
        if (!dir_map.contains(dirName)) {
            try dir_map.put(dirName, std.ArrayList([]const u8).init(allocator));
        }

        if (dir_map.getPtr(dirName)) |v| {
            try v.append(path);
            try dir_map.put(dirName, v.*);
        }
    }

    return dir_map;
}

fn entryFile(allocator: std.mem.Allocator, dir_name: []const u8, file_name: []const u8) !std.MultiArrayList(Item) {
    var items = std.MultiArrayList(Item){};

    if (Item.init(allocator, dir_name, file_name, Kind.Unknown)) |item| {
        try items.append(allocator, item);
    } else |err| {
        return err;
    }

    return items;
}

fn isPatternString(pattern: []const u8) bool {
    for (pattern) |p| {
        if (p == '*') return true;
    }

    return false;
}

fn filterFiles(allocator: std.mem.Allocator, items: std.MultiArrayList(Item), filter_options: option.FiltringAndSortingOptions) !std.MultiArrayList(Item) {
    var filtered_items = std.MultiArrayList(Item){};
    var exclude_pattern = if (filter_options.exclude) |e| try Regex.compile(allocator, e) else null;
    var only_pattern = if (filter_options.only) |o| try Regex.compile(allocator, o) else null;
    defer {
        if (exclude_pattern) |*p| {
            p.deinit();
        }
        if (only_pattern) |*p| {
            p.deinit();
        }
    }

    for (items.items(.name)) |name, i| {
        if (!filter_options.all and Item.isDotFile(name)) {
            continue;
        }

        const item = items.get(i);

        if (filter_options.onlyDirs and !item.isDir()) {
            continue;
        }

        if (exclude_pattern) |*p| {
            if (try p.partialMatch(name)) {
                continue;
            }
        }

        if (only_pattern) |*p| {
            if (!(try p.partialMatch(name))) {
                continue;
            }
        }

        try filtered_items.append(allocator, items.get(i));
    }

    return filtered_items;
}

test {
    _ = @import("test.zig");
}
