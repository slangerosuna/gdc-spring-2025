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
};

pub const TimeSystem = struct {
    time: Time,

    pub const stage = ecs.SystemStage.PreUpdate;

    pub fn init() TimeSystem {
        return .{
            .time = Time{
                .last_ns = sdl.SDL_GetTicksNS(),
            },
        };
    }

    pub fn run(self: *TimeSystem) void {
        const now_ns = sdl.SDL_GetTicksNS();
        const delta_ns = now_ns - self.time.last_ns;
        self.time.dt = @as(f32, @floatFromInt(delta_ns)) / 1_000_000_000.0;
        self.time.frame += 1;
        self.time.last_ns = now_ns;
    }

    pub fn getTime(self: *const TimeSystem) *const Time {
        return &self.time;
    }

    pub fn getTimeMut(self: *TimeSystem) *Time {
        return &self.time;
    }

    pub fn total(self: *const TimeSystem) f32 {
        _ = self;
        return @as(f32, @floatFromInt(sdl.SDL_GetTicksNS())) / 1_000_000_000.0;
    }
};
