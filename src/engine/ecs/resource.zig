const std = @import("std");

pub fn Resources(comptime ResourceDefs: type) type {
    const fields = @typeInfo(ResourceDefs).@"struct".fields;

    comptime var storage_fields: [fields.len]std.builtin.Type.StructField = undefined;
    inline for (fields, 0..) |field, i| {
        storage_fields[i] = .{
            .name = field.name,
            .type = ?field.type,
            .default_value_ptr = @ptrCast(&@as(?field.type, null)),
            .is_comptime = false,
            .alignment = @alignOf(?field.type),
        };
    }

    const Storage = @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .fields = &storage_fields,
            .decls = &.{},
            .is_tuple = false,
        },
    });

    return struct {
        storage: Storage,

        const Self = @This();

        pub fn init() Self {
            return .{ .storage = std.mem.zeroInit(Storage, .{}) };
        }

        pub fn set(self: *Self, comptime name: []const u8, value: @FieldType(ResourceDefs, name)) void {
            @field(self.storage, name) = value;
        }

        pub fn get(self: *const Self, comptime name: []const u8) ?@FieldType(ResourceDefs, name) {
            return @field(self.storage, name);
        }

        pub fn getPtr(self: *const Self, comptime name: []const u8) ?*@FieldType(ResourceDefs, name) {
            const val = @field(self.storage, name);
            if (val) |*v| {
                return v;
            }
            return null;
        }

        pub fn has(self: *const Self, comptime name: []const u8) bool {
            return @field(self.storage, name) != null;
        }

        pub fn clear(self: *Self, comptime name: []const u8) void {
            @field(self.storage, name) = null;
        }

        pub fn clearAll(self: *Self) void {
            inline for (fields) |field| {
                @field(self.storage, field.name) = null;
            }
        }
    };
}

pub fn buildResourceStruct(
    comptime ResourceDefs: type,
    comptime ResourcesStore: type,
    comptime ResDecl: type,
    resources: *const ResourcesStore,
) ResDecl {
    const res_fields = @typeInfo(ResDecl).@"struct".fields;
    var result: ResDecl = undefined;

    inline for (res_fields) |field| {
        const name = field.name;
        const ResType = @FieldType(ResourceDefs, name);

        comptime {
            if (@typeInfo(field.type) != .pointer) {
                @compileError("Resource field '" ++ name ++ "' must be a pointer type (*T or *const T)");
            }
            const field_child = @typeInfo(field.type).pointer.child;
            const res_child = if (@typeInfo(ResType) == .pointer) @typeInfo(ResType).pointer.child else ResType;
            if (field_child != res_child) {
                @compileError("Resource '" ++ name ++ "' type mismatch: expected " ++ @typeName(res_child) ++ ", found " ++ @typeName(field_child));
            }
        }

        const value = resources.get(name);
        if (value == null) {
            std.debug.panic("Resource '{s}' not set", .{name});
        }

        @field(result, name) = value.?;
    }

    return result;
}

pub fn extractResources(
    comptime ResourceDefs: type,
    comptime ResourcesStore: type,
    comptime ResDecl: type,
    resources: *const ResourcesStore,
) ?ResDecl {
    _ = ResourceDefs;
    const res_fields = @typeInfo(ResDecl).@"struct".fields;
    var result: ResDecl = undefined;

    inline for (res_fields) |field| {
        const name = field.name;

        const value = resources.get(name);
        if (value == null) {
            return null;
        }

        @field(result, name) = value.?;
    }

    return result;
}

test "Resources basic operations" {
    const TestResources = struct {
        device: *u32,
        count: u32,
        name: []const u8,
    };

    var res = Resources(TestResources).init();

    try std.testing.expect(!res.has("device"));
    try std.testing.expect(!res.has("count"));

    var device_val: u32 = 42;
    res.set("device", &device_val);
    res.set("count", 100);
    res.set("name", "test");

    try std.testing.expect(res.has("device"));
    try std.testing.expect(res.has("count"));
    try std.testing.expect(res.has("name"));

    const dev = res.get("device");
    try std.testing.expect(dev != null);
    try std.testing.expectEqual(@as(u32, 42), dev.?.*);

    const cnt = res.get("count");
    try std.testing.expect(cnt != null);
    try std.testing.expectEqual(@as(u32, 100), cnt.?);

    res.clear("count");
    try std.testing.expect(!res.has("count"));
}

test "buildResourceStruct" {
    const TestResources = struct {
        device: *u32,
        count: *const u32,
    };

    const ResDecl = struct {
        device: *u32,
        count: *const u32,
    };

    var res = Resources(TestResources).init();

    var device_val: u32 = 42;
    var count_val: u32 = 100;
    res.set("device", &device_val);
    res.set("count", &count_val);

    const extracted = buildResourceStruct(TestResources, Resources(TestResources), ResDecl, &res);

    try std.testing.expectEqual(@as(u32, 42), extracted.device.*);
    try std.testing.expectEqual(@as(u32, 100), extracted.count.*);
}

comptime {
    std.testing.refAllDecls(@This());
}
