package game

import "logic"

Sprite :: struct {
	uv:     [4]f32,
	offset: [2]int,
}

render_sprite :: proc(w: ^World, r: ^Render) {
	view := logic.view(&w.position, &w.sprite)
	for _, pos, s in logic.each(&view) {
		target := &r.world_sprites.instances[r.world_sprites.count]
		r.world_sprites.count += 1
		target.uv = s.uv
		target.pos = to_pixelf(pos^ + s.offset)
		target.opacity = 1
		target.size = {18 * 10, 30 * 10}
	}
}
