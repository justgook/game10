package game

// Platformer Animation Controller
//
// High-level state machine that switches animations based on entity state.
// Designed for 2D platformer games with left/right directional animations.
// Works with the Animation component - controller decides WHICH animation,
// Animation component handles playback.
//
// Usage:
//   // Define animation set for entity type (with directional support)
//   hero_anims := AnimSetPlatformer{
//       idle      = {.Right = &hero_idle_right_def, .Left = &hero_idle_left_def},
//       run       = {.Right = &hero_run_right_def,  .Left = &hero_run_left_def},
//       jump_up   = {.Right = &hero_jump_up_right_def, .Left = &hero_jump_up_left_def},
//       // ...
//   }
//
//   // Add controller to entity
//   logic.add_component(&w.anim_controller, player, anim_controller_create(&hero_anims))
//
// The sys_anim_controller checks entity state (velocity, grounded, etc.) and
// switches animations automatically based on priorities and facing direction.

import "logic"

// Direction for platformer animations (left/right)
Direction :: enum u8 {
	Right = 0, // Default direction
	Left  = 1,
}

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

// Set of directional animations for a platformer entity type
// Each animation has variants for left and right facing
// Pointers can be nil if that animation doesn't exist for a direction
AnimSetPlatformer :: struct {
	idle:      [Direction]^AnimDef,
	run:       [Direction]^AnimDef,
	jump_up:   [Direction]^AnimDef,
	jump_down: [Direction]^AnimDef,
	land:      [Direction]^AnimDef,
	dash:      [Direction]^AnimDef,
	hurt:      [Direction]^AnimDef,
}

// Platformer animation controller component
AnimControllerPlatformer :: struct {
	anims:         ^AnimSetPlatformer, // Pointer to animation set
	current_state: AnimState, // Current animation state
	facing:        Direction, // Current facing direction
	// Lock state (for non-interruptible animations like hurt/land)
	lock_timer:    f32, // Time remaining in lock (0 = not locked)
}

// Create a new platformer animation controller
anim_controller_create :: proc(anims: ^AnimSetPlatformer) -> AnimControllerPlatformer {
	return AnimControllerPlatformer{anims = anims, current_state = .None, facing = .Right, lock_timer = 0}
}

// Get the AnimDef for a state and direction from the set
animset_get :: proc(set: ^AnimSetPlatformer, state: AnimState, dir: Direction) -> ^AnimDef {
	if set == nil {
		return nil
	}
	switch state {
	case .Idle:
		return set.idle[dir]
	case .Run:
		return set.run[dir]
	case .Jump_Up:
		return set.jump_up[dir]
	case .Jump_Down:
		return set.jump_down[dir]
	case .Land:
		return set.land[dir]
	case .Dash:
		return set.dash[dir]
	case .Hurt:
		return set.hurt[dir]
	case .None:
		return nil
	}
	return nil
}

// Lock the controller for a duration (prevents state changes)
anim_controller_lock :: proc(ctrl: ^AnimControllerPlatformer, duration: f32) {
	ctrl.lock_timer = duration
}

// Check if controller is locked
anim_controller_is_locked :: proc(ctrl: ^AnimControllerPlatformer) -> bool {
	return ctrl.lock_timer > 0
}

// Force a state change (ignores lock)
anim_controller_force_state :: proc(ctrl: ^AnimControllerPlatformer, state: AnimState) {
	ctrl.current_state = state
}

// Platformer animation controller system
// Checks entity state and switches animations based on priorities and facing direction
sys_anim_controller :: proc(w: ^World, dt: f32) {
	// View entities with controller, animation, velocity, and jump state
	// We need these to determine animation state
	view := logic.view(&w.anim_controller, &w.animation, &w.velocity, &w.jump)

	for id, ctrl, anim, vel, jump in logic.each(&view) {
		_ = id // Unused for now since we use directional animations instead of flip
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

		// Update facing direction based on velocity
		if vel.x > 0 {
			ctrl.facing = .Right
		} else if vel.x < 0 {
			ctrl.facing = .Left
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

		// Apply state change or direction change
		// Need to switch animation if state changed OR if direction changed
		new_def := animset_get(ctrl.anims, new_state, ctrl.facing)
		if new_state != ctrl.current_state || anim.def != new_def {
			ctrl.current_state = new_state
			if new_def != nil {
				animation_play_if_different(anim, new_def)
			}
		}
	}
}

// Helper to trigger land animation with lock
anim_controller_on_land :: proc(atlas: ^AnimationAtlas, ctrl: ^AnimControllerPlatformer, anim: ^Animation, power: f32) {
	if ctrl.anims == nil {
		return
	}
	land_def := ctrl.anims.land[ctrl.facing]
	if land_def == nil {
		return
	}

	// Only play land animation for significant landings
	if power > 0.3 {
		ctrl.current_state = .Land
		animation_play(anim, land_def)
		// Lock for the duration of the animation
		lock_duration := animdef_total_duration(atlas, land_def)
		anim_controller_lock(ctrl, lock_duration * 0.8) // Slight overlap for smoothness
	}
}

// Helper to trigger hurt animation with lock
anim_controller_on_hurt :: proc(atlas: ^AnimationAtlas, ctrl: ^AnimControllerPlatformer, anim: ^Animation) {
	if ctrl.anims == nil {
		return
	}
	hurt_def := ctrl.anims.hurt[ctrl.facing]
	if hurt_def == nil {
		return
	}

	ctrl.current_state = .Hurt
	animation_play(anim, hurt_def)
	lock_duration := animdef_total_duration(atlas, hurt_def)
	anim_controller_lock(ctrl, lock_duration)
}
