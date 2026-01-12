package game

import sapp "sokol/app"

Input_State_Flags :: enum {
	down,
	just_pressed,
	just_released,
	repeat,
}

Input_State :: struct {
	keys: [sapp.MAX_KEYCODES]bit_set[Input_State_Flags],
}

@(private = "file")
input_state: Input_State

key_just_pressed :: proc(code: sapp.Keycode) -> bool {
	return .just_pressed in input_state.keys[code]
}

key_down :: proc(code: sapp.Keycode) -> bool {
	return .down in input_state.keys[code]
}

key_just_released :: proc(code: sapp.Keycode) -> bool {
	return .just_released in input_state.keys[code]
}

globalEventHandler :: proc(event: ^sapp.Event) {
	// ui.ui_input(state.gui, event)
	// ui.ui_input(state.wui, event)
	// ui.ui_input(state.hud, event)

	// see this for example of events: https://floooh.github.io/sokol-html5/events-sapp.html
	// input_state := &state.input_state

	#partial switch event.type {
	// case .MOUSE_UP:
	// 	if .down in input_state.keys[map_sokol_mouse_button(event.mouse_button)] {
	// 		input_state.keys[map_sokol_mouse_button(event.mouse_button)] -= {.down}
	// 		input_state.keys[map_sokol_mouse_button(event.mouse_button)] += {.just_released}
	// 	}
	// case .MOUSE_DOWN:
	// 	if !(.down in input_state.keys[map_sokol_mouse_button(event.mouse_button)]) {
	// 		input_state.keys[map_sokol_mouse_button(event.mouse_button)] += {.down, .just_pressed}
	// 	}

	case .KEY_UP:
		if .down in input_state.keys[event.key_code] {
			input_state.keys[event.key_code] -= {.down}
			input_state.keys[event.key_code] += {.just_released}
		}
	case .KEY_DOWN:
		if !event.key_repeat && !(.down in input_state.keys[event.key_code]) {
			input_state.keys[event.key_code] += {.down, .just_pressed}
		}
		if event.key_repeat {
			input_state.keys[event.key_code] += {.repeat}
		}
	case .QUIT_REQUESTED:
		sapp.cancel_quit()
		sapp.quit()
	// context = runtime.default_context()
	// fmt.println("QUIT_REQUESTED")
	}
}

reset_input_state_for_next_frame :: proc() {
	for &set in input_state.keys {
		set -= {.just_pressed, .just_released, .repeat}
	}
}
