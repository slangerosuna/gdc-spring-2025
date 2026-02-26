const std = @import("std");
pub const ecs = @import("engine/ecs/ecs.zig");
pub const math = @import("engine/math.zig");
pub const geometry = @import("engine/geometry/mod.zig");
pub const material = @import("engine/material/mod.zig");
pub const TimeSystem = @import("engine/systems/time.zig").TimeSystem;
pub const Time = @import("engine/systems/time.zig").Time;
pub const InputSystem = @import("engine/systems/input.zig").InputSystem;
pub const Input = @import("engine/systems/input.zig").Input;
pub const RenderSystem = @import("engine/systems/render.zig").RenderSystem;
pub const RenderTarget = @import("engine/systems/render.zig").RenderTarget;
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
