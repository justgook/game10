package game

import "camera"
import "core:fmt"
import "grid"
import "logic"
import "shape"

// Weapon/Trigger System
//
// Handles weapon firing with cooldowns and state management.
// Based on the odin-game reference implementation but simplified.

// Trigger state tracks button state and cooldown
Trigger_State :: struct {
	is_active:     bool, // Is the trigger button held
	just_pressed:  bool, // Was the trigger pressed this frame
	just_released: bool, // Was the trigger released this frame
	cooldown:      int, // Frames until can fire again
}

// Trigger component - attached to entities that can shoot
Trigger :: struct {
	state:         Trigger_State,
	fire_cooldown: int, // Frames between shots
	fire_proc:     proc(w: ^World, entity: int), // What happens when we fire
}

// Create a basic gun trigger
trigger_init_gun :: proc() -> Trigger {
	return Trigger {
		fire_cooldown = 10, // ~6 shots per second at 60fps
		fire_proc     = fire_bullet,
	}
}

// System that processes all triggers
sys_trigger :: proc(w: ^World) {
	view := logic.view(&w.trigger)
	for entity, trigger in logic.each(&view) {
		update_trigger(w, entity, trigger)
	}
}

@(private = "file")
update_trigger :: proc(w: ^World, entity: int, trigger: ^Trigger) {
	state := &trigger.state

	// Decrement cooldown
	if state.cooldown > 0 {
		state.cooldown -= 1
	}

	// Check if we should fire
	if state.is_active && state.cooldown <= 0 {
		// Reset cooldown
		state.cooldown = trigger.fire_cooldown

		// Fire!
		if trigger.fire_proc != nil {
			trigger.fire_proc(w, entity)
		}
	}
}

// =============================================================================
// FIRE PROCEDURES - What happens when weapons fire
// =============================================================================

// Fire a bullet from the entity
fire_bullet :: proc(w: ^World, entity: int) {
	pos, pos_ok := logic.get_component(&w.position, entity)
	jump, jump_ok := logic.get_component(&w.jump, entity)

	if !pos_ok {
		return
	}

	// Determine facing direction
	facing_right := true
	if jump_ok {
		facing_right = jump.facing_right
	}

	// Create bullet entity
	bullet := create_entity(w)

	// Position bullet at shooter's hands (Y+ is UP, so add to go up from feet)
	// Hands are roughly at Y + 12 units from feet
	bullet_offset_x := 10 * UNIT * (facing_right ? 1 : -1)
	bullet_offset_y := 12 * UNIT // Up from feet to hands
	logic.add_component(&w.position, bullet, Position{pos.x + bullet_offset_x, pos.y + bullet_offset_y})

	// Bullet velocity
	bullet_speed := 12 * UNIT
	logic.add_component(&w.velocity, bullet, Velocity{bullet_speed * (facing_right ? 1 : -1), 0})

	// Bullet hit box (circle)
	logic.add_component(&w.player_hit, bullet, shape.Circle{y = 0, radius = 4 * UNIT})

	// On hit callback - what happens when bullet hits something
	logic.add_component(&w.on_hit, bullet, on_hit_fn[.Bullet])

	// Timer to auto-delete bullet after 2 seconds
	timer := timer_create(120, bullet_timeout)
	timer.delete_on_complete = true
	logic.add_component(&w.timer, bullet, timer)

	// === GAME FEEL EFFECTS ===

	// Get pixel position for effects (at hand height)
	pixel_pos := to_pixelf(pos^)
	hand_y := pixel_pos.y + 12 // Hand height in pixels
	dir: f32 = facing_right ? 0.0 : 3.14159

	// Muzzle flash particles at hand position
	fx_gun_shot(&w.particles, pixel_pos.x, hand_y, dir)

	// Cartridge ejection at hand position
	fx_cartridge(&w.particles, pixel_pos.x, hand_y, dir)

	// Screen flash (subtle yellow)
	screen_flash_shoot(&w.screen_flash)

	// Camera bump (recoil feel)
	bump_x: f32 = facing_right ? -2.0 : 2.0
	camera.camera_bump(&w.cam, bump_x, 0)

	// Small camera shake
	camera.camera_shake(&w.cam, 1.0, 0.5, 0.05)

	// Squash the shooter (recoil)
	if squash, ok := logic.get_component(&w.squash, entity); ok {
		squash_on_dash(squash, facing_right) // Horizontal stretch
	}
}

// Bullet timeout callback - just marks for deletion
bullet_timeout :: proc(w: ^World, entity: int, data: rawptr) {
	// Timer has delete_on_complete = true, so entity will be deleted
	// We could spawn fade-out particles here if desired
}

// =============================================================================
// BULLET COLLISION SYSTEM
// =============================================================================

// System to check bullet collisions with walls
// Bullets are identified by having player_hit but no collider
sys_bullet_collision :: proc(w: ^World) {
	// View bullets: entities with player_hit, position, velocity (but no collider)
	view := logic.view(&w.player_hit, &w.position, &w.velocity)

	// Collect bullets to delete (can't delete during iteration)
	bullets_to_delete: [dynamic]int
	defer delete(bullets_to_delete)

	for entity, hit_circle, pos, vel in logic.each(&view) {
		// Skip if this entity has a collider (it's not a bullet, it's a character)
		if _, has_collider := logic.get_component(&w.collider, entity); has_collider {
			continue
		}

		// Check if bullet path intersects any wall
		movement := [4]int{pos.x, pos.y, pos.x + vel.x, pos.y + vel.y}

		found := grid.query_segment(&w.grid, &movement)
		defer delete(found)

		for wall in found {
			if shape.segment_segment_test(wall, &movement) {
				// Hit a wall! Spawn impact effect and mark for deletion
				pixel_pos := to_pixelf(pos^)

				// Direction for particles (opposite of bullet travel)
				dir: f32 = vel.x > 0 ? 3.14159 : 0.0
				fx_hit_wall(&w.particles, pixel_pos.x, pixel_pos.y, dir)

				append(&bullets_to_delete, entity)
				break
			}
		}
	}

	// Delete bullets that hit walls
	for bullet in bullets_to_delete {
		entity_delete(w, bullet)
	}
}

// =============================================================================
// INPUT HELPERS
// =============================================================================

// Update trigger state from input (call this from input handling)
trigger_set_active :: proc(trigger: ^Trigger, active: bool) {
	state := &trigger.state

	// Track just_pressed/just_released
	state.just_pressed = active && !state.is_active
	state.just_released = !active && state.is_active

	state.is_active = active
}
