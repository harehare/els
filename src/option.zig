const std = @import("std");
const process = std.process;
const Regex = @import("regex").Regex;

const Item = @import("./models/item.zig").Item;

pub const OptionError = error{
    InvalidSortField,
    InvalidTimeStyle,
    InvalidColor,
    InvalidIcons,
};

pub const FiltringAndSortingOptions = struct {
    all: bool,
    reverse: bool,
    onlyDirs: bool,
    sort: Item.Field,
    level: usize,
    groupDirectoriesFirst: bool,
    exclude: ?[]const u8,
    only: ?[]const u8,

    pub fn default() FiltringAndSortingOptions {
        return FiltringAndSortingOptions{
            .all = false,
            .reverse = false,
            .onlyDirs = false,
            .sort = Item.Field.Kind,
            .level = 128,
            .groupDirectoriesFirst = false,
            .exclude = null,
            .only = null,
        };
    }

    pub fn fromEnv(envMap: process.EnvMap) FiltringAndSortingOptions {
        const allValue = envMap.get("ELS_FILTRING_AND_SORTING_ALL") orelse "false";
        const reverseValue = envMap.get("ELS_FILTRING_AND_SORTING_REVERSE") orelse "false";
        const onlyDirsValue = envMap.get("ELS_FILTRING_AND_SORTING_ONLY_DIRS") orelse "false";
        const sortValue = envMap.get("ELS_FILTRING_AND_SORTING_SORT") orelse "kind";
        const levelValue = envMap.get("ELS_FILTRING_AND_SORTING_LEVEL") orelse "128";
        const groupDirectoriesFirstValue = envMap.get("ELS_GROUP_DIRECTORIES_FIRST") orelse "false";
        const excludeValue = envMap.get("ELS_FILTRING_AND_SORTING_EXCLUDE") orelse null;
        const onlyValue = envMap.get("ELS_FILTRING_AND_SORTING_ONLY") orelse null;

        var options = default();

        options.all = std.mem.eql(u8, allValue, "true");
        options.onlyDirs = std.mem.eql(u8, onlyDirsValue, "true");
        options.reverse = std.mem.eql(u8, reverseValue, "true");
        options.sort = Item.Field.fromString(sortValue);
        options.level = std.fmt.parseInt(usize, levelValue, 10) catch 128;
        options.groupDirectoriesFirst = std.mem.eql(u8, groupDirectoriesFirstValue, "true");
        options.exclude = excludeValue;
        options.only = onlyValue;

        return options;
    }

    pub fn updateFromArgs(self: @This(), args: anytype) OptionError!FiltringAndSortingOptions {
        var sort: Item.Field = Item.Field.Kind;
        var exclude: ?[]const u8 = null;
        var only: ?[]const u8 = null;

        if (@field(args, "sort")) |s| {
            sort = Item.Field.fromString(s);

            if (sort == Item.Field.None) {
                return error.InvalidSortField;
            }
        }

        if (@field(args, "exclude")) |e| {
            exclude = e;
        }

        if (@field(args, "only")) |o| {
            only = o;
        }

        return FiltringAndSortingOptions{
            .all = if (@field(args, "all")) true else self.all,
            .reverse = if (@field(args, "reverse")) true else self.reverse,
            .onlyDirs = if (@field(args, "only-dirs")) true else self.onlyDirs,
            .sort = if (sort != Item.Field.Kind) sort else self.sort,
            .level = @field(args, "level") orelse self.level,
            .groupDirectoriesFirst = if (@field(args, "group-directories-first")) true else self.groupDirectoriesFirst,
            .exclude = exclude orelse self.exclude,
            .only = only orelse self.only,
        };
    }
};

pub const Color = enum {
    Always,
    Never,
    None,

    const Self = @This();

    pub fn isAlways(self: Self) bool {
        return self == Self.Always;
    }

    pub fn fromString(s: []const u8) Self {
        if (std.mem.eql(u8, s, "always")) {
            return Self.Always;
        } else if (std.mem.eql(u8, s, "never")) {
            return Self.Never;
        } else {
            return Self.None;
        }
    }

    pub fn choice() []const u8 {
        return "nerd, unicode";
    }
};

pub const IconStyle = enum {
    Nerd,
    Unicode,
    None,

    const Self = @This();

    pub fn fromString(s: []const u8) IconStyle {
        if (std.mem.eql(u8, s, "nerd")) {
            return Self.Nerd;
        } else if (std.mem.eql(u8, s, "unicode")) {
            return Self.Unicode;
        } else {
            return Self.None;
        }
    }

    pub fn choice() []const u8 {
        return "nerd, unicode";
    }
};

pub const DisplayStyle = enum {
    Grid,
    Oneline,
    Long,
    Classify,
    Csv,
    Json,
    Jsonl,
};

pub const DisplayOptions = struct {
    style: DisplayStyle,
    recurse: bool,
    icons: IconStyle,
    path: bool,
    color: Color,

    pub fn default() DisplayOptions {
        return DisplayOptions{
            .style = DisplayStyle.Grid,
            .recurse = false,
            .icons = IconStyle.None,
            .path = false,
            .color = Color.Always,
        };
    }

    pub fn fromEnv(envMap: process.EnvMap) DisplayOptions {
        const gridValue = envMap.get("ELS_DISPLAY_GRID") orelse "true";
        const onelineValue = envMap.get("ELS_DISPLAY_ONELINE") orelse "false";
        const longValue = envMap.get("ELS_DISPLAY_LONG") orelse "false";
        const csvValue = envMap.get("ELS_DISPLAY_CSV") orelse "false";
        const classifyValue = envMap.get("ELS_DISPLAY_CLASSIFY") orelse "false";
        const jsonValue = envMap.get("ELS_DISPLAY_JSON") orelse "false";
        const jsonlValue = envMap.get("ELS_DISPLAY_JSONL") orelse "false";
        const recurseValue = envMap.get("ELS_DISPLAY_RECURSE") orelse "false";
        const iconsValue = envMap.get("ELS_DISPLAY_ICONS") orelse "none";
        const pathValue = envMap.get("ELS_DISPLAY_PATH") orelse "false";
        const colorStyleValue = envMap.get("ELS_DISPLAY_COLOR_STYLE") orelse "always";

        var options = default();

        options.style = if (std.mem.eql(u8, gridValue, "true")) DisplayStyle.Grid else if (std.mem.eql(u8, onelineValue, "true"))
            DisplayStyle.Oneline
        else if (std.mem.eql(u8, longValue, "true"))
            DisplayStyle.Long
        else if (std.mem.eql(u8, classifyValue, "true"))
            DisplayStyle.Classify
        else if (std.mem.eql(u8, csvValue, "true"))
            DisplayStyle.Csv
        else if (std.mem.eql(u8, jsonValue, "true"))
            DisplayStyle.Json
        else if (std.mem.eql(u8, jsonlValue, "true"))
            DisplayStyle.Jsonl
        else
            DisplayStyle.Grid;

        options.recurse = std.mem.eql(u8, recurseValue, "true");
        options.path = std.mem.eql(u8, pathValue, "true");

        const enabledColor = options.style != DisplayStyle.Json and options.style != DisplayStyle.Jsonl and options.style != DisplayStyle.Csv;

        if (!std.mem.eql(u8, colorStyleValue, "always") and enabledColor) {
            options.color = Color.fromString(colorStyleValue);
        } else {
            options.color = Color.Never;
        }

        if (!std.mem.eql(u8, iconsValue, "none")) {
            options.icons = IconStyle.fromString(iconsValue);
        }

        return options;
    }

    pub fn updateFromArgs(self: @This(), args: anytype) OptionError!DisplayOptions {
        var icons: IconStyle = IconStyle.None;
        var color: Color = Color.Always;

        if (@field(args, "icons")) |i| {
            icons = IconStyle.fromString(i);

            if (icons == IconStyle.None) {
                return error.InvalidIcons;
            }
        }

        if (@field(args, "color")) |c| {
            color = Color.fromString(c);

            if (color == Color.None) {
                return error.InvalidColor;
            }
        }

        const style = if (@field(args, "grid"))
            DisplayStyle.Grid
        else if (@field(args, "oneline"))
            DisplayStyle.Oneline
        else if (@field(args, "long"))
            DisplayStyle.Long
        else if (@field(args, "classify"))
            DisplayStyle.Classify
        else if (@field(args, "csv"))
            DisplayStyle.Csv
        else if (@field(args, "json"))
            DisplayStyle.Json
        else if (@field(args, "jsonl"))
            DisplayStyle.Jsonl
        else
            DisplayStyle.Grid;

        const enabledColor = style != DisplayStyle.Json and style != DisplayStyle.Jsonl and style != DisplayStyle.Csv;

        return DisplayOptions{
            .style = style,
            .recurse = if (@field(args, "recurse")) true else self.recurse,
            .icons = if (icons != IconStyle.None) icons else self.icons,
            .path = if (@field(args, "path")) true else self.path,
            .color = if (color != Color.Always or enabledColor) color else self.color,
        };
    }
};

pub const TimeStyle = enum {
    Default,
    Iso,
    LongIso,
    Timestamp,
    None,

    const Self = @This();

    pub fn fromString(s: []const u8) TimeStyle {
        if (std.mem.eql(u8, s, "default")) {
            return Self.Default;
        } else if (std.mem.eql(u8, s, "iso")) {
            return Self.Iso;
        } else if (std.mem.eql(u8, s, "long-iso")) {
            return Self.LongIso;
        } else if (std.mem.eql(u8, s, "timestamp")) {
            return Self.Timestamp;
        } else {
            return Self.None;
        }
    }

    pub fn choice() []const u8 {
        return "default, iso, long-iso, timestamp";
    }
};

pub const LongViewOptions = struct {
    inode: bool,
    group: bool,
    created: bool,
    accessed: bool,
    modified: bool,
    header: bool,
    noFileSize: bool,
    noTime: bool,
    noUser: bool,
    noPermissions: bool,
    timeStyle: TimeStyle,
    bytes: bool,
    octalPermissions: bool,
    blocks: bool,
    numeric: bool,
    links: bool,
    noDirName: bool,
    allFields: bool,

    pub fn default() LongViewOptions {
        return LongViewOptions{
            .inode = false,
            .group = false,
            .created = false,
            .accessed = false,
            .modified = false,
            .header = false,
            .noFileSize = false,
            .noUser = false,
            .noTime = false,
            .noPermissions = false,
            .timeStyle = TimeStyle.Default,
            .bytes = false,
            .octalPermissions = false,
            .blocks = false,
            .numeric = false,
            .links = false,
            .noDirName = false,
            .allFields = false,
        };
    }

    pub fn fromEnv(envMap: process.EnvMap) LongViewOptions {
        const inodeValue = envMap.get("ELS_LONG_VIEW_INODE") orelse "false";
        const groupValue = envMap.get("ELS_LONG_VIEW_GROUP") orelse "false";
        const createdValue = envMap.get("ELS_LONG_VIEW_CREATED") orelse "false";
        const accessedValue = envMap.get("ELS_LONG_VIEW_ACCESSED") orelse "false";
        const modifiedValue = envMap.get("ELS_LONG_VIEW_MODIFIED") orelse "false";
        const headerValue = envMap.get("ELS_LONG_VIEW_HEADER") orelse "false";
        const noFileSizeValue = envMap.get("ELS_LONG_VIEW_NO_FILE_SIZE") orelse "false";
        const noUserValue = envMap.get("ELS_LONG_VIEW_NO_USER") orelse "false";
        const noTimeValue = envMap.get("ELS_LONG_VIEW_NO_TIME") orelse "false";
        const noPermissionsValue = envMap.get("ELS_LONG_VIEW_NO_PERMISSIONS") orelse "false";
        const timeStyleValue = envMap.get("ELS_LONG_VIEW_TIME_STYLE") orelse "default";
        const bytesValue = envMap.get("ELS_LONG_VIEW_BYTES") orelse "false";
        const octalPermissionsValue = envMap.get("ELS_LONG_VIEW_OCTAL_PERMISSIONS") orelse "false";
        const blocksValue = envMap.get("ELS_LONG_VIEW_BLOCKS") orelse "false";
        const numericValue = envMap.get("ELS_LONG_VIEW_NUMERIC") orelse "false";
        const linksValue = envMap.get("ELS_LONG_VIEW_LINKS") orelse "false";
        const noDirNameValue = envMap.get("ELS_LONG_VIEW_NO_DIR_NAME") orelse "false";
        const allFieldsValue = envMap.get("ELS_LONG_VIEW_ALL_FIELDS") orelse "false";

        var options = default();

        options.inode = std.mem.eql(u8, inodeValue, "true");
        options.group = std.mem.eql(u8, groupValue, "true");
        options.created = std.mem.eql(u8, createdValue, "true");
        options.accessed = std.mem.eql(u8, accessedValue, "true");
        options.modified = std.mem.eql(u8, modifiedValue, "true");
        options.header = std.mem.eql(u8, headerValue, "true");
        options.noFileSize = std.mem.eql(u8, noFileSizeValue, "true");
        options.noUser = std.mem.eql(u8, noUserValue, "true");
        options.noTime = std.mem.eql(u8, noTimeValue, "true");
        options.noPermissions = std.mem.eql(u8, noPermissionsValue, "true");
        options.bytes = std.mem.eql(u8, bytesValue, "true");
        options.octalPermissions = std.mem.eql(u8, octalPermissionsValue, "true");
        options.blocks = std.mem.eql(u8, blocksValue, "true");
        options.numeric = std.mem.eql(u8, numericValue, "true");
        options.links = std.mem.eql(u8, linksValue, "true");
        options.noDirName = std.mem.eql(u8, noDirNameValue, "true");
        options.allFields = std.mem.eql(u8, allFieldsValue, "true");

        if (!std.mem.eql(u8, timeStyleValue, "defult")) {
            options.timeStyle = TimeStyle.fromString(timeStyleValue);
        }

        return options;
    }

    pub fn updateFromArgs(self: @This(), args: anytype) OptionError!LongViewOptions {
        var time_style: TimeStyle = TimeStyle.Default;

        if (@field(args, "time-style")) |t| {
            time_style = TimeStyle.fromString(t);

            if (time_style == TimeStyle.None) {
                return error.InvalidTimeStyle;
            }
        }

        return LongViewOptions{
            .inode = if (@field(args, "inode")) true else self.inode,
            .group = if (@field(args, "group")) true else self.group,
            .created = if (@field(args, "created")) true else self.created,
            .accessed = if (@field(args, "accessed")) true else self.accessed,
            .modified = if (@field(args, "modified")) true else self.modified,
            .header = if (@field(args, "header")) true else self.header,
            .noFileSize = if (@field(args, "no-filesize")) true else self.noFileSize,
            .noUser = if (@field(args, "no-user")) true else self.noUser,
            .noTime = if (@field(args, "no-time")) true else self.noTime,
            .noPermissions = if (@field(args, "no-permissions")) true else self.noPermissions,
            .timeStyle = if (time_style != TimeStyle.Default) time_style else self.timeStyle,
            .bytes = if (@field(args, "bytes")) true else self.bytes,
            .octalPermissions = if (@field(args, "octal-permissions")) true else self.octalPermissions,
            .blocks = if (@field(args, "blocks")) true else self.blocks,
            .numeric = if (@field(args, "numeric")) true else self.numeric,
            .links = if (@field(args, "links")) true else self.links,
            .noDirName = if (@field(args, "no-dir-name")) true else self.noDirName,
            .allFields = if (@field(args, "all-fields")) true else self.allFields,
        };
    }
};
