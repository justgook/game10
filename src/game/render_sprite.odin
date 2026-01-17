package game

import "logic"

Sprite :: struct {
	uv:        [4]f32,
	offset:    [2]int,
	base_size: [2]f32,  // Base sprite size (before squash/stretch)
}

// Default sprite size if not specified
DEFAULT_SPRITE_SIZE :: [2]f32{18, 30}

render_sprite :: proc(w: ^World, r: ^Render) {
	view := logic.view(&w.position, &w.sprite)
	for id, pos, s in logic.each(&view) {
		target := &r.world_sprites.instances[r.world_sprites.count]
		r.world_sprites.count += 1
		target.uv = s.uv
		target.pos = to_pixelf(pos^ + s.offset)
		target.opacity = 1
		
		// Get base size (use default if not set)
		base_size := s.base_size
		if base_size.x == 0 && base_size.y == 0 {
			base_size = DEFAULT_SPRITE_SIZE
		}
		
		// Apply squash/stretch if component exists
		if squash, ok := logic.get_component(&w.squash, id); ok {
			target.size = squash_apply_to_size(squash, base_size)
		} else {
			target.size = base_size
		}
	}
}
