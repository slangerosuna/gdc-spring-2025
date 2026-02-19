const std = @import("std");
const gdc_spring_2025 = @import("gdc_spring_2025");
const Query = gdc_spring_2025.query.Query;

pub const Transform = struct {
    x: f32,
    y: f32,
};

pub const Camera = struct {
    zoom: f32,
};

pub const Player = struct {};

pub const Input = struct {
    up: bool,
    down: bool,
    left: bool,
    right: bool,
};

pub fn main() !void {
    const QueryType = try Query(.{
        .transform = *Transform,
        .camera = *const Camera,
        .with = .{
            .player_tag = Player,
        },
    });

    _ = QueryType;
}
