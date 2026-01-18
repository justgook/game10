@header package particles
@header import sg "../../sokol/gfx"
@ctype mat4 matrix[4,4]f32

//
// GPU Instanced Particle Shader
//
// Renders particles as textured quads with:
// - Position, scale, rotation
// - Color tint and alpha
// - UV coordinates for sprite atlas
//

@vs vs_particle
layout(binding=0) uniform vs_params {
    mat4 ortho;
};

// Base quad vertex (unit quad centered at origin)
in vec2 pos;

// Per-instance data
in vec2 inst_pos;       // World position
in vec2 inst_scale;     // Scale X, Y
in float inst_rotation; // Rotation in radians
in vec4 inst_color;     // RGBA color/tint
in vec4 inst_uv;        // UV rect: xy = min, zw = max
in vec2 inst_pivot;     // Pivot point (0-1)

out vec2 frag_uv;
out vec4 frag_color;

void main() {
    // Offset by pivot
    vec2 local_pos = pos - inst_pivot + vec2(0.5);
    
    // Apply scale
    local_pos *= inst_scale;
    
    // Apply rotation
    float c = cos(inst_rotation);
    float s = sin(inst_rotation);
    vec2 rotated = vec2(
        local_pos.x * c - local_pos.y * s,
        local_pos.x * s + local_pos.y * c
    );
    
    // Apply world position
    vec2 world_pos = rotated + inst_pos;
    
    gl_Position = ortho * vec4(world_pos, 0.0, 1.0);
    
    // Calculate UV from quad position
    vec2 uv_local = pos + vec2(0.5); // 0-1 range
    frag_uv = inst_uv.xy + uv_local * (inst_uv.zw - inst_uv.xy);
    
    frag_color = inst_color;
}
@end

@fs fs_particle
layout(binding=0) uniform texture2D tex0;
layout(binding=0) uniform sampler default_sampler;

in vec2 frag_uv;
in vec4 frag_color;

out vec4 out_color;

void main() {
    vec4 tex_color = texture(sampler2D(tex0, default_sampler), frag_uv);
    
    // Apply color tint and alpha
    out_color = tex_color * frag_color;
    
    // Discard fully transparent pixels
    if (out_color.a < 0.001) {
        discard;
    }
}
@end

@program particle vs_particle fs_particle
