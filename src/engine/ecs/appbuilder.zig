const std = @import("std");
const query = @import("query.zig");

const TypeId = query.TypeId;
const QueryInfo = query.QueryInfo;

const config = @import("config.zon");

pub fn build(comptime root_plugin: anytype) type {
    _ = root_plugin;

    return struct {
        pub const StateMachine = struct {};
        pub fn run() void {}
    };
}
