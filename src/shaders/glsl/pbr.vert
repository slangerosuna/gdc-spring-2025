#version 450

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aTexCoord;

layout(location = 0) out vec3 WorldPos;
layout(location = 1) out vec3 Normal;
layout(location = 2) out vec2 TexCoord;

layout(std140, set = 1, binding = 0) uniform FrameUBO {
    mat4 view;
    mat4 projection;
} frame_ubo;

layout(std140, set = 1, binding = 1) uniform ObjectUBO {
    mat4 model;
    vec4 color;
} object_ubo;

void main() {
    vec4 worldPos = object_ubo.model * vec4(aPos, 1.0);
    WorldPos = worldPos.xyz;
    gl_Position = frame_ubo.projection * frame_ubo.view * worldPos;
    Normal = normalize(mat3(transpose(inverse(object_ubo.model))) * aNormal);
    TexCoord = aTexCoord;
}
