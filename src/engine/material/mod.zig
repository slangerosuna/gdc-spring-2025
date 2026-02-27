pub const loadShader = @import("common.zig").loadShader;
pub const loadShaderFromBytes = @import("common.zig").loadShaderFromBytes;
pub const loadTexture = @import("common.zig").loadTexture;
pub const createWhiteTexture = @import("common.zig").createWhiteTexture;
pub const createDefaultSampler = @import("common.zig").createDefaultSampler;

pub const createBasicMaterial = @import("basic.zig").createBasicMaterial;
pub const BasicMaterialArgs = @import("basic.zig").BasicMaterialArgs;
pub const basic_material_vert_spv = @import("basic.zig").basic_material_vert_spv;
pub const basic_material_frag_spv = @import("basic.zig").basic_material_frag_spv;

pub const createPhongMaterial = @import("phong.zig").createPhongMaterial;
pub const PhongMaterialArgs = @import("phong.zig").PhongMaterialArgs;
pub const phong_material_vert_spv = @import("phong.zig").phong_material_vert_spv;
pub const phong_material_frag_spv = @import("phong.zig").phong_material_frag_spv;

pub const createPBRMaterial = @import("pbr.zig").createPBRMaterial;
pub const createPBRMaterialWithTextures = @import("pbr.zig").createPBRMaterialWithTextures;
pub const PBRMaterialArgs = @import("pbr.zig").PBRMaterialArgs;
pub const pbr_vert_spv = @import("pbr.zig").pbr_vert_spv;
pub const pbr_frag_spv = @import("pbr.zig").pbr_frag_spv;
