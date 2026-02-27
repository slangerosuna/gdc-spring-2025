const sdl = @import("sdl");

pub const Mesh = struct {
    vertex_buffer: ?*sdl.SDL_GPUBuffer,
    num_vertices: u32,
    index_buffer: ?*sdl.SDL_GPUBuffer,
    num_indices: u32,
    index_size: sdl.SDL_GPUIndexElementSize,
};
