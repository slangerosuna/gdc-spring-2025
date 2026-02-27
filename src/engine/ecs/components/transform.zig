// TODO: switch to transform matrix

pub const Transform = struct {
    position: @Vector(3, f32) = .{ 0, 0, 0 }, // euclidean coordinates
    rotation: @Vector(4, f32) = .{ 0, 0, 0, 1 }, // quaternion
    scale: @Vector(3, f32) = .{ 1, 1, 1 }, //xyz
};
