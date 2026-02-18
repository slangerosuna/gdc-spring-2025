fn nothing() void {}

const System = struct {
    comptime f: fn () void = nothing, // TODO: figure out how to allow parameterized systems
};

pub fn system(
    comptime f: fn () void, // TODO: figure out how to allow parameterized systems
) void {
    _ = f;
}
