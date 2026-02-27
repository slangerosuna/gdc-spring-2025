const std = @import("std");
const root = @import("../../root.zig");
const sdl = root.sdl;
const Material = @import("../ecs/components/material.zig").Material;

const common = @import("common.zig");
const loadShaderFromBytes = common.loadShaderFromBytes;
const loadTexture = common.loadTexture;
const createWhiteTexture = common.createWhiteTexture;
const createDefaultSampler = common.createDefaultSampler;

pub const pbr_vert_spv align(4) = @embedFile("../../shaders/spirv/pbr.vert.spv");
pub const pbr_frag_spv align(4) = @embedFile("../../shaders/spirv/pbr.frag.spv");

pub const PBRMaterialArgs = struct {
    albedo_texture: ?*sdl.SDL_GPUTexture = null,
    metallic_texture: ?*sdl.SDL_GPUTexture = null,
    roughness_texture: ?*sdl.SDL_GPUTexture = null,
    ao_texture: ?*sdl.SDL_GPUTexture = null,
    sampler: ?*sdl.SDL_GPUSampler = null,
    cullmode: sdl.SDL_GPUCullMode = sdl.SDL_GPU_CULLMODE_BACK,
};

pub fn createPBRMaterial(
    device: *sdl.SDL_GPUDevice,
    format: sdl.SDL_GPUTextureFormat,
    args: PBRMaterialArgs,
) !Material {
    const vertex_shader = try loadShaderFromBytes(
        device,
        pbr_vert_spv,
        sdl.SDL_GPU_SHADERSTAGE_VERTEX,
        .{ .sampler_count = 0, .uniform_buffer_count = 2, .storage_buffer_count = 0 },
    );
    errdefer sdl.SDL_ReleaseGPUShader(device, vertex_shader);

    const fragment_shader = try loadShaderFromBytes(
        device,
        pbr_frag_spv,
        sdl.SDL_GPU_SHADERSTAGE_FRAGMENT,
        .{ .sampler_count = 4, .uniform_buffer_count = 1, .storage_buffer_count = 2 },
    );
    errdefer sdl.SDL_ReleaseGPUShader(device, fragment_shader);

    const pipe_info = sdl.SDL_GPUGraphicsPipelineCreateInfo{
        .target_info = .{
            .num_color_targets = 1,
            .color_target_descriptions = &[_]sdl.SDL_GPUColorTargetDescription{.{ .format = format }},
            .has_depth_stencil_target = true,
            .depth_stencil_format = sdl.SDL_GPU_TEXTUREFORMAT_D24_UNORM,
        },
        .primitive_type = sdl.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
        .vertex_shader = vertex_shader,
        .fragment_shader = fragment_shader,
        .vertex_input_state = .{
            .vertex_buffer_descriptions = &[_]sdl.SDL_GPUVertexBufferDescription{.{
                .slot = 0,
                .pitch = 8 * @sizeOf(f32),
                .input_rate = sdl.SDL_GPU_VERTEXINPUTRATE_VERTEX,
                .instance_step_rate = 0,
            }},
            .num_vertex_buffers = 1,
            .num_vertex_attributes = 3,
            .vertex_attributes = &[_]sdl.SDL_GPUVertexAttribute{
                .{ .location = 0, .buffer_slot = 0, .format = sdl.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, .offset = 0 },
                .{ .location = 1, .buffer_slot = 0, .format = sdl.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, .offset = 3 * @sizeOf(f32) },
                .{ .location = 2, .buffer_slot = 0, .format = sdl.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, .offset = 6 * @sizeOf(f32) },
            },
        },
        .rasterizer_state = .{
            .fill_mode = sdl.SDL_GPU_FILLMODE_FILL,
            .cull_mode = args.cullmode,
            .front_face = sdl.SDL_GPU_FRONTFACE_CLOCKWISE,
        },
        .depth_stencil_state = .{
            .enable_depth_test = true,
            .enable_depth_write = true,
            .compare_op = sdl.SDL_GPU_COMPAREOP_LESS,
            .enable_stencil_test = false,
        },
        .multisample_state = .{
            .sample_count = sdl.SDL_GPU_SAMPLECOUNT_1,
            .enable_mask = false,
        },
    };

    const pipeline = sdl.SDL_CreateGPUGraphicsPipeline(device, &pipe_info);
    if (pipeline == null) {
        return error.PipelineCreateFailed;
    }

    const white_tex = try createWhiteTexture(device);
    errdefer sdl.SDL_ReleaseGPUTexture(device, white_tex);

    return .{
        .color = .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 },
        .emissive = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
        .texture = args.albedo_texture orelse white_tex,
        .sampler = args.sampler,
        .vertex_shader = vertex_shader,
        .fragment_shader = fragment_shader,
        .pipeline = pipeline.?,
    };
}

pub fn createPBRMaterialWithTextures(
    device: *sdl.SDL_GPUDevice,
    format: sdl.SDL_GPUTextureFormat,
    albedo_path: [:0]const u8,
    metallic_path: [:0]const u8,
    roughness_path: [:0]const u8,
    ao_path: [:0]const u8,
) !struct { material: Material, albedo: *sdl.SDL_GPUTexture, metallic: *sdl.SDL_GPUTexture, roughness: *sdl.SDL_GPUTexture, ao: *sdl.SDL_GPUTexture } {
    const albedo_tex = try loadTexture(device, albedo_path);
    errdefer sdl.SDL_ReleaseGPUTexture(device, albedo_tex);

    const metallic_tex = try loadTexture(device, metallic_path);
    errdefer sdl.SDL_ReleaseGPUTexture(device, metallic_tex);

    const roughness_tex = try loadTexture(device, roughness_path);
    errdefer sdl.SDL_ReleaseGPUTexture(device, roughness_tex);

    const ao_tex = try loadTexture(device, ao_path);
    errdefer sdl.SDL_ReleaseGPUTexture(device, ao_tex);

    const sampler = try createDefaultSampler(device);
    errdefer sdl.SDL_ReleaseGPUSampler(device, sampler);

    const material = try createPBRMaterial(device, format, .{
        .albedo_texture = albedo_tex,
        .metallic_texture = metallic_tex,
        .roughness_texture = roughness_tex,
        .ao_texture = ao_tex,
        .sampler = sampler,
    });

    return .{
        .material = material,
        .albedo = albedo_tex,
        .metallic = metallic_tex,
        .roughness = roughness_tex,
        .ao = ao_tex,
    };
}
