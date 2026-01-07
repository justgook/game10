package game

import "logic"
import "render/debug_draw"
import "shape"

Active_Hurt_Box :: struct {
	using _: shape.Capsule,
	iframes: struct {
		remaining: int,
	},
}

// when ODIN_DEBUG {
debug_state: struct {
	draw: debug_draw.DebugDraw,
}
// }

debug_frame :: proc(w: ^World, r: ^Render) {
	debug_draw.add_coordinate_system(&debug_state.draw, origin = {0, 0}, size = 16 * 20, grid_size = 16)


	player_hurd_debug := Active_Hurt_Box {
		y      = 14 * UNIT,
		radius = 7 * UNIT,
		height = 14 * UNIT,
	}
	aabb := transmute([4]int)shape.aabb(&player_hurd_debug)

	//fmt.println("AABB", aabb / UNIT)

	for &seg2 in w.segments {
		color := [4]f32{0, 0, 1, 1}
		//aabb := [4]int{-8, 0, 8, 20}
		//aabb *= UNIT
		// seg := shift_segment_by_aabb(&seg2, &aabb)
		seg := seg2
		debug_draw.add_vector_with_arrow(
			&debug_state.draw,
			{f32(to_pixel(seg.x)), f32(to_pixel(seg.y))},
			{f32(to_pixel(seg.z)), f32(to_pixel(seg.w))},
			color,
		)
	}

	enemy_hurt := logic.view(&w.position, &w.enemy_hurt)
	for _, pos, capsule in logic.each(&enemy_hurt) {
		debug_draw.add_capsule(
			&debug_state.draw,
			f32(to_pixel(pos.x + capsule.x)),
			f32(to_pixel(pos.y + capsule.y)),
			f32(to_pixel(capsule.radius)),
			f32(to_pixel(capsule.height)),
			color = [4]f32{1, 1, 0, 1},
		)
	}

	enemy_hit := logic.view(&w.position, &w.enemy_hit)
	for _, pos, circle in logic.each(&enemy_hit) {
		debug_draw.add_circle(
			&debug_state.draw,
			f32(to_pixel(pos.x + circle.x)),
			f32(to_pixel(pos.y + circle.y)),
			f32(to_pixel(circle.radius)),
			color = [4]f32{1, 0, 0, 1},
		)
	}

	player_hit := logic.view(&w.position, &w.player_hit)
	for _, pos, circle in logic.each(&player_hit) {
		debug_draw.add_circle(
			&debug_state.draw,
			f32(to_pixel(pos.x + circle.x)),
			f32(to_pixel(pos.y + circle.y)),
			f32(to_pixel(circle.radius)),
			color = [4]f32{1, 0, 1, 1},
		)
	}

	player_hurt := logic.view(&w.position, &w.player_hurt)
	for _, pos, capsule in logic.each(&player_hurt) {
		debug_draw.add_capsule(
			&debug_state.draw,
			f32(to_pixel(pos.x + capsule.x)),
			f32(to_pixel(pos.y + capsule.y)),
			f32(to_pixel(capsule.radius)),
			f32(to_pixel(capsule.height)),
			color = [4]f32{0, 1, 0, 1},
		)
	}

}
