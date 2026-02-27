const std = @import("std");
const pool_mod = @import("pool.zig");
const Pool = pool_mod.Pool;
const Entity = pool_mod.Entity;
const invalid_entity = pool_mod.invalid_entity;

fn canHaveDecls(comptime T: type) bool {
    const info = @typeInfo(T);
    return info == .@"struct";
}

pub fn World(comptime Components: type) type {
    const component_fields = @typeInfo(Components).@"struct".fields;

    comptime var pool_fields: [component_fields.len]std.builtin.Type.StructField = undefined;
    inline for (component_fields, 0..) |field, i| {
        const PoolType = Pool(field.type);
        pool_fields[i] = .{
            .name = field.name ++ "_pool",
            .type = PoolType,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(PoolType),
        };
    }

    const Pools = @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .fields = &pool_fields,
            .decls = &.{},
            .is_tuple = false,
        },
    });

    return struct {
        const Self = @This();
        const CompFields = component_fields;

        pools: Pools,
        next_entity: Entity,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            var self: Self = .{
                .pools = undefined,
                .next_entity = 0,
                .allocator = allocator,
            };

            inline for (component_fields) |field| {
                const pool_name = field.name ++ "_pool";
                const PoolType = Pool(field.type);
                @field(self.pools, pool_name) = PoolType.init(allocator);
            }

            return self;
        }

        pub fn deinit(self: *Self) void {
            inline for (component_fields) |field| {
                const pool_name = field.name ++ "_pool";
                @field(self.pools, pool_name).deinit();
            }
        }

        pub fn createEntity(self: *Self) Entity {
            defer self.next_entity += 1;
            return self.next_entity;
        }

        pub fn destroyEntity(self: *Self, entity: Entity, ctx: ?*anyopaque) void {
            inline for (component_fields) |field| {
                const comp_name = field.name;
                const CompType = field.type;
                if (self.has(comp_name, entity)) {
                    if (comptime canHaveDecls(CompType)) {
                        if (@hasDecl(CompType, "onRemove")) {
                            CompType.onRemove(entity, self, ctx);
                        }
                    }
                    const pool_name = comp_name ++ "_pool";
                    @field(self.pools, pool_name).remove(entity) catch {};
                }
            }
        }

        pub fn add(
            self: *Self,
            comptime component_name: []const u8,
            entity: Entity,
            component: @FieldType(Components, component_name),
            ctx: ?*anyopaque,
        ) !void {
            const pool_name = component_name ++ "_pool";
            try @field(self.pools, pool_name).add(entity, component);

            const CompType = @FieldType(Components, component_name);
            if (comptime canHaveDecls(CompType)) {
                if (@hasDecl(CompType, "onAdd")) {
                    CompType.onAdd(entity, &component, self, ctx);
                }
            }
        }

        pub fn set(
            self: *Self,
            comptime component_name: []const u8,
            entity: Entity,
            component: @FieldType(Components, component_name),
        ) !void {
            const pool_name = component_name ++ "_pool";
            try @field(self.pools, pool_name).add(entity, component);
        }

        pub fn get(
            self: *Self,
            comptime component_name: []const u8,
            entity: Entity,
        ) ?*@FieldType(Components, component_name) {
            const pool_name = component_name ++ "_pool";
            return @field(self.pools, pool_name).getMut(entity);
        }

        pub fn getConst(
            self: *const Self,
            comptime component_name: []const u8,
            entity: Entity,
        ) ?*const @FieldType(Components, component_name) {
            const pool_name = component_name ++ "_pool";
            return @field(self.pools, pool_name).get(entity);
        }

        pub fn has(
            self: *const Self,
            comptime component_name: []const u8,
            entity: Entity,
        ) bool {
            if (!@hasField(Components, component_name)) {
                return false;
            }
            const pool_name = component_name ++ "_pool";
            return @field(self.pools, pool_name).has(entity);
        }

        pub fn remove(
            self: *Self,
            comptime component_name: []const u8,
            entity: Entity,
            ctx: ?*anyopaque,
        ) !void {
            const CompType = @FieldType(Components, component_name);
            if (comptime canHaveDecls(CompType)) {
                if (@hasDecl(CompType, "onRemove")) {
                    CompType.onRemove(entity, self, ctx);
                }
            }

            const pool_name = component_name ++ "_pool";
            try @field(self.pools, pool_name).remove(entity);
        }

        pub fn iter(
            self: *const Self,
            comptime component_name: []const u8,
        ) pool_mod.Iter(@FieldType(Components, component_name)) {
            const pool_name = component_name ++ "_pool";
            return @field(self.pools, pool_name).iter();
        }

        pub fn count(
            self: *const Self,
            comptime component_name: []const u8,
        ) u32 {
            const pool_name = component_name ++ "_pool";
            return @field(self.pools, pool_name).len();
        }

        pub fn entityCount(self: *const Self) u32 {
            return self.next_entity;
        }

        pub fn getPool(
            self: *Self,
            comptime component_name: []const u8,
        ) *Pool(@FieldType(Components, component_name)) {
            const pool_name = component_name ++ "_pool";
            return &@field(self.pools, pool_name);
        }

        pub fn getPoolConst(
            self: *const Self,
            comptime component_name: []const u8,
        ) *const Pool(@FieldType(Components, component_name)) {
            const pool_name = component_name ++ "_pool";
            return &@field(self.pools, pool_name);
        }
    };
}

test "World basic operations" {
    const Components = struct {
        position: @Vector(3, f32),
        velocity: @Vector(3, f32),
    };

    const allocator = std.testing.allocator;
    var world = World(Components).init(allocator);
    defer world.deinit();

    const e1 = world.createEntity();
    const e2 = world.createEntity();

    try world.set("position", e1, .{ 0, 0, 0 });
    try world.set("velocity", e1, .{ 1, 0, 0 });
    try world.set("position", e2, .{ 5, 5, 5 });

    try std.testing.expect(world.has("position", e1));
    try std.testing.expect(world.has("velocity", e1));
    try std.testing.expect(world.has("position", e2));
    try std.testing.expect(!world.has("velocity", e2));

    const pos = world.get("position", e1);
    try std.testing.expect(pos != null);
    try std.testing.expectApproxEqAbs(@as(f32, 0), pos.?.*[0], 0.001);

    pos.?.* = .{ 10, 10, 10 };
    const pos2 = world.get("position", e1);
    try std.testing.expectApproxEqAbs(@as(f32, 10), pos2.?.*[0], 0.001);
}

test "World iteration" {
    const Components = struct {
        value: u32,
    };

    const allocator = std.testing.allocator;
    var world = World(Components).init(allocator);
    defer world.deinit();

    for (0..5) |i| {
        const e = world.createEntity();
        try world.set("value", e, @intCast(i * 10));
    }

    var iter = world.iter("value");
    var count: u32 = 0;
    var sum: u32 = 0;

    while (iter.next()) |entry| {
        count += 1;
        sum += entry.component.*;
    }

    try std.testing.expectEqual(@as(u32, 5), count);
    try std.testing.expectEqual(@as(u32, 100), sum);
}

test "World component hooks" {
    var add_count: u32 = 0;
    var remove_count: u32 = 0;

    const TestComponent = struct {
        value: u32,

        pub fn onAdd(entity: Entity, comp: *const @This(), world: anytype, ctx: ?*anyopaque) void {
            _ = world;
            _ = comp;
            _ = entity;
            if (ctx) |c| {
                @as(*u32, @ptrCast(@alignCast(c))).* += 1;
            }
        }

        pub fn onRemove(entity: Entity, world: anytype, ctx: ?*anyopaque) void {
            _ = world;
            _ = entity;
            if (ctx) |c| {
                @as(*u32, @ptrCast(@alignCast(c))).* += 1;
            }
        }
    };

    const Components = struct {
        test_comp: TestComponent,
    };

    const allocator = std.testing.allocator;
    var world = World(Components).init(allocator);
    defer world.deinit();

    const e = world.createEntity();
    try world.add("test_comp", e, .{ .value = 42 }, &add_count);

    try std.testing.expectEqual(@as(u32, 1), add_count);

    try world.remove("test_comp", e, &remove_count);
    try std.testing.expectEqual(@as(u32, 1), remove_count);
}

comptime {
    std.testing.refAllDecls(@This());
}
