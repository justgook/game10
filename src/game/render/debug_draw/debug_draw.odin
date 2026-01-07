package debug_draw

import sg "../../sokol/gfx"
import "core:math"
import "core:math/linalg"


Vertex :: struct {
	pos:   [2]f32,
	color: [4]f32,
}

DebugDraw :: struct {
	pip:           sg.Pipeline,
	bind:          sg.Bindings,
	vertex_buffer: sg.Buffer,
	// Buffer for batch drawing
	vertices:      [dynamic]Vertex,
}

init_debug_draw :: proc() -> (dd: DebugDraw) {
	dd = DebugDraw{}

	// Pipeline setup matching our shader
	pip_desc := sg.Pipeline_Desc {
		shader = sg.make_shader(vector_shader_desc(sg.query_backend())),
		primitive_type = .LINES,
		layout = {
			attrs = {
				0 = {format = .FLOAT2}, // position
				1 = {format = .FLOAT4}, // color
			},
		},
	}
	dd.pip = sg.make_pipeline(pip_desc)

	// Create vertex buffer for batching
	dd.vertices = make([dynamic]Vertex, 0, 1024) // Initial capacity for 512 lines

	return dd
}

destroy_debug_draw :: proc(dd: ^DebugDraw) {
	delete(dd.vertices)
	//free(dd)
}

add_vector :: proc(state: ^DebugDraw, start, end: [2]f32, color: [4]f32) {
	append(&state.vertices, Vertex{pos = start, color = color})
	append(&state.vertices, Vertex{pos = end, color = color})
}

draw :: proc(state: ^DebugDraw, ortho: ^linalg.Matrix4f32) {
	if len(state.vertices) == 0 {return}

	vs_params := Vs_Params {
		ortho = ortho^,
	}

	// Update buffer with batched vertices
	vbuf_desc := sg.Buffer_Desc {
		data = sg.Range{ptr = raw_data(state.vertices[:]), size = len(state.vertices) * size_of(Vertex)},
	}

	if state.vertex_buffer.id != 0 {
		sg.destroy_buffer(state.vertex_buffer)
	}
	state.vertex_buffer = sg.make_buffer(vbuf_desc)
	state.bind.vertex_buffers[0] = state.vertex_buffer

	// Draw all vectors in one batch
	sg.apply_pipeline(state.pip)
	sg.apply_bindings(state.bind)
	sg.apply_uniforms(UB_vs_params, {ptr = &vs_params, size = size_of(vs_params)})

	sg.draw(0, i32(len(state.vertices)), 1)

	// Clear batch
	clear(&state.vertices)
}

// Adds arrow head to vectors to show direction
add_vector_with_arrow :: proc(dd: ^DebugDraw, start, end: [2]f32, color: [4]f32, arrow_size: f32 = 10.0) {
	// Main line
	add_vector(dd, start, end, color)

	// Calculate arrow head
	dir := end - start
	dir_norm := linalg.normalize(dir)

	// Calculate perpendicular vector for arrow head
	perp := [2]f32{-dir_norm.y, dir_norm.x}

	// Arrow head points
	arrow_left := end - dir_norm * arrow_size + perp * arrow_size * 0.5
	arrow_right := end - dir_norm * arrow_size - perp * arrow_size * 0.5

	// Draw arrow head
	add_vector(dd, end, arrow_left, color)
	add_vector(dd, end, arrow_right, color)
}

// Draws coordinate axes with optional grid
add_coordinate_system :: proc(dd: ^DebugDraw, origin: [2]f32, size: f32, grid_size: f32 = 0) {
	// Draw grid first (if enabled)
	if grid_size > 0 {
		grid_color := [4]f32{0.5, 0.5, 0.5, 0.3} // Semi-transparent gray

		// Calculate grid bounds
		min_x := origin.x - size
		max_x := origin.x + size
		min_y := origin.y - size
		max_y := origin.y + size

		// Vertical lines
		x := min_x - math.mod(min_x, grid_size)
		for x <= max_x {
			add_vector(dd, {x, min_y}, {x, max_y}, grid_color)
			x += grid_size
		}

		// Horizontal lines
		y := min_y - math.mod(min_y, grid_size)
		for y <= max_y {
			add_vector(dd, {min_x, y}, {max_x, y}, grid_color)
			y += grid_size
		}
	}
	// X axis (red)
	add_vector_with_arrow(dd, origin, {origin.x + size, origin.y}, {1, 0, 0, 1})

	// Y axis (green)
	add_vector_with_arrow(dd, origin, {origin.x, origin.y + size}, {0, 1, 0, 1})
}
