package game

import "logic"

sys_movement :: proc(w: ^World) {
	view := logic.view(&w.position, &w.velocity, &w.jump, &w.input)
	for id, pos, vel, jump, input in logic.each(&view) {
		was := vel.y
		update_movement_horizontal(vel, input)
		update_movement_vertical(vel, jump)

		if collider, ok := logic.get_component(&w.collider, id); ok {
			terrain_collision_collider_system(&w.grid, collider, pos, vel, jump)
		} else {
			terrain_collision_system(&w.grid, pos, vel, jump)
		}
		// if was == 0 && vel.y > 0 {
		// 	create_jump_dust_emitter(w, pos^)
		// 	//_ = create_jump_dust_emitter
		// }
		//
		// if was != 0 && vel.y == 0 {
		// 	create_landing_impact_emitter(w, pos^)
		// }
	}
}
