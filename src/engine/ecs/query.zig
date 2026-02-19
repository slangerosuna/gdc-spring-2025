const std = @import("std");
const Type = std.builtin.Type;

pub const TypeId = u64;

pub fn typeIdOf(comptime t: type) TypeId {
    const secret: [64]u64 = comptime blk: {
        var value: [64]u64 = undefined;
        var hash = 0xDEADBEEFDEADBEEF;

        for (0..value.len) |i| {
            hash = (hash ^ (hash % 256)) * 0x100000001B3;

            value[i] = hash % (1 << 64);
        }

        break :blk value;
    };

    var hash = secret[10];

    for (@typeName(t)) |byte| {
        hash = ((hash +% secret[byte % 64]) ^ @as(u64, byte)) *% 0x100000001B3;
    }

    return hash;
}

pub const QueryField = struct {
    field_name: [:0]const u8,
    id: TypeId,
    is_const: bool,
    type: type,
};

pub fn Query(comptime query: anytype) !type {
    var fields: [64]QueryField = undefined;
    var cur_field = 0;

    var with_fields: [64]TypeId = undefined;
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

        const value: type = @field(query, field.name);

        const info = @typeInfo(value).pointer;
        const id = typeIdOf(value);
        const is_const: bool = info.is_const;

        fields[cur_field] = .{
            .field_name = field.name,
            .id = id,
            .is_const = is_const,
            .type = value,
        };

        cur_field += 1;
        if (cur_field >= fields.len) {
            return error.TooManyFields;
        }
    }

    var struct_fields: [64]Type.StructField = undefined;
    var cur_struct_field = 0;

    for (0..cur_field) |i| {
        struct_fields[cur_struct_field] = .{
            .name = fields[i].field_name,
            .type = fields[i].type,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = 1, // Minimal alignment for placeholder type
        };
        cur_struct_field += 1;
    }

    return []const @Type(Type{ .@"struct" = .{
        .layout = .auto,
        .fields = struct_fields[0..cur_struct_field],
        .decls = &[_]Type.Declaration{},

        .is_tuple = false,
    } });
}
