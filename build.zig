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
    const source_type_option = b.option(
        SourceType,
        "source_type",
        "Determines the type of frontend source (built_assets | dev_server)",
    ) orelse .dev_server;

    options.addOption(SourceType, "source_type", source_type_option);

    const frontend_assets_path = b.option(
        []const u8,
        "assets_path",
        "Relative path to frontend built assets (optional if source_type is dev_server)",
    );
    options.addOption(?[]const u8, "assets_path", frontend_assets_path);

    if (source_type_option == .dev_server and frontend_assets_path != null) {
        std.debug.print("-assets_path is ignored when -source_type=dev_server is set\n", .{});
    }

    // ----------------------------------------------------------------------------------------------
    // Root module
    const zystal_mod = b.addModule("zystal", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    zystal_mod.addOptions("build_options", options);

    // ----------------------------------------------------------------------------------------------
    // Asset module
    const assets_gen_mod = blk: {
        if (source_type_option == .built_assets) {
            if (frontend_assets_path) |path| {
                break :blk makeAssetGenModule(b, path);
            }
            std.debug.panic("You should add -assets_path option for when -source_type=built_assets\n", .{});
        }
        break :blk makeEmptyAssetsModule(b);
    };
    zystal_mod.addImport("assets_gen", assets_gen_mod);

    // ----------------------------------------------------------------------------------------------
    // Dependencies
    const webview = b.dependency("webview", .{
        .target = target,
        .optimize = optimize,
    });
    zystal_mod.addImport("webview", webview.module("webview"));

    // ----------------------------------------------------------------------------------------------
    // Library artifact
    const static_lib = b.addLibrary(.{
        .linkage = .static,
        .name = "zystal",
        .root_module = zystal_mod,
    });
    static_lib.root_module.linkLibrary(webview.artifact("webviewStatic"));
    b.installArtifact(static_lib);

    // ----------------------------------------------------------------------------------------------
    // Tests
    const mod_tests = b.addTest(.{
        .root_module = zystal_mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}

fn makeAssetGenModule(b: *std.Build, frontend_assets_path: []const u8) *std.Build.Module {
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

    asset_gen_run.addArg(frontend_assets_path);

    return assets_gen_mod;
}

fn makeEmptyAssetsModule(b: *std.Build) *std.Build.Module {
    const generated = b.addWriteFiles().add("assets_generated.zig",
        \\pub const AssetFile = struct {
        \\    path: []const u8,
        \\    data: []const u8,
        \\};
        \\pub const asset_files = [_]AssetFile{};
    );

    return b.createModule(.{
        .root_source_file = generated,
    });
}
