const std = @import("std");
const query = @import("query.zig");
const config = @import("config.zon");
const ecs_mod = @import("ecs.zig");
const resource_mod = @import("resource.zig");
const scheduler_mod = @import("scheduler.zig");

const SystemStage = scheduler_mod.SystemStage;

pub fn build(comptime root_plugin: type) type {
    return struct {
        pub const Systems = root_plugin.Systems;

        pub const StateMachine = struct {
            current: ?[]const u8 = null,
            transitions: std.StringHashMap([]const u8),

            pub fn init(allocator: std.mem.Allocator) @This() {
                return .{
                    .transitions = std.StringHashMap([]const u8).init(allocator),
                };
            }

            pub fn deinit(self: *@This()) void {
                self.transitions.deinit();
            }

            pub fn set(self: *@This(), state: []const u8) void {
                self.current = state;
            }

            pub fn get(self: *const @This()) ?[]const u8 {
                return self.current;
            }
        };

        pub fn run() void {
            @panic("App.run() requires config. Use App.runWith(.{...}, AppConfig, Components, ResourceDefs, setup)");
        }

        pub fn runWith(
            comptime user_systems: anytype,
            comptime app_config: AppConfig,
            comptime Components: type,
            comptime ResourceDefs: type,
            comptime setup: anytype,
        ) void {
            const root = @import("../../root.zig");
            const sdl = root.sdl;
            const Time = root.Time;
            const Input = root.Input;
            const RenderSystem = root.RenderSystem;

            const World = ecs_mod.World(Components);

            const all_systems = comptime blk: {
                var arr: [Systems.len + user_systems.len]type = undefined;
                for (Systems, 0..) |sys, i| arr[i] = sys;
                for (user_systems, 0..) |sys, i| arr[Systems.len + i] = sys;
                break :blk arr;
            };
            const TypedScheduler = scheduler_mod.Scheduler(World, ResourceDefs, &all_systems);

            _ = sdl.SDL_SetAppMetadata(app_config.name.ptr, app_config.version.ptr, app_config.identifier.ptr);

            if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
                std.debug.panic("Failed to init SDL: {s}", .{sdl.SDL_GetError()});
            }
            defer sdl.SDL_Quit();

            const device = sdl.SDL_CreateGPUDevice(sdl.SDL_GPU_SHADERFORMAT_SPIRV, true, null) orelse {
                std.debug.panic("Failed to create GPU device: {s}", .{sdl.SDL_GetError()});
            };
            defer sdl.SDL_DestroyGPUDevice(device);

            const window = sdl.SDL_CreateWindow(
                app_config.name.ptr,
                @intCast(app_config.width),
                @intCast(app_config.height),
                sdl.SDL_WINDOW_RESIZABLE,
            ) orelse {
                std.debug.panic("Failed to create window: {s}", .{sdl.SDL_GetError()});
            };
            defer sdl.SDL_DestroyWindow(window);

            if (!sdl.SDL_ClaimWindowForGPUDevice(device, window)) {
                std.debug.panic("Failed to claim window for GPU: {s}", .{sdl.SDL_GetError()});
            }

            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer _ = gpa.deinit();
            const allocator = gpa.allocator();

            var world = World.init(allocator);
            defer world.deinit();

            const ResourcesStore = resource_mod.Resources(ResourceDefs);
            var resources = ResourcesStore.init();

            var time = Time.init();
            var input = Input.init();

            resources.set("device", device);
            resources.set("window", window);
            resources.set("time", &time);
            resources.set("input", &input);

            const Ctx = Context(Components, ResourceDefs);
            var ctx: Ctx = .{
                .device = device,
                .window = window,
                .world = &world,
                .resources = &resources,
                .time = &time,
                .input = &input,
                .allocator = allocator,
            };

            const setup_info = @typeInfo(@TypeOf(setup));
            if (setup_info == .@"fn") {
                const params = setup_info.@"fn".params;
                if (params.len == 1) {
                    setup(&ctx);
                } else if (params.len == 2) {
                    setup(&ctx, &world);
                } else if (params.len == 3) {
                    setup(&ctx, &world, &resources);
                }
            }

            mainLoop: while (true) {
                TypedScheduler.runStage(.PreUpdate, &world, &resources);

                if (input.quit_requested) {
                    break :mainLoop;
                }

                TypedScheduler.runStage(.Update, &world, &resources);
                TypedScheduler.runStage(.PostUpdate, &world, &resources);

                if (ctx.camera_entity) |cam| {
                    const render_res = RenderSystem.Res{
                        .device = device,
                        .camera_entity = cam,
                        .target = .{ .swapchain = window },
                    };
                    RenderSystem.run(render_res, &world);
                }
            }

            RenderSystem.deinit(device);
            sdl.SDL_ReleaseWindowFromGPUDevice(device, window);
        }

        pub fn Context(comptime Components: type, comptime ResourceDefs: type) type {
            return struct {
                device: *anyopaque,
                window: *anyopaque,
                world: *ecs_mod.World(Components),
                resources: *resource_mod.Resources(ResourceDefs),
                time: *@import("../../root.zig").Time,
                input: *@import("../../root.zig").Input,
                allocator: std.mem.Allocator,
                camera_entity: ?ecs_mod.Entity = null,

                const Self = @This();

                pub fn setCamera(self: *Self, entity: ecs_mod.Entity) void {
                    self.camera_entity = entity;
                }

                pub fn getDevice(self: *const Self) *anyopaque {
                    return self.device;
                }

                pub fn getWindow(self: *const Self) *anyopaque {
                    return self.window;
                }

                pub fn sdlDevice(self: *const Self) *@import("../../root.zig").sdl.SDL_GPUDevice {
                    return @ptrCast(self.device);
                }

                pub fn sdlWindow(self: *const Self) *@import("../../root.zig").sdl.SDL_Window {
                    return @ptrCast(self.window);
                }
            };
        }

        pub const AppConfig = struct {
            name: [:0]const u8,
            version: [:0]const u8,
            identifier: [:0]const u8,
            width: u32,
            height: u32,
        };
    };
}
