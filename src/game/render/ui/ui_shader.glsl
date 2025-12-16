@header package ui
@header import sg "../../sokol/gfx"
// Vertex Shader
@vs microui_vs
layout(binding=0) uniform vs_params {
    vec2 screen_size;
};

// Base quad attributes
in vec2 position;   // Base corners of quad (-1,-1) to (1,1)

// Per-instance attributes
in vec2 i_position; // Screen position
in vec2 i_size;     // Width and height
in vec4 i_uv;       // Atlas coordinates (x, y, width, height)
in vec4 i_color;    // RGBA color normalized to 0-1
in vec4 i_clip;     // Clip rectangle (x, y, width, height)

out vec2 uv;
out vec4 color;

void main() {
// Calculate initial world position
    vec2 world_pos = position * i_size + i_position + (i_size * 0.5);
    vec2 quad_min = i_position;
    vec2 quad_max = i_position + i_size;

    // Calculate clipping bounds
    vec2 clip_min = i_clip.xy;
    vec2 clip_max = i_clip.xy + i_clip.zw;

    // Clamp quad bounds to clip rect
    vec2 clamped_min = max(quad_min, clip_min);
    vec2 clamped_max = min(quad_max, clip_max);

    // Calculate new size and position after clipping
    vec2 new_size = max(clamped_max - clamped_min, vec2(0.0));
    vec2 new_pos = (clamped_min + clamped_max) * 0.5; // Center of new quad

    // Calculate UV adjustment based on clipping
    vec2 uv_scale = new_size / i_size;
    vec2 uv_offset = (clamped_min - quad_min) / i_size;

    // Apply new position and size
    world_pos = position * new_size + new_pos;

    // Convert to NDC
    vec2 pos = (world_pos / screen_size) * 2.0 - 1.0;
    pos.y = -pos.y;
    gl_Position = vec4(pos, 0.0, 1.0);

    // Adjust UVs based on clipping
    vec2 base_uv = position + 0.5;
    vec2 scaled_uv = base_uv * uv_scale + uv_offset;
    uv = scaled_uv * vec2(i_uv.z, i_uv.w) + vec2(i_uv.x, i_uv.y);

    color = i_color;
}

@end

// Fragment Shader
@fs microui_fs
layout(binding=0) uniform texture2D atlas;
layout(binding=0) uniform sampler atlas_smp;

in vec2 uv;
in vec4 color;

out vec4 frag_color;

void main() {
    float alpha = texture(sampler2D(atlas, atlas_smp), uv).r;
    frag_color = color * vec4(1.0, 1.0, 1.0, alpha);
}
@end

@program microui microui_vs microui_fs
