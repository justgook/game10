@header package screen_flash
@header import sg "../../sokol/gfx"

@ctype vec4 [4]f32

//
// Simple fullscreen quad shader for screen flash effect.
// Uses a fullscreen triangle trick - no vertex buffer needed.
// Pass color via uniform, alpha controls intensity.
//

@vs vs
// Fullscreen triangle - generates positions from vertex ID
// No input attributes needed
out vec2 uv;

void main() {
    // Generate fullscreen triangle from vertex ID (0, 1, 2)
    // This creates a triangle that covers the entire screen
    vec2 pos = vec2(
        float((gl_VertexIndex << 1) & 2) * 2.0 - 1.0,
        float(gl_VertexIndex & 2) * 2.0 - 1.0
    );
    gl_Position = vec4(pos, 0.0, 1.0);
    uv = pos * 0.5 + 0.5;
}
@end

@fs fs
layout(binding=0) uniform fs_params {
    vec4 flash_color;  // RGB + Alpha
};

in vec2 uv;
out vec4 frag_color;

void main() {
    // Output color with alpha for blending
    frag_color = flash_color;
}
@end

@program screen_flash vs fs
