const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // Look at b.option() custom flags (might be useful for env build)

    // --------------------
    // Asset gen
    // --------------------

    const asset_gen_exe = b.addExecutable(.{
        .name = "asset_gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/asset_gen.zig"),
            .target = b.graph.host,
        }),
    });

    const asset_gen_run = b.addRunArtifact(asset_gen_exe);
    const generated_asset_file = asset_gen_run.addOutputFileArg("assets_generated.zig");
    const assets_gen_mod = b.createModule(.{
        .root_source_file = generated_asset_file,
    });
    // TODO: - Make it dynamic using options
    asset_gen_run.addArg("frontend/dist");

    const mod = b.addModule("zystal", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "zystal",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zystal", .module = mod },
                .{ .name = "assets_gen", .module = assets_gen_mod },
            },
        }),
    });
    //
    const webview = b.dependency("webview", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("webview", webview.module("webview"));
    exe.root_module.linkLibrary(webview.artifact("webviewStatic"));

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
