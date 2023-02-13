const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const file_name = b.option([]const u8, "output", "Output file name");
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable(file_name orelse "els", "src/main.zig");
    exe.addPackagePath("clap", "libs/zig-clap/clap.zig");
    exe.addPackagePath("datetime", "libs/zig-datetime/src/main.zig");
    exe.addPackagePath("zig-string", "libs/zig-string/zig-string.zig");
    exe.addPackagePath("regex", "libs/zig-regex/src/regex.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.addPackagePath("clap", "libs/zig-clap/clap.zig");
    exe_tests.addPackagePath("datetime", "libs/zig-datetime/src/main.zig");
    exe_tests.addPackagePath("zig-string", "libs/zig-string/zig-string.zig");
    exe_tests.addPackagePath("regex", "libs/zig-regex/src/regex.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);
    exe_tests.linkLibC();

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
