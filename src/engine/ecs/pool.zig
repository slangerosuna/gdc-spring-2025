const std = @import("std");

pub const Entity = u32;

pub const invalid_entity: Entity = std.math.maxInt(Entity);

pub fn Pool(comptime T: type) type {
    return struct {
        const Self = @This();

        data: []T,
        entity_to_index: []u32,
        index_to_entity: []Entity,
        count: u32,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .data = &.{},
                .entity_to_index = &.{},
                .index_to_entity = &.{},
                .count = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.data.len > 0) self.allocator.free(self.data);
            if (self.entity_to_index.len > 0) self.allocator.free(self.entity_to_index);
            if (self.index_to_entity.len > 0) self.allocator.free(self.index_to_entity);
        }

        pub fn add(self: *Self, entity: Entity, component: T) !void {
            if (entity >= self.entity_to_index.len) {
                try self.growSparse(entity + 1);
            }

            if (self.entity_to_index[entity] != invalid_entity) {
                const idx = self.entity_to_index[entity];
                self.data[idx] = component;
                return;
            }

            if (self.count >= self.data.len) {
                try self.growDense();
            }

            const idx = self.count;
            self.entity_to_index[entity] = idx;
            self.index_to_entity[idx] = entity;
            self.data[idx] = component;
            self.count += 1;
        }

        pub fn get(self: *const Self, entity: Entity) ?*const T {
            if (!self.has(entity)) return null;
            const idx = self.entity_to_index[entity];
            return &self.data[idx];
        }

        pub fn getMut(self: *Self, entity: Entity) ?*T {
            if (!self.has(entity)) return null;
            const idx = self.entity_to_index[entity];
            return &self.data[idx];
        }

        pub fn has(self: *const Self, entity: Entity) bool {
            return entity < self.entity_to_index.len and self.entity_to_index[entity] != invalid_entity;
        }

        pub const Error = error{EntityNotFound};

        pub fn remove(self: *Self, entity: Entity) Error!void {
            if (!self.has(entity)) return Error.EntityNotFound;

            const idx = self.entity_to_index[entity];
            const last_idx = self.count - 1;

            self.entity_to_index[entity] = invalid_entity;

            if (idx != last_idx) {
                const moved_entity = self.index_to_entity[last_idx];
                self.index_to_entity[idx] = moved_entity;
                self.data[idx] = self.data[last_idx];
                self.entity_to_index[moved_entity] = idx;
            }

            self.count -= 1;
        }

        pub fn iter(self: *const Self) Iter(T) {
            return .{
                .data = self.data,
                .index_to_entity = self.index_to_entity,
                .count = self.count,
            };
        }

        pub fn clear(self: *Self) void {
            @memset(self.entity_to_index, invalid_entity);
            self.count = 0;
        }

        pub fn len(self: *const Self) u32 {
            return self.count;
        }

        fn growSparse(self: *Self, min_size: usize) !void {
            const new_size = @max(min_size, if (self.entity_to_index.len == 0) 64 else self.entity_to_index.len * 2);
            const old_len = self.entity_to_index.len;

            const new_sparse = try self.allocator.alloc(u32, new_size);
            @memcpy(new_sparse[0..old_len], self.entity_to_index);
            @memset(new_sparse[old_len..], invalid_entity);

            if (self.entity_to_index.len > 0) self.allocator.free(self.entity_to_index);
            self.entity_to_index = new_sparse;
        }

        fn growDense(self: *Self) !void {
            const new_size = if (self.data.len == 0) 64 else self.data.len * 2;

            const new_data = try self.allocator.alloc(T, new_size);
            const new_index_to_entity = try self.allocator.alloc(Entity, new_size);

            @memcpy(new_data[0..self.count], self.data[0..self.count]);
            @memcpy(new_index_to_entity[0..self.count], self.index_to_entity[0..self.count]);

            if (self.data.len > 0) self.allocator.free(self.data);
            if (self.index_to_entity.len > 0) self.allocator.free(self.index_to_entity);

            self.data = new_data;
            self.index_to_entity = new_index_to_entity;
        }
    };
}

pub fn Iter(comptime T: type) type {
    return struct {
        data: []const T,
        index_to_entity: []const Entity,
        count: u32,
        index: u32 = 0,

        pub const Entry = struct {
            entity: Entity,
            component: *const T,
        };

        pub fn next(self: *@This()) ?Entry {
            if (self.index >= self.count) return null;
            const entity = self.index_to_entity[self.index];
            const component = &self.data[self.index];
            self.index += 1;
            return .{ .entity = entity, .component = component };
        }

        pub fn reset(self: *@This()) void {
            self.index = 0;
        }
    };
}

test "Pool basic operations" {
    const allocator = std.testing.allocator;

    var pool = Pool(f32).init(allocator);
    defer pool.deinit();

    try pool.add(0, 1.5);
    try pool.add(5, 2.5);
    try pool.add(10, 3.5);

    try std.testing.expect(pool.has(0));
    try std.testing.expect(pool.has(5));
    try std.testing.expect(pool.has(10));
    try std.testing.expect(!pool.has(1));

    try std.testing.expectApproxEqAbs(@as(f32, 1.5), pool.get(0).?.*, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 2.5), pool.get(5).?.*, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 3.5), pool.get(10).?.*, 0.001);

    try pool.remove(5);
    try std.testing.expect(!pool.has(5));
    try std.testing.expect(pool.has(0));
    try std.testing.expect(pool.has(10));
}

test "Pool iteration" {
    const allocator = std.testing.allocator;

    var pool = Pool(u32).init(allocator);
    defer pool.deinit();

    try pool.add(0, 100);
    try pool.add(1, 200);
    try pool.add(2, 300);

    var iter = pool.iter();
    var count: u32 = 0;
    var sum: u32 = 0;

    while (iter.next()) |entry| {
        count += 1;
        sum += entry.component.*;
    }

    try std.testing.expectEqual(@as(u32, 3), count);
    try std.testing.expectEqual(@as(u32, 600), sum);
}

test "Pool overwrite" {
    const allocator = std.testing.allocator;

    var pool = Pool(f32).init(allocator);
    defer pool.deinit();

    try pool.add(0, 1.0);
    try pool.add(0, 2.0);

    try std.testing.expectEqual(@as(u32, 1), pool.len());
    try std.testing.expectApproxEqAbs(@as(f32, 2.0), pool.get(0).?.*, 0.001);
}

comptime {
    std.testing.refAllDecls(@This());
}
