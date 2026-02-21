const std = @import("std");

pub const SourceType = enum {
    built_assets,
    dev_server,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ----------------------------------------------------------------------------------------------
    // Options setup
    const options = b.addOptions();
    // Source-Type
    const source_type_option = b.option(
        SourceType,
        "source_type",
        "Determines the type of frontend source (BuiltAssets | DevServer)",
    ) orelse .built_assets;

    options.addOption(
        SourceType,
        "source_type",
        source_type_option,
    );
    // Frontend built assets folder
    const frontend_assets_path = b.option(
        []const u8,
        "assets_path",
        "Relative path to frontend built assets (optional if source_type is dev_server)",
    );
    options.addOption(?[]const u8, "assets_path", frontend_assets_path);

    // Options validation
    if (source_type_option == .built_assets and frontend_assets_path == null) {
        std.debug.panic("You should add -assets_path option for when -source_type=built_assets\n", .{});
    } else if (source_type_option == .dev_server and frontend_assets_path != null) {
        std.debug.print("-assets_path would be ignored when -source_type=dev_server set\n", .{});
    }

    // ----------------------------------------------------------------------------------------------
    // Asset gen
    // I think we should skip this part of assets gen if source_type is DevServer
    // I could also inject SourceType option in asset_gen to skip it, or it's better to pass more explicit option
    // like "skip_gen" or entirely exclude this step during build time
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

    // ----------------------------------------------------------------------------------------------
    // RootModule/Exe
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
    exe.root_module.addOptions("build_options", options);

    // ----------------------------------------------------------------------------------------------
    // Dependencies
    // - WebView -
    const webview = b.dependency("webview", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("webview", webview.module("webview"));
    exe.root_module.linkLibrary(webview.artifact("webviewStatic"));

    // ----------------------------------------------------------------------------------------------
    // CMD's
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // ----------------------------------------------------------------------------------------------
    // Tests
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
