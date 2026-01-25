package game

// Sprite Atlas
//
// Stores all UV coordinates in a single slice. Animation frames reference UVs by index,
// allowing reuse of the same UV across multiple animations/frames without duplication.
//
// Usage:
//   // Define UV atlas (loaded from binary or defined in code)
//   atlas := SpriteAtlas{
//       uvs = []UV{
//           {0.0, 0.0, 0.1, 0.1},   // Index 0: idle frame 1
//           {0.1, 0.0, 0.2, 0.1},   // Index 1: idle frame 2
//           {0.2, 0.0, 0.3, 0.1},   // Index 2: run frame 1 (can also be idle frame 3)
//           ...
//       },
//   }
//
//   // Animation frames reference by index
//   idle_frames := []AnimFrame{
//       {uv_index = 0, duration = 0.5},
//       {uv_index = 1, duration = 0.5},
//   }

// UV coordinates (min_u, min_v, max_u, max_v)
UV :: [4]f32

// Sprite atlas - single storage for all UV coordinates
SpriteAtlas :: struct {
	uvs: []UV,
}

// Get UV by index, returns zero UV if out of bounds
atlas_get_uv :: proc(atlas: ^SpriteAtlas, index: int) -> UV {
	if atlas == nil || index < 0 || index >= len(atlas.uvs) {
		return UV{0, 0, 0, 0}
	}
	return atlas.uvs[index]
}

// Helper to create UV from pixel coordinates and atlas size
uv_from_pixels :: proc(x, y, w, h: int, atlas_width, atlas_height: int) -> UV {
	aw := f32(atlas_width)
	ah := f32(atlas_height)
	return UV{
		f32(x) / aw,
		f32(y) / ah,
		f32(x + w) / aw,
		f32(y + h) / ah,
	}
}

// Helper to create UV from tile coordinates (for grid-based atlases)
uv_from_tile :: proc(tile_x, tile_y: int, tile_width, tile_height: int, atlas_width, atlas_height: int) -> UV {
	return uv_from_pixels(
		tile_x * tile_width,
		tile_y * tile_height,
		tile_width,
		tile_height,
		atlas_width,
		atlas_height,
	)
}
