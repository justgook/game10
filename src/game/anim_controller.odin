package game

// Animation Controller
//
// High-level state machine that switches animations based on entity state.
// Works with the Animation component - controller decides WHICH animation,
// Animation component handles playback.
//
// Usage:
//   // Define animation set for entity type
//   hero_anims := AnimSet{
//       idle      = &hero_idle_def,
//       run       = &hero_run_def,
//       jump_up   = &hero_jump_up_def,
//       jump_down = &hero_jump_down_def,
//       land      = &hero_land_def,
//   }
//
//   // Add controller to entity
//   logic.add_component(&w.anim_controller, player, anim_controller_create(&hero_anims))
//
// The sys_anim_controller checks entity state (velocity, grounded, etc.) and
// switches animations automatically based on priorities.

import "logic"

// Animation states
AnimState :: enum u8 {
	None,
	Idle,
	Run,
	Jump_Up,
	Jump_Down,
	Land,
	Dash,
	Hurt,
}

// Set of animations for an entity type
// Each pointer can be nil if that animation doesn't exist
AnimSet :: struct {
	idle:      ^AnimDef,
	run:       ^AnimDef,
	jump_up:   ^AnimDef,
	jump_down: ^AnimDef,
	land:      ^AnimDef,
	dash:      ^AnimDef,
	hurt:      ^AnimDef,
}

// Animation controller component
AnimController :: struct {
	anims:         ^AnimSet, // Pointer to animation set
	current_state: AnimState, // Current animation state
	facing:        int, // -1 = left, 1 = right (for flip)
	// Lock state (for non-interruptible animations like hurt/land)
	lock_timer:    f32, // Time remaining in lock (0 = not locked)
}

// Create a new animation controller
anim_controller_create :: proc(anims: ^AnimSet) -> AnimController {
	return AnimController{anims = anims, current_state = .None, facing = 1, lock_timer = 0}
}

// Get the AnimDef for a state from the set
animset_get :: proc(set: ^AnimSet, state: AnimState) -> ^AnimDef {
	if set == nil {
		return nil
	}
	switch state {
	case .Idle:
		return set.idle
	case .Run:
		return set.run
	case .Jump_Up:
		return set.jump_up
	case .Jump_Down:
		return set.jump_down
	case .Land:
		return set.land
	case .Dash:
		return set.dash
	case .Hurt:
		return set.hurt
	case .None:
		return nil
	}
	return nil
}

// Lock the controller for a duration (prevents state changes)
anim_controller_lock :: proc(ctrl: ^AnimController, duration: f32) {
	ctrl.lock_timer = duration
}

// Check if controller is locked
anim_controller_is_locked :: proc(ctrl: ^AnimController) -> bool {
	return ctrl.lock_timer > 0
}

// Force a state change (ignores lock)
anim_controller_force_state :: proc(ctrl: ^AnimController, state: AnimState) {
	ctrl.current_state = state
}

// Animation controller system
// Checks entity state and switches animations based on priorities
sys_anim_controller :: proc(w: ^World, dt: f32) {
	// View entities with controller, animation, velocity, and jump state
	// We need these to determine animation state
	view := logic.view(&w.anim_controller, &w.animation, &w.velocity, &w.jump)

	for id, ctrl, anim, vel, jump in logic.each(&view) {
		if ctrl.anims == nil {
			continue
		}

		// Update lock timer
		if ctrl.lock_timer > 0 {
			ctrl.lock_timer -= dt
			if ctrl.lock_timer < 0 {
				ctrl.lock_timer = 0
			}
		}

		// Update facing based on velocity
		if vel.x > 0 {
			ctrl.facing = 1
		} else if vel.x < 0 {
			ctrl.facing = -1
		}

		// Determine new state based on priorities (higher = more important)
		new_state := ctrl.current_state

		// Skip state determination if locked
		if !anim_controller_is_locked(ctrl) {
			// Priority 0: Idle (default)
			new_state = .Idle

			// Priority 1: Running (horizontal movement on ground)
			is_grounded := jump.can_jump // Using can_jump as grounded indicator
			if is_grounded && (vel.x != 0) {
				new_state = .Run
			}

			// Priority 2: Jumping/Falling
			if !is_grounded {
				if vel.y < 0 {
					new_state = .Jump_Up
				} else {
					new_state = .Jump_Down
				}
			}

			// Priority 3: Landing (brief animation after landing)
			// This would be triggered by movement system setting a flag
			// For now, handled via lock_timer when landing detected

			// Priority 4: Hurt (set externally via lock)
			// Handled by lock mechanism
		}

		// Apply state change
		if new_state != ctrl.current_state || anim.def == nil {
			ctrl.current_state = new_state
			new_def := animset_get(ctrl.anims, new_state)
			if new_def != nil {
				animation_play_if_different(anim, new_def)
			}
		}

		// Apply flip based on facing
		// Get the current animation's flip and combine with facing
		if anim.def != nil && len(anim.def.frames) > 0 {
			frame := &anim.def.frames[anim.frame_index]
			// If facing left, add FLIP_X to the frame's flip
			if ctrl.facing < 0 {
				// Combine frame flip with horizontal flip for facing
				if sprite, ok := logic.get_component(&w.sprite, id); ok {
					// XOR with FLIP_X to toggle horizontal flip based on facing
					sprite.flip = frame.flip ~ FLIP_X
				}
			}
		}
	}
}

// Helper to trigger land animation with lock
anim_controller_on_land :: proc(ctrl: ^AnimController, anim: ^Animation, power: f32) {
	if ctrl.anims == nil || ctrl.anims.land == nil {
		return
	}

	// Only play land animation for significant landings
	if power > 0.3 {
		ctrl.current_state = .Land
		animation_play(anim, ctrl.anims.land)
		// Lock for the duration of the animation
		lock_duration := animdef_total_duration(ctrl.anims.land)
		anim_controller_lock(ctrl, lock_duration * 0.8) // Slight overlap for smoothness
	}
}

// Helper to trigger hurt animation with lock
anim_controller_on_hurt :: proc(ctrl: ^AnimController, anim: ^Animation) {
	if ctrl.anims == nil || ctrl.anims.hurt == nil {
		return
	}

	ctrl.current_state = .Hurt
	animation_play(anim, ctrl.anims.hurt)
	lock_duration := animdef_total_duration(ctrl.anims.hurt)
	anim_controller_lock(ctrl, lock_duration)
}
