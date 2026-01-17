package game

import "camera"
import "core:math"
import "logic"

sys_movement :: proc(w: ^World) {
	view := logic.view(&w.position, &w.velocity, &w.jump, &w.input)
	for id, pos, vel, jump, input in logic.each(&view) {
		was_falling := vel.y < 0
		was_vel_y := vel.y
		was_grounded := jump.can_jump
		
		update_movement_horizontal(vel, input)
		update_movement_vertical(vel, jump)

		if collider, ok := logic.get_component(&w.collider, id); ok {
			terrain_collision_collider_system(&w.grid, collider, pos, vel, jump)
		} else {
			terrain_collision_system(&w.grid, pos, vel, jump)
		}

		// Detect landing - was falling and now grounded
		if was_falling && jump.can_jump && vel.y == 0 {
			// Calculate landing power based on fall velocity
			fall_speed := math.abs(f32(was_vel_y)) / f32(UNIT)
			
			// Only trigger effects for significant falls
			if fall_speed > 2.0 && id == w.player_entity {
				// Normalize power (0-1 range, capped)
				power := min(fall_speed / 10.0, 1.0)
				
				// Camera effects on landing
				camera.camera_bump(&w.cam, 0, 8 * power)
				camera.camera_shake(&w.cam, 0.5 * power, 1.5 * power, 0.3 * power)
				
				// Zoom bump for heavy landings
				if power > 0.5 {
					camera.camera_bump_zoom(&w.cam, 0.02 * power)
				}
				
				// Squash effect on landing
				if squash, ok := logic.get_component(&w.squash, id); ok {
					squash_on_land(squash, power)
				}
			}
		}
		
		// Detect jump start
		if !was_falling && vel.y > 0 && was_vel_y <= 0 {
			if id == w.player_entity {
				// Small camera bump on jump
				camera.camera_bump(&w.cam, 0, -3)
			}
			
			// Squash effect on jump (stretch vertically)
			if squash, ok := logic.get_component(&w.squash, id); ok {
				squash_on_jump(squash)
			}
		}
	}
}
