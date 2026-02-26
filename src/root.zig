const std = @import("std");
pub const ecs = @import("engine/ecs/ecs.zig");
pub const math = @import("engine/math.zig");
pub const sdl = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_gpu.h");
    @cInclude("SDL3_image/SDL_image.h");
    @cDefine("SDL_MAIN_HANDLED", {});
    @cInclude("SDL3/SDL_main.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

pub const RootPlugin = ecs.Plugin(.{
    .systems = .{},
    .statemachine = .{},
    .plugins = .{},
});

comptime {
    // this is needed to make it so that the tests in other files are visible to the test runner
    std.testing.refAllDecls(@This());
}
