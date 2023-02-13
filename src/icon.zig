const std = @import("std");

const Item = @import("models/item.zig").Item;
const Kind = @import("models/item.zig").Kind;
const options = @import("./option.zig");

const expect = std.testing.expect;

pub const Icon = struct {
    pub const none = "";

    pub fn detect(item: Item, display_options: options.DisplayOptions) []const u8 {
        if (display_options.icons == options.IconStyle.Nerd) {
            return NerdIcon.detect(item);
        } else if (display_options.icons == options.IconStyle.Unicode) {
            return UnicodeIcon.detect(item);
        } else {
            return "";
        }
    }
};

const UnicodeIcon = struct {
    pub const folder = "\u{1F4C1} ";
    pub const link = "\u{1F517} ";
    pub const device = "\u{1F4BD} ";

    pub fn detect(item: Item) []const u8 {
        if (item.kind == Kind.Directory) {
            return folder;
        }

        if (item.kind == Kind.SymLink) {
            return link;
        }

        if (item.kind == Kind.CharacterDevice or item.kind == Kind.BlockDevice) {
            return device;
        }

        return "";
    }
};

const NerdIcon = struct {
    pub const folder = "\u{F115} ";

    const file = "\u{F15B} ";
    const device = "\u{F0A0} ";
    const git = "\u{E702} ";
    const env = "\u{EB99} ";

    const java = "\u{E738} ";
    const python = "\u{E73C} ";
    const golang = "\u{E626} ";
    const rust = "\u{E7A8} ";
    const swift = "\u{E755} ";
    const dotnet = "\u{E77F} ";
    const cs = "\u{F81A} ";
    const fs = "\u{E7A7} ";
    const scala = "\u{e737} ";
    const ruby = "\u{F219} ";
    const julia = "\u{E624} ";
    const haskell = "\u{E61F} ";
    const php = "\u{E608} ";
    const elixir = "\u{E62D} ";
    const erlang = "\u{E7B1} ";
    const javascript = "\u{E74E} ";
    const typescript = "\u{FBE4} ";
    const perl = "\u{FBE4} ";
    const css = "\u{E749} ";
    const markdown = "\u{E73E} ";
    const sass = "\u{E74B} ";
    const json = "\u{E60B} ";
    const lua = "\u{E620} ";
    const html = "\u{E60E} ";
    const link = "\u{F836} ";
    const clojure = "\u{E768} ";
    const dart = "\u{E798} ";
    const react = "\u{E7BA} ";
    const vue = "\u{E6A0} ";
    const svg = "\u{E698} ";
    const elm = "\u{E62C} ";
    const gradle = "\u{E660} ";
    const crystal = "\u{e62f} ";
    const nim = "\u{E677} ";
    const pdf = "\u{E67D} ";
    const sbt = "\u{E68D} ";
    const svelte = "\u{E697} ";
    const zig = "\u{E6A9} ";
    const yaml = "\u{E6A8} ";
    const xml = "\u{E619} ";
    const wat = "\u{E6A2} ";
    const zip = "\u{E6AA} ";
    const lock = "\u{EB99} ";
    const makefile = "\u{EB99} ";

    const vimrc = "\u{E62B} ";
    const envrc = "\u{25BC} ";
    const docker = "\u{F308} ";
    const editorconfig = "\u{E652} ";
    const webpack = "\u{E6A3} ";
    const firebase = "\u{E657} ";
    const tsconfig = "\u{E69D} ";
    const home = "\u{F015} ";
    const download = "\u{F019} ";
    const desktop = "\u{F108} ";
    const licence = "\u{E78B} ";
    const apple = "\u{EB99} ";
    const settings = "\u{EB99} ";

    const KV = struct {
        @"0": []const u8,
        @"1": []const u8,
    };

    const extMap = std.ComptimeStringMap([]const u8, [_]KV{
        .{ .@"0" = ".rs", .@"1" = rust },
        .{ .@"0" = ".scala", .@"1" = scala },
        .{ .@"0" = ".dart", .@"1" = dart },
        .{ .@"0" = ".clj", .@"1" = clojure },
        .{ .@"0" = ".php", .@"1" = php },
        .{ .@"0" = ".java", .@"1" = java },
        .{ .@"0" = ".py", .@"1" = python },
        .{ .@"0" = ".js", .@"1" = javascript },
        .{ .@"0" = ".ts", .@"1" = typescript },
        .{ .@"0" = ".go", .@"1" = golang },
        .{ .@"0" = ".css", .@"1" = css },
        .{ .@"0" = ".md", .@"1" = markdown },
        .{ .@"0" = ".scss", .@"1" = sass },
        .{ .@"0" = ".sass", .@"1" = sass },
        .{ .@"0" = ".json", .@"1" = json },
        .{ .@"0" = ".lua", .@"1" = lua },
        .{ .@"0" = ".julia", .@"1" = julia },
        .{ .@"0" = ".hs", .@"1" = haskell },
        .{ .@"0" = ".rb", .@"1" = ruby },
        .{ .@"0" = ".swift", .@"1" = swift },
        .{ .@"0" = ".ex", .@"1" = elixir },
        .{ .@"0" = ".exs", .@"1" = elixir },
        .{ .@"0" = ".erl", .@"1" = erlang },
        .{ .@"0" = ".cs", .@"1" = cs },
        .{ .@"0" = ".fs", .@"1" = fs },
        .{ .@"0" = ".fsi", .@"1" = fs },
        .{ .@"0" = ".fsi", .@"1" = fs },
        .{ .@"0" = ".vue", .@"1" = vue },
        .{ .@"0" = ".svg", .@"1" = svg },
        .{ .@"0" = ".elm", .@"1" = elm },
        .{ .@"0" = ".gradle", .@"1" = gradle },
        .{ .@"0" = ".cr", .@"1" = crystal },
        .{ .@"0" = ".nim", .@"1" = nim },
        .{ .@"0" = ".pdf", .@"1" = pdf },
        .{ .@"0" = ".sbt", .@"1" = sbt },
        .{ .@"0" = ".svelte", .@"1" = svelte },
        .{ .@"0" = ".zig", .@"1" = zig },
        .{ .@"0" = ".xml", .@"1" = xml },
        .{ .@"0" = ".wat", .@"1" = wat },
        .{ .@"0" = ".zig", .@"1" = zig },
        .{ .@"0" = ".zip", .@"1" = zip },
        .{ .@"0" = ".lock", .@"1" = lock },
        .{ .@"0" = ".mk", .@"1" = makefile },
        // yaml
        .{ .@"0" = ".yaml", .@"1" = yaml },
        .{ .@"0" = ".yml", .@"1" = yaml },
        // html
        .{ .@"0" = ".htm", .@"1" = html },
        .{ .@"0" = ".html", .@"1" = html },
        // react
        .{ .@"0" = ".tsx", .@"1" = react },
        .{ .@"0" = ".jsx", .@"1" = react },
        // settings
        .{ .@"0" = ".ini", .@"1" = settings },
        .{ .@"0" = ".toml", .@"1" = settings },
    });

    const fileMap = std.ComptimeStringMap([]const u8, [_]KV{
        .{ .@"0" = ".vimrc", .@"1" = vimrc },
        .{ .@"0" = ".envrc", .@"1" = envrc },
        .{ .@"0" = "Dockerfile", .@"1" = docker },
        .{ .@"0" = ".editorconfig", .@"1" = editorconfig },
        .{ .@"0" = "tsconfig.json", .@"1" = tsconfig },
        .{ .@"0" = "LICENSE", .@"1" = licence },
        // git
        .{ .@"0" = ".gitignore", .@"1" = git },
        .{ .@"0" = ".gitconfig", .@"1" = git },
        .{ .@"0" = ".git", .@"1" = git },
        // webpack
        .{ .@"0" = "webpack.config.js", .@"1" = webpack },
        .{ .@"0" = "webpack.config.ts", .@"1" = webpack },
        // firebase
        .{ .@"0" = "firebase.json", .@"1" = firebase },
        .{ .@"0" = ".firebaserc", .@"1" = firebase },
        .{ .@"0" = "firestore.indexes.json", .@"1" = firebase },
        // directory
        .{ .@"0" = "home", .@"1" = home },
        .{ .@"0" = "Downloads", .@"1" = download },
        .{ .@"0" = "Desktop", .@"1" = desktop },
        // env
        .{ .@"0" = ".env", .@"1" = env },
        .{ .@"0" = ".envrc", .@"1" = env },
        // apple
        .{ .@"0" = ".DS_Store", .@"1" = apple },
        // Makefile
        .{ .@"0" = "Makefile", .@"1" = makefile },
        .{ .@"0" = "justfile", .@"1" = makefile },
        .{ .@"0" = "Justfile", .@"1" = makefile },
    });

    pub fn detect(item: Item) []const u8 {
        const ext = std.fs.path.extension(item.path);
        const baseName = std.fs.path.basename(item.path);

        if (item.kind == Kind.Directory) {
            return folder;
        }

        if (item.kind == Kind.SymLink) {
            return link;
        }

        if (item.kind == Kind.CharacterDevice or item.kind == Kind.BlockDevice) {
            return device;
        }

        if (extMap.has(ext)) {
            return extMap.get(ext).?;
        }

        if (fileMap.has(baseName)) {
            return fileMap.get(baseName).?;
        }

        return file;
    }
};
