const std = @import("std");
const ecs = @import("ecs.zig");
const Type = std.builtin.Type;

pub const TypeId = u64;

pub const hash_table: [256]u64 = blk: {
    var value: [256]u64 = undefined;
    var hash: u64 = 0x96f30b2dd403d7c1;

    for (0..value.len) |i| {
        hash ^= i *% 0x9E3779B185EBCA87;
        hash ^= (hash << 27) | (hash >> 37);
        hash *%= 0x100000001B3;

        hash ^= hash >> 33;
        hash *%= 0xff51afd7ed558ccd;
        hash ^= hash >> 33;
        hash *%= 0xc4ceb9fe1a85ec53;
        hash ^= hash >> 33;

        value[i] = hash;
    }

    break :blk value;
};

pub fn typeIdOf(comptime t: type) TypeId {
    return comptime blk: {
        var hash: u64 = 0xcbf29ce484222325;

        for (@typeName(t)) |byte| {
            hash ^= hash_table[byte];
            hash = (hash << 27) | (hash >> 37);
            hash *%= 0x100000001B3;
        }

        hash ^= @typeName(t).len *% 0x9E3779B97F4A7C15;

        // murmur3 finalizer
        // used so I can put it into a hashmap without hashing again and still have good distribution
        hash ^= hash >> 33;
        hash *%= 0xff51afd7ed558ccd;
        hash ^= hash >> 33;
        hash *%= 0xc4ceb9fe1a85ec53;
        hash ^= hash >> 33;

        break :blk hash;
    };
}

pub const QueryField = struct {
    field_name: [:0]const u8,
    id: TypeId,
    is_const: bool,
    is_optional: bool,
    type: type,
};

pub fn Query(comptime query: anytype) type {
    return Internal(query) catch unreachable;
}

fn Internal(comptime query: anytype) !type {
    var fields: [ecs.config.max_components]QueryField = undefined;
    var cur_field = 0;

    var with_fields: [ecs.config.max_components]TypeId = undefined;
    var cur_with_field = 0;

    for (std.meta.fields(@TypeOf(query))) |field| {
        if (std.mem.eql(u8, field.name, "with")) {
            const value = @field(query, field.name);

            for (std.meta.fields(@TypeOf(value))) |withField| {
                const with = @field(value, withField.name);
                const id = typeIdOf(with);

                with_fields[cur_with_field] = id;
                cur_with_field += 1;

                if (cur_with_field >= with_fields.len) {
                    return error.TooManyWithFields;
                }
            }

            continue;
        }
        if (std.mem.eql(u8, field.name, "QUERYINFO")) {
            return error.QUERYINFOIsAReservedIdentifier;
        }

        const value: type = @field(query, field.name);

        var ptr = value;
        var is_optional = false;

        if (@typeInfo(value) == .optional) {
            ptr = @typeInfo(value).optional.child;
            is_optional = true;
        }

        if (@typeInfo(ptr) != .pointer) {
            return error.FieldTypeMustBePointer;
        }

        const info = @typeInfo(ptr).pointer;

        if (info.size != .one) {
            return error.FieldTypeMustNotBeSlice;
        }

        const id = typeIdOf(info.child);
        const is_const: bool = info.is_const;

        fields[cur_field] = .{
            .field_name = field.name,
            .id = id,
            .is_const = is_const,
            .is_optional = is_optional,
            .type = value,
        };

        cur_field += 1;
        if (cur_field >= fields.len) {
            return error.TooManyFields;
        }
    }

    var struct_fields: [64]Type.StructField = undefined;
    const QueryInfoTy = @Type(.{ .@"struct" = .{
        .layout = .auto,
        .fields = &[4]Type.StructField{ .{
            .name = "fields",
            .type = [cur_field]QueryField,
            .default_value_ptr = fields[0..cur_field],
            .is_comptime = true,
            .alignment = @alignOf([cur_field]QueryField),
        }, .{
            .name = "fields_count",
            .type = comptime_int,
            .default_value_ptr = &cur_field,
            .is_comptime = true,
            .alignment = @alignOf(comptime_int),
        }, .{
            .name = "with",
            .type = [cur_with_field]TypeId,
            .default_value_ptr = with_fields[0..cur_with_field],
            .is_comptime = true,
            .alignment = @alignOf([cur_with_field]TypeId),
        }, .{
            .name = "with_count",
            .type = comptime_int,
            .default_value_ptr = &cur_with_field,
            .is_comptime = true,
            .alignment = @alignOf(comptime_int),
        } },
        .decls = &[0]Type.Declaration{},
        .is_tuple = false,
    } });

    struct_fields[0] = .{
        .name = "QUERYINFO",
        .type = type,
        .default_value_ptr = &QueryInfoTy,
        .is_comptime = true,
        .alignment = @alignOf(QueryInfoTy),
    };

    var cur_struct_field = 1;

    for (0..cur_field) |i| {
        struct_fields[cur_struct_field] = .{
            .name = fields[i].field_name,
            .type = fields[i].type,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(fields[i].type),
        };
        cur_struct_field += 1;
    }

    return []const @Type(Type{ .@"struct" = .{
        .layout = .auto,
        .fields = struct_fields[0..cur_struct_field],
        .decls = &[0]Type.Declaration{},

        .is_tuple = false,
    } });
}

pub const QueryInfo = struct {
    fields: []const QueryField,
    with: []const TypeId,
};

pub fn queryInfo(comptime query: type) QueryInfo {
    const inner = @typeInfo(query).pointer.child;
    const queryInfoTy: *const type = for (@typeInfo(inner).@"struct".fields) |field| {
        if (std.mem.eql(u8, field.name, "QUERYINFO")) {
            break @ptrCast(field.default_value_ptr.?);
        }
    };

    const queryInfoTyFields = @typeInfo(queryInfoTy.*).@"struct".fields;

    var fields_count: comptime_int = undefined;
    var with_count: comptime_int = undefined;

    for (queryInfoTyFields) |field| {
        if (std.mem.eql(u8, field.name, "fields_count")) {
            const fields_count_ptr: *const comptime_int = @ptrCast(field.default_value_ptr.?);
            fields_count = fields_count_ptr.*;
        }
        if (std.mem.eql(u8, field.name, "with_count")) {
            const with_count_ptr: *const comptime_int = @ptrCast(field.default_value_ptr.?);
            with_count = with_count_ptr.*;
        }
    }

    var fields: [fields_count]QueryField = undefined;
    var with: [with_count]TypeId = undefined;

    for (queryInfoTyFields) |field| {
        if (std.mem.eql(u8, field.name, "fields")) {
            const fields_ptr: *const [fields_count]QueryField = @ptrCast(@alignCast(field.default_value_ptr.?));
            fields = fields_ptr.*;
        }
        if (std.mem.eql(u8, field.name, "with")) {
            const with_ptr: *const [with_count]TypeId = @ptrCast(@alignCast(field.default_value_ptr.?));
            with = with_ptr.*;
        }
    }

    return .{
        .fields = &fields,
        .with = &with,
    };
}

test "ensure Query generates correct query info" {
    const Transform = struct {};
    const Camera = struct {};
    const Player = struct {};

    const QueryType = Query(.{ .transform = *Transform, .camera = ?*const Camera, .with = .{ .player_tag = Player } });

    const QueryInfoFieldNoType = struct {
        field_name: [:0]const u8,
        id: u64,
        is_const: bool,
        is_optional: bool,
    };

    const query_info = comptime outer: {
        const info = queryInfo(QueryType);
        const fields: [info.fields.len]QueryField = info.fields[0..info.fields.len].*;
        const with: [info.with.len]TypeId = info.with[0..info.with.len].*;

        const fields_no_type: [fields.len]QueryInfoFieldNoType = inner: {
            var arr: [fields.len]QueryInfoFieldNoType = undefined;
            for (0..fields.len) |i| {
                const field = fields[i];
                arr[i] = .{
                    .field_name = field.field_name,
                    .id = field.id,
                    .is_const = field.is_const,
                    .is_optional = field.is_optional,
                };
            }
            break :inner arr;
        };

        break :outer .{
            .fields = fields_no_type,
            .with = with,
        };
    };

    // basically the only reason I do it like this is so the error message is readable
    // I very much could compare directly without converting to a string first, but the error message would be unreadable
    var queryInfoBuf: [1024]u8 = undefined;
    const queryInfoString = try std.fmt.bufPrint(&queryInfoBuf, "{}", .{query_info});

    var testStringBuf: [1024]u8 = undefined;
    const testString = try std.fmt.bufPrint(&testStringBuf, "{}", .{.{
        .fields = [_]QueryInfoFieldNoType{
            .{ .field_name = "transform", .id = typeIdOf(Transform), .is_const = false, .is_optional = false },
            .{ .field_name = "camera", .id = typeIdOf(Camera), .is_const = true, .is_optional = true },
        },
        .with = [_]TypeId{typeIdOf(Player)},
    }});

    std.testing.expect(std.mem.eql(u8, queryInfoString, testString)) catch {
        std.debug.print("\nGenerated query info: {s}\n", .{queryInfoString});
        std.debug.print("\nExpected query info: {s}\n", .{testString});

        return error.IncorrectQueryInfo;
    };
}
