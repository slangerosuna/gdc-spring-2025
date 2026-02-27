const std = @import("std");
const gdc = @import("gdc_spring_2025");
const sdl = gdc.sdl;

const Transform = struct {
    position: @Vector(3, f32) = .{ 0, 0, 0 },
    rotation: @Vector(4, f32) = .{ 0, 0, 0, 1 },
    scale: @Vector(3, f32) = .{ 1, 1, 1 },
};

const Mesh = struct {
    vertex_buffer: ?*sdl.SDL_GPUBuffer = null,
    index_buffer: ?*sdl.SDL_GPUBuffer = null,
    num_vertices: u32 = 0,
    num_indices: u32 = 0,
    index_size: c_uint = sdl.SDL_GPU_INDEXELEMENTSIZE_16BIT,
};

const Material = struct {
    pipeline: ?*sdl.SDL_GPUGraphicsPipeline = null,
    texture: ?*sdl.SDL_GPUTexture = null,
    sampler: ?*sdl.SDL_GPUSampler = null,
    color: struct { r: f32 = 1, g: f32 = 1, b: f32 = 1, a: f32 = 1 } = .{},
};

const Camera = struct {
    fov: f32 = 75.0,
    near_clip: f32 = 0.1,
    far_clip: f32 = 1000.0,
};

const PointLight = struct {
    color: sdl.SDL_FColor = .{ .r = 1, .g = 1, .b = 1, .a = 1 },
};

const AmbientLight = struct {
    color: sdl.SDL_FColor = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1 },
};

const Rotation = struct {
    speed: f32 = 1.0,
};

const Components = struct {
    transform: Transform,
    mesh: Mesh,
    material: Material,
    camera: Camera,
    point_light: PointLight,
    ambient_light: AmbientLight,
    rotation: Rotation,
};

const ResourceDefs = struct {
    device: *sdl.SDL_GPUDevice,
    window: *sdl.SDL_Window,
    time: *gdc.Time,
    input: *gdc.Input,
};

const app_config = gdc.ecs.App.AppConfig{
    .name = "GDC Spring 2025",
    .version = "0.1.0",
    .identifier = "com.gdc.spring2025",
    .width = 1280,
    .height = 720,
};

const RotationSystem = struct {
    pub const stage = gdc.ecs.SystemStage.Update;

    pub const Res = struct {
        time: *gdc.Time,
    };

    pub const Query = struct {
        transform: *Transform,
        rotation: *const Rotation,
    };

    pub fn runEntity(res: Res, entity: gdc.ecs.Entity, query: Query) void {
        _ = entity;
        _ = res;
        _ = query;
    }
};

fn setup(ctx: *gdc.ecs.App.Context(Components, ResourceDefs)) void {
    _ = ctx;
}

pub fn main() !void {
    gdc.ecs.App.runWith(
        .{RotationSystem},
        app_config,
        Components,
        ResourceDefs,
        setup,
    );
}
