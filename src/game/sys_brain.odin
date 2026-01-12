package game

import "grid"
import "logic"
import "shape"

Brain :: i8

Input :: struct {
	x: i8, // -1, 0, 1 for left/none/right
}

sys_brain :: proc(w: ^World) {
	view := logic.view(&w.brain, &w.position, &w.input)
	for entity, brain, pos, input in logic.each(&view) {
		if brain^ == 0 {
			sys_keyboard(w, entity)

			continue
		}

		test := [4]int{}
		test.xy = pos^
		test.z = test.x + int(input.x) * 10 * UNIT
		test.w = test.y
		found := grid.query_segment(&w.grid, &test)
		defer delete(found)

		for wall in found {
			shape.segment_segment_test(wall, &test) or_continue
			input.x *= -1
		}
	}
}

@(private = "file")
sys_keyboard :: proc(w: ^World, id: int) {
	if comp, ok := logic.get_component(&w.jump, id); ok {
		comp.input = key_down(.SPACE)
	}

	if char_input, ok := logic.get_component(&w.input, id); ok {
		char_input.x = 0
		char_input.x += i8(key_down(.RIGHT))
		char_input.x -= i8(key_down(.LEFT))
	}

	// if comp, ok := logic.get_component(&w.trigger, id); ok {
	// 	comp.state.is_active = key_down(input_state, .X)
	// 	comp.state.just_pressed = key_just_pressed(input_state, .X)
	// 	comp.state.just_released = key_just_released(input_state, .X)
	// }
}
