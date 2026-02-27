const std = @import("std");

pub const query = @import("query.zig");
pub const appbuilder = @import("appbuilder.zig");
pub const config = @import("config.zon");
pub const pool = @import("pool.zig");
pub const world = @import("world.zig");
pub const resource = @import("resource.zig");
pub const scheduler = @import("scheduler.zig");

pub const Entity = pool.Entity;
pub const invalid_entity = pool.invalid_entity;
pub const Pool = pool.Pool;
pub const World = world.World;
pub const Resources = resource.Resources;
pub const Scheduler = scheduler.Scheduler;
pub const SystemStage = scheduler.SystemStage;

const Type = std.builtin.Type;

pub const App = appbuilder.build(@import("../../root.zig").RootPlugin);
pub const StateMachine = App.StateMachine;

pub fn Plugin(comptime plugin: anytype) type {
    comptime var system_count: usize = 0;

    const systems_type = @TypeOf(@field(plugin, "systems"));
    if (@typeInfo(systems_type) == .@"struct") {
        system_count = @typeInfo(systems_type).@"struct".fields.len;
    }

    comptime var systems: [system_count]type = undefined;
    comptime var sys_idx: usize = 0;

    const systems_value = @field(plugin, "systems");
    inline for (@typeInfo(systems_type).@"struct".fields) |sys_field| {
        systems[sys_idx] = @field(systems_value, sys_field.name);
        sys_idx += 1;
    }

    return struct {
        pub const Systems = systems;
        pub const system_count_val = system_count;
    };
}

comptime {
    std.testing.refAllDecls(@This());
}
