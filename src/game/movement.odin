package game
import "grid"
import "shape"

// Movement constants
WALK_FORCE :: 12 // Force applied per tick when walking

// Friction values in percentages (how much velocity is retained)
// For example: 95 means keep 95% of velocity (5% friction)
FRICTION_PERCENT :: 95 // Base friction - retain 95% of velocity
NO_INPUT_FRICTION :: 85 // More friction when no input - retain 85%
BRAKE_FRICTION :: 80 // Even more friction when braking - retain 80%


/*
    Jump mechanics constants:
    - Initial burst of velocity when jump starts
    - Extra upward force while holding jump (for N frames)
    - Maximum frames you can hold jump for extra height
    - Different gravity values for:
        * Rising with jump held
        * Rising without jump held (cut jump short)
        * Falling with jump held (slow fall)
        * Falling without jump held (fast fall)
*/
JUMP_INITIAL_FORCE :: 3 * UNIT // Initial jump burst
JUMP_HOLD_FORCE :: UNIT / 2 // Extra force per frame while holding
MAX_JUMP_HOLD_FRAMES :: 10 // Maximum frames to apply extra force

GRAVITY_JUMP_HOLD :: -12 // Gravity while rising with jump held
GRAVITY_JUMP_RELEASE :: -32 // Gravity when jump released during rise
GRAVITY_FALL_SLOW :: -16 // Gravity while falling with jump held
GRAVITY_FALL_FAST :: -32 // Gravity while falling without jump held


// State needed for jump mechanics
JumpState :: struct {
	jump_hold_frames: int, // How many frames we've been holding jump
	was_jumping:      bool, // Was jump button held last frame
	is_rising:        bool, // Are we moving upward
	released_jump:    bool, // Have we released jump during this jump
	can_jump:         bool, // Are we allowed to jump (e.g., touching ground)
	facing_right:     bool,
	input:            bool,
}

update_movement_vertical :: proc(vel: ^[2]int, state: ^JumpState) {
	if vel[0] != 0 {
		state.facing_right = vel[0] > 0
	}

	// Start new jump
	if state.input && state.can_jump && !state.was_jumping {
		vel[1] = JUMP_INITIAL_FORCE
		state.jump_hold_frames = 0
		state.is_rising = true
		state.released_jump = false // Reset released state on new jump
	}

	// Track if jump was released
	if !state.input && state.was_jumping {
		state.released_jump = true
	}

	// Update rising/falling state
	state.is_rising = vel[1] > 0

	// Apply appropriate gravity based on state
	gravity := GRAVITY_FALL_FAST // Default to fast fall

	if state.is_rising {
		if state.input && !state.released_jump && state.jump_hold_frames < MAX_JUMP_HOLD_FRAMES {
			// Rising and holding jump (without having released) - add extra force
			vel[1] += JUMP_HOLD_FORCE
			gravity = GRAVITY_JUMP_HOLD
			state.jump_hold_frames += 1
		} else {
			// Either released jump or exceeded hold time
			gravity = GRAVITY_JUMP_RELEASE
		}
	} else if state.input {
		// Falling but holding jump for slow fall
		gravity = GRAVITY_FALL_SLOW
	}

	// Apply gravity
	vel[1] += gravity

	// Update jump button state
	state.was_jumping = state.input
}

// Keep horizontal movement in separate function
update_movement_horizontal :: proc(vel: ^[2]int, input: ^Input) {
	// Apply walk force
	vel[0] += int(input.x) * WALK_FORCE

	// Calculate friction percentage (how much velocity to keep)
	friction := FRICTION_PERCENT
	if input.x == 0 {
		// No input - higher friction
		friction = NO_INPUT_FRICTION
	} else if (input.x > 0 && vel[0] < 0) || (input.x < 0 && vel[0] > 0) {
		// Pressing opposite direction - highest friction
		friction = BRAKE_FRICTION
	}

	// Apply proportional friction
	vel[0] = vel[0] * friction / 100
}

terrain_collision_collider_system :: proc(
	g: ^grid.Grid,
	capsule: ^shape.Capsule,
	pos, vel: ^[2]int,
	state: ^JumpState,
) {
	movement := [4]int{pos.x, pos.y, pos.x + vel.x, pos.y + vel.y}
	state.can_jump = false
	collider := transmute([4]int)shape.aabb(capsule)

	// Vertical collision test
	{
		test := movement
		test.z = test.x // Keep x position constant for vertical test

		found := capsule_swept_query(g, pos, vel, capsule)
		defer delete(found)

		for &wall_before in found {
			wall := shift_segment_by_aabb(wall_before, &collider)
			if check_side(&wall, movement.xy) {continue}
			point := shape.segment_segment_solve(&test, &wall) or_continue

			movement.w = vel.y > 0 ? min(point.y - 1, movement.w) : max(point.y + 1, movement.w)
			state.can_jump = true
			vel.y = 0
		}
	}

	// Horizontal collision test
	{
		test := movement
		test.w = test.y // Keep y position constant for horizontal test

		found := capsule_swept_query(g, pos, vel, capsule)
		defer delete(found)

		for &wall_before in found {
			wall := shift_segment_by_aabb(wall_before, &collider)
			if check_side(&wall, movement.xy) {continue}
			point := shape.segment_segment_solve(&test, &wall) or_continue

			movement.z = vel.x > 0 ? min(point.x - 1, movement.z) : max(point.x + 1, movement.z)
			vel.x = 0
		}
	}

	vel.x = movement.z - pos.x
	vel.y = movement.w - pos.y
}


terrain_collision_system :: proc(g: ^grid.Grid, pos, vel: ^[2]int, state: ^JumpState) {
	movement := [4]int{pos.x, pos.y, pos.x + vel.x, pos.y + vel.y}
	state.can_jump = false
	// Vertical collision test
	{
		test := movement
		test.z = test.x // Keep x position constant for vertical test

		found := grid.query_segment(g, &test)
		defer delete(found)

		for wall in found {
			if check_side(wall, movement.xy) {continue}
			point := shape.segment_segment_solve(&test, wall) or_continue

			movement.w = vel.y > 0 ? min(point.y - 1, movement.w) : max(point.y + 1, movement.w)
			state.can_jump = true
			vel.y = 0
		}
	}

	// Horizontal collision test
	{
		test := movement
		test.w = test.y // Keep y position constant for horizontal test

		found := grid.query_segment(g, &test)
		defer delete(found)
		for wall in found {
			if check_side(wall, movement.xy) {continue}
			point := shape.segment_segment_solve(&test, wall) or_continue

			movement.z = vel.x > 0 ? min(point.x - 1, movement.z) : max(point.x + 1, movement.z)
			vel.x = 0
		}
	}

	//pos.x = movement.z
	//pos.y = movement.w
	vel.x = movement.z - pos.x
	vel.y = movement.w - pos.y
}

@(private = "file")
check_side :: proc(wall: ^[4]int, test: [2]int) -> bool {
	return shape.ccw(wall.x, wall.y, wall.z, wall.w, test.x, test.y) <= 0
}


@(private = "file")
capsule_swept_query :: proc(g: ^grid.Grid, pos, vel: ^[2]int, capsule: ^shape.Capsule) -> [dynamic]^[4]int {
	half_height := capsule.height / 2
	radius := capsule.radius

	// Start position of capsule in world space
	start_x := pos.x + capsule.x
	start_y := pos.y + capsule.y

	// End position of capsule in world space
	end_x := start_x + vel.x
	end_y := start_y + vel.y

	// Calculate the bounding box for the swept capsule
	min_x := min(start_x, end_x) - radius
	min_y := min(start_y, end_y) - half_height - radius
	max_x := max(start_x, end_x) + radius
	max_y := max(start_y, end_y) + half_height + radius

	return grid.query_aabb(g, &[4]int{min_x, min_y, max_x, max_y})
}

shift_segment_by_aabb :: proc(wall: ^[4]int, aabb: ^[4]int) -> [4]int {
	is_horizontal := abs(wall[3] - wall[1]) < abs(wall[2] - wall[0])
	is_left := wall[1] < wall[3]
	is_bottom := wall[0] > wall[2]

	if is_horizontal && !is_bottom {
		return shift_segment_by_aabb_top(wall, aabb)
	}
	if !is_horizontal && !is_left {
		return shift_segment_by_aabb_right(wall, aabb)
	}
	if is_horizontal && is_bottom {
		return shift_segment_by_aabb_bottom(wall, aabb)
	}
	if !is_horizontal && is_left {
		return shift_segment_by_aabb_left(wall, aabb)
	}

	return wall^
}

@(private = "file")
shift_segment_by_aabb_top :: proc(wall: ^[4]int, aabb: ^[4]int) -> [4]int {
	//TODO: add missing offset when aabb.y != 0
	// goes right
	output := wall^
	output.z -= aabb.x
	output.x -= aabb.z

	return output
}

@(private = "file")
shift_segment_by_aabb_right :: proc(wall: ^[4]int, aabb: ^[4]int) -> [4]int {
	// Goes down
	output := wall^
	output.w -= aabb.w
	output.xz -= aabb.x
	return output
}

@(private = "file")
shift_segment_by_aabb_bottom :: proc(wall: ^[4]int, aabb: ^[4]int) -> [4]int {
	// goes left
	output := wall^
	output.yw -= aabb.w
	output.x -= aabb.x
	output.z -= aabb.z
	return output
}

@(private = "file")
shift_segment_by_aabb_left :: proc(wall: ^[4]int, aabb: ^[4]int) -> [4]int {
	// Goes up
	output := wall^
	output.xz -= aabb.z
	output.y -= aabb.w
	return output
}
