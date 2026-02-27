const root = @import("../../root.zig");
const sdl = root.sdl;
const ecs = root.ecs;

pub const Time = struct {
    dt: f32 = 0,
    frame: u64 = 0,
    start_ns: u64 = 0,
    last_ns: u64 = 0,

    pub fn elapsed(self: *const Time) f32 {
        const now_ns = sdl.SDL_GetTicksNS();
        return @as(f32, @floatFromInt(now_ns - self.start_ns)) / 1_000_000_000.0;
    }

    pub fn init() Time {
        return .{
            .last_ns = sdl.SDL_GetTicksNS(),
        };
    }

    pub fn update(self: *Time) void {
        const now_ns = sdl.SDL_GetTicksNS();
        const delta_ns = now_ns - self.last_ns;
        self.dt = @as(f32, @floatFromInt(delta_ns)) / 1_000_000_000.0;
        self.frame += 1;
        self.last_ns = now_ns;
    }

    pub fn total(_: *const Time) f32 {
        return @as(f32, @floatFromInt(sdl.SDL_GetTicksNS())) / 1_000_000_000.0;
    }
};

pub const TimeSystem = struct {
    pub const stage = ecs.SystemStage.PreUpdate;

    pub const Res = struct {
        time: *Time,
    };

    pub fn run(res: Res, world: anytype) void {
        _ = world;
        res.time.update();
    }
};
