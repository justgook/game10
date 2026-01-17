package game

import "logic"
import sapp "sokol/app"

Sprite :: struct {
	uv:        [4]f32,
	offset:    [2]int,
	base_size: [2]f32,  // Base sprite size (before squash/stretch)
}

// Default sprite size if not specified
DEFAULT_SPRITE_SIZE :: [2]f32{18, 30}

render_sprite :: proc(w: ^World, r: ^Render) {
	// Get current time for shake animation
	// Using frame time accumulator for consistent animation
	@(static) frame_time: f32 = 0
	frame_time += f32(sapp.frame_duration())
	
	view := logic.view(&w.position, &w.sprite)
	for id, pos, s in logic.each(&view) {
		target := &r.world_sprites.instances[r.world_sprites.count]
		r.world_sprites.count += 1
		target.uv = s.uv
		target.pos = to_pixelf(pos^ + s.offset)
		target.opacity = 1
		
		// Apply sprite shake offset if component exists
		if shake, ok := logic.get_component(&w.sprite_shake, id); ok {
			offset := sprite_shake_get_offset(shake, frame_time)
			target.pos += offset
		}
		
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
		
		// Apply blink color if component exists
		if blink, ok := logic.get_component(&w.blink, id); ok {
			target.color_add = blink_get_color_add(blink)
		} else {
			target.color_add = {0, 0, 0, 0}
		}
	}
}
