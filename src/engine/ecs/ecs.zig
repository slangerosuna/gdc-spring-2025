const std = @import("std");

pub const query = @import("query.zig");
pub const appbuilder = @import("appbuilder.zig");
pub const config = @import("config.zon");

const Type = std.builtin.Type;

pub const SystemStage = enum(usize) {
    Init,
    DeInit,

    PreUpdate,
    Update,
    PostUpdate,
    Render,
};

pub const App = appbuilder.build(@import("../../root.zig").RootPlugin);
pub const StateMachine = App.StateMachine;

pub fn Plugin(comptime plugin: anytype) type {
    var systems: [config.max_systems]type = undefined;
    var cur_system = 0;

    var statemachines: [config.max_statemachine]type = undefined;
    var cur_statemachine = 0;

    for (@typeInfo(@TypeOf(plugin)).@"struct".fields) |field| {
        if (std.mem.eql(u8, field.name, "systems")) {
            // TODO:
            systems[cur_system] = @TypeOf(@field(plugin, field.name));
            cur_system += 1;
            if (cur_system >= systems.len) {
                @panic("too many systems");
            }
        } else if (std.mem.eql(u8, field.name, "statemachine")) {
            // TODO:
            statemachines[cur_statemachine] = @TypeOf(@field(plugin, field.name));
            cur_statemachine += 1;
            if (cur_statemachine >= statemachines.len) {
                @panic("too many statemachines");
            }
        } else if (std.mem.eql(u8, field.name, "plugins")) {
            // TODO:
        } else {
            @panic("expected .systems, .statemachine, or .plugins");
        }
    }

    return @Type(.{ .@"struct" = .{
        .layout = .auto,
        .fields = &[4]Type.StructField{ .{
            .name = "systems",
            .type = [cur_system]type,
            .default_value_ptr = systems[0..cur_system],
            .is_comptime = true,
            .alignment = @alignOf([cur_system]type),
        }, .{
            .name = "system_count",
            .type = comptime_int,
            .default_value_ptr = &cur_system,
            .is_comptime = true,
            .alignment = @alignOf(comptime_int),
        }, .{
            .name = "statemachines",
            .type = [cur_statemachine]type,
            .default_value_ptr = statemachines[0..cur_statemachine],
            .is_comptime = true,
            .alignment = @alignOf([cur_statemachine]type),
        }, .{
            .name = "statemachine_count",
            .type = comptime_int,
            .default_value_ptr = &cur_statemachine,
            .is_comptime = true,
            .alignment = @alignOf(comptime_int),
        } },
        .decls = &[0]Type.Declaration{},
        .is_tuple = false,
    } });
}

comptime {
    std.testing.refAllDecls(@This());
}
