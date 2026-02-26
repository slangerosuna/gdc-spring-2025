const root = @import("../../root.zig");
const sdl = root.sdl;
const ecs = root.ecs;

pub const Input = struct {
    keyboard_state: [*]const bool = undefined,
    num_keys: i32 = 0,
    mouse_x: f32 = 0,
    mouse_y: f32 = 0,
    mouse_xrel: f32 = 0,
    mouse_yrel: f32 = 0,
    mouse_buttons: u32 = 0,
    mouse_wheel_x: f32 = 0,
    mouse_wheel_y: f32 = 0,
    quit_requested: bool = false,

    pub fn keyPressed(self: *const Input, scancode: sdl.SDL_Scancode) bool {
        const idx: usize = @intCast(scancode);
        if (idx >= @as(usize, @intCast(self.num_keys))) return false;
        return self.keyboard_state[idx];
    }

    pub fn mouseButtonPressed(self: *const Input, button: u8) bool {
        if (button >= 32) return false;
        return (self.mouse_buttons & (@as(u32, 1) << button)) != 0;
    }

    pub fn leftPressed(self: *const Input) bool {
        return self.mouseButtonPressed(sdl.SDL_BUTTON_LEFT);
    }

    pub fn rightPressed(self: *const Input) bool {
        return self.mouseButtonPressed(sdl.SDL_BUTTON_RIGHT);
    }

    pub fn middlePressed(self: *const Input) bool {
        return self.mouseButtonPressed(sdl.SDL_BUTTON_MIDDLE);
    }
};

pub const InputSystem = struct {
    input: Input,

    pub const stage = ecs.SystemStage.PreUpdate;

    pub fn init() InputSystem {
        var self: InputSystem = .{
            .input = .{},
        };
        self.input.keyboard_state = sdl.SDL_GetKeyboardState(&self.input.num_keys);
        return self;
    }

    pub fn run(self: *InputSystem) void {
        self.input.mouse_xrel = 0;
        self.input.mouse_yrel = 0;
        self.input.mouse_wheel_x = 0;
        self.input.mouse_wheel_y = 0;
        self.input.quit_requested = false;

        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            switch (event.type) {
                sdl.SDL_EVENT_QUIT => {
                    self.input.quit_requested = true;
                },
                sdl.SDL_EVENT_MOUSE_MOTION => {
                    self.input.mouse_x = event.motion.x;
                    self.input.mouse_y = event.motion.y;
                    self.input.mouse_xrel += event.motion.xrel;
                    self.input.mouse_yrel += event.motion.yrel;
                },
                sdl.SDL_EVENT_MOUSE_WHEEL => {
                    self.input.mouse_wheel_x += event.wheel.x;
                    self.input.mouse_wheel_y += event.wheel.y;
                },
                else => {},
            }
        }

        var mx: f32 = undefined;
        var my: f32 = undefined;
        self.input.mouse_buttons = sdl.SDL_GetMouseState(&mx, &my);
        if (self.input.mouse_xrel == 0 and self.input.mouse_yrel == 0) {
            self.input.mouse_x = mx;
            self.input.mouse_y = my;
        }
    }

    pub fn getInput(self: *const InputSystem) *const Input {
        return &self.input;
    }

    pub fn getInputMut(self: *InputSystem) *Input {
        return &self.input;
    }

    pub fn quitRequested(self: *const InputSystem) bool {
        return self.input.quit_requested;
    }
};
