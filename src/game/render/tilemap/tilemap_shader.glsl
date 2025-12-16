@header package tilemap
@header import sg "../../sokol/gfx"
@ctype mat4 matrix[4,4]f32

@vs tilemap_vs
layout(binding=0) uniform vs_params {
    mat4 ortho;
    vec2 atlas_size;
};

// Base quad attributes
in vec2 position;   // Base corners of quad (-0.5,-0.5) to (0.5,0.5)

// Per-instance attributes
in vec2 i_position;     // Screen position
in vec2 i_tile_size;    // Size of a single tile
in vec4 i_tileset_uv;   // UV coordinates for tileset region
in vec4 i_tilemap_uv;   // UV coordinates for tilemap LUT region

out vec2 uv;
out vec2 tile_size;
out vec4 tileset_uv;
out vec4 tilemap_uv;
out vec2 tilemap_size;
out vec2 tileset_size;
out vec2 atlas_size2;

void main() {
    // Calculate sizes
    tilemap_size = (i_tilemap_uv.zw - i_tilemap_uv.xy) * atlas_size;
    tileset_size = (i_tileset_uv.zw - i_tileset_uv.xy) * atlas_size;


    // Calculate world position
    vec2 world_pos = (position + vec2(0.5)) * tilemap_size * i_tile_size + i_position;

    // Convert to clip space
    gl_Position = ortho * vec4(world_pos, 0.0, 1.0);

    uv = position + vec2(0.5);
    tile_size = i_tile_size;
    tileset_uv = i_tileset_uv;
    tilemap_uv = i_tilemap_uv;
    atlas_size2 = atlas_size;
}
@end

@fs tilemap_fs
layout(binding=0) uniform texture2D atlas;    // Atlas texture containing both tileset and LUT
layout(binding=0) uniform sampler smp;        // Sampler

in vec2 uv;
in vec2 tile_size;
in vec4 tileset_uv;
in vec4 tilemap_uv;
in vec2 tilemap_size;
in vec2 tileset_size;
in vec2 atlas_size2;

out vec4 frag_color;

float color2float(vec4 color) {
//    return color.a * 255.0 + color.b * 256.0 * 255.0 + color.g * 256.0 * 256.0 * 255.0 + color.r * 256.0 * 256.0 * 256.0 * 255.0;
    return color.a * 255.0 + color.b * 65280.0 + color.g * 16711680.0 + color.r * 4278190080.0;
}

void main() {
    //(2i + 1)/(2N) Pixel center
    vec2 coordinate = (floor(uv * tilemap_size) + 0.5) / atlas_size2+tilemap_uv.xy ;
    vec4 lut_color = texture(sampler2D(atlas, smp), coordinate);
    float index = color2float(lut_color);
    // vec2 map_coord = tilemap_uv.xy + (uv * tilemap_size) / atlas_size2;
    // float index = color2float(texture(sampler2D(atlas, smp), map_coord));

    if (index <= 0.0) discard;

      // Convert index to tileset coordinates
    vec2 tiles_per_row = floor(tileset_size / tile_size);
    vec2 tile;
    tile.x = mod(index - 1.0, tiles_per_row.x);
    tile.y = tiles_per_row.y - 1.0 - floor((index - 1.0) / tiles_per_row.x);

    vec2 tile_offset = floor(fract(uv * tilemap_size) * tile_size);
    //(2i + 1)/(2N) Pixel center
    vec2 pixel =  tileset_uv.xy + (floor(tile * tile_size + tile_offset) + 0.5) / atlas_size2;

    frag_color = texture(sampler2D(atlas, smp), pixel);
}
@end
@program tilemap tilemap_vs tilemap_fs
