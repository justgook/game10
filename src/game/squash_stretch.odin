package game

import "core:math"

// Squash & Stretch Effect
//
// Makes entities feel alive and reactive by distorting their sprite
// in response to events like jumping, landing, dashing, or getting hit.
//
// The effect preserves volume: when X shrinks, Y grows (and vice versa).
// Values auto-recover to 1.0 each frame using friction.
//
// Usage:
//   squash_set(&entity.squash, 0.7, 1.3)  // Squash horizontally, stretch vertically
//   squash_set(&entity.squash, 1.3, 0.7)  // Stretch horizontally, squash vertically

// Configuration
SQUASH_RECOVERY_SPEED :: 0.15 // How fast to recover to normal (0-1, higher = faster)
SQUASH_MIN :: 0.5 // Minimum scale allowed
SQUASH_MAX :: 1.5 // Maximum scale allowed

// Squash & Stretch component
SquashStretch :: struct {
	scale_x:    f32, // Current X scale multiplier (1.0 = normal)
	scale_y:    f32, // Current Y scale multiplier (1.0 = normal)
	velocity_x: f32, // Velocity for smooth animation
	velocity_y: f32, // Velocity for smooth animation
}

// Initialize with default values
squash_init :: proc() -> SquashStretch {
	return SquashStretch{scale_x = 1.0, scale_y = 1.0}
}

// Set squash/stretch values directly
// Automatically clamps to min/max and preserves volume
squash_set :: proc(s: ^SquashStretch, scale_x, scale_y: f32) {
	s.scale_x = clamp(scale_x, SQUASH_MIN, SQUASH_MAX)
	s.scale_y = clamp(scale_y, SQUASH_MIN, SQUASH_MAX)
	s.velocity_x = 0
	s.velocity_y = 0
}

// Set squash with volume preservation
// If you squash X, Y automatically stretches to compensate
squash_set_preserve_volume :: proc(s: ^SquashStretch, scale_x: f32) {
	clamped_x := clamp(scale_x, SQUASH_MIN, SQUASH_MAX)
	// Preserve volume: area = x * y should stay constant
	// If x shrinks to 0.7, y should grow to 1/0.7 ≈ 1.43
	scale_y := 1.0 / clamped_x
	s.scale_x = clamped_x
	s.scale_y = clamp(scale_y, SQUASH_MIN, SQUASH_MAX)
	s.velocity_x = 0
	s.velocity_y = 0
}

// Apply squash effect for common events
squash_on_jump :: proc(s: ^SquashStretch) {
	// Stretch vertically when jumping (preparing to launch)
	squash_set(s, 0.8, 1.25)
}

squash_on_land :: proc(s: ^SquashStretch, power: f32 = 1.0) {
	// Squash vertically when landing (impact)
	// Power 0-1 controls intensity
	intensity := clamp(power, 0.0, 1.0)
	squash_x := 1.0 + 0.3 * intensity // Wider
	squash_y := 1.0 - 0.3 * intensity // Shorter
	squash_set(s, squash_x, squash_y)
}

squash_on_dash :: proc(s: ^SquashStretch, facing_right: bool) {
	// Stretch horizontally when dashing
	squash_set(s, 1.3, 0.8)
}

squash_on_hit :: proc(s: ^SquashStretch) {
	// Quick squash when hit
	squash_set(s, 0.7, 1.3)
}

squash_on_bounce :: proc(s: ^SquashStretch) {
	// Oscillating effect for bouncy objects
	squash_set(s, 1.2, 0.85)
}

// Update squash values - call every frame
// Returns true if still animating (not at rest)
squash_update :: proc(s: ^SquashStretch) -> bool {
	// Spring-like recovery to 1.0
	target_x: f32 = 1.0
	target_y: f32 = 1.0

	// Calculate spring force
	diff_x := target_x - s.scale_x
	diff_y := target_y - s.scale_y

	// Apply spring force to velocity
	s.velocity_x += diff_x * SQUASH_RECOVERY_SPEED
	s.velocity_y += diff_y * SQUASH_RECOVERY_SPEED

	// Apply damping
	s.velocity_x *= 0.8
	s.velocity_y *= 0.8

	// Apply velocity
	s.scale_x += s.velocity_x
	s.scale_y += s.velocity_y

	// Clamp values
	s.scale_x = clamp(s.scale_x, SQUASH_MIN, SQUASH_MAX)
	s.scale_y = clamp(s.scale_y, SQUASH_MIN, SQUASH_MAX)

	// Check if at rest (close enough to 1.0 and not moving)
	epsilon: f32 = 0.01
	at_rest :=
		math.abs(s.scale_x - 1.0) < epsilon &&
		math.abs(s.scale_y - 1.0) < epsilon &&
		math.abs(s.velocity_x) < epsilon &&
		math.abs(s.velocity_y) < epsilon

	if at_rest {
		s.scale_x = 1.0
		s.scale_y = 1.0
		s.velocity_x = 0
		s.velocity_y = 0
	}

	return !at_rest
}

// Get the current scale for rendering
squash_get_scale :: proc(s: ^SquashStretch) -> [2]f32 {
	return {s.scale_x, s.scale_y}
}

// Apply squash to a base size
squash_apply_to_size :: proc(s: ^SquashStretch, base_size: [2]f32) -> [2]f32 {
	return {base_size.x * s.scale_x, base_size.y * s.scale_y}
}
