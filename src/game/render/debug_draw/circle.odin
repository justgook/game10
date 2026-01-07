package debug_draw

import "core:math"

// Adds a circle to the debug draw batch
add_circle :: proc(
	state: ^DebugDraw,
	x, y, radius: f32,
	color: [4]f32 = {1, 1, 1, 1},
	segments := 32,
) {
	// Calculate the angle step based on number of segments
	angle_step := 2.0 * math.PI / f32(segments)

	// Generate points around the circle
	for i := 0; i < segments; i += 1 {
		angle1 := f32(i) * angle_step
		angle2 := f32(i + 1) * angle_step

		// Calculate points
		x1 := x + radius * math.cos(angle1)
		y1 := y + radius * math.sin(angle1)
		x2 := x + radius * math.cos(angle2)
		y2 := y + radius * math.sin(angle2)

		// Add line segment
		add_vector(state, {x1, y1}, {x2, y2}, color)
	}
}
