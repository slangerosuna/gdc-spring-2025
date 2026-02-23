const std = @import("std");
pub const ecs = @import("engine/ecs/ecs.zig");

pub const RootPlugin = ecs.Plugin(.{
    .systems = .{},
    .statemachine = .{},
    .plugins = .{},
});

comptime {
    // this is needed to make it so that the tests in other files are visible to the test runner
    std.testing.refAllDecls(@This());
}
