package debug_draw

import "core:math"

// Adds a capsule to the debug draw batch
add_capsule :: proc(
	state: ^DebugDraw,
	x, y: f32, // Center position
	radius: f32, // Radius of semi-circles
	height: f32, // Height of rectangular part
	color: [4]f32 = {1, 1, 1, 1},
	segments := 16, // Number of segments for semi-circles (half of what's used for full circles)
) {
	// Calculate top and bottom centers of the semi-circles
	half_height := height / 2
	top_y := y + half_height
	bottom_y := y - half_height

	// Draw the rectangular part (4 lines)
	left_x := x - radius
	right_x := x + radius

	// Vertical lines
	add_vector(state, {left_x, bottom_y}, {left_x, top_y}, color)
	add_vector(state, {right_x, bottom_y}, {right_x, top_y}, color)

	// Draw top semi-circle
	angle_step := math.PI / f32(segments)
	for i := 0; i <= segments; i += 1 {
		angle := f32(i) * angle_step

		x1 := x + radius * math.cos(angle)
		y1 := top_y + radius * math.sin(angle)

		if i < segments {
			angle2 := f32(i + 1) * angle_step
			x2 := x + radius * math.cos(angle2)
			y2 := top_y + radius * math.sin(angle2)
			add_vector(state, {x1, y1}, {x2, y2}, color)
		}
	}

	// Draw bottom semi-circle
	for i := segments; i <= segments * 2; i += 1 {
		angle := f32(i) * angle_step

		x1 := x + radius * math.cos(angle)
		y1 := bottom_y + radius * math.sin(angle)

		if i < segments * 2 {
			angle2 := f32(i + 1) * angle_step
			x2 := x + radius * math.cos(angle2)
			y2 := bottom_y + radius * math.sin(angle2)
			add_vector(state, {x1, y1}, {x2, y2}, color)
		}
	}
}

