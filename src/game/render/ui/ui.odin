package ui

import sapp "../../sokol/app"
import sg "../../sokol/gfx"
import microui "./microui2"
import "./microui2/textbox"
import "./microui2/textbox/textedit"
import "core:c"
import "core:fmt"
import "core:slice"
import "core:unicode/utf8"

Context :: microui.Context

Ui_State :: struct {
	ctx:           microui.Context,
	textbox_state: textedit.State,
	text_store:    textbox.Text_Store,
	pip:           sg.Pipeline,
	bind:          sg.Bindings,
	instances:     [UI_MAX_QUADS]Ui_Render_Instance,
	count:         int,
}

destryoy_ui :: proc(manager: ^Ui_State) {
	free(manager)
}

init_ui :: proc() -> ^Ui_State {
	manager := new(Ui_State)

	microui.init(&manager.ctx, game9_style)
	// microui.init(&manager.ctx)

	ui_init_renderer(manager)
	textbox.init_textbox(&manager.textbox_state, &manager.text_store)

	return manager
}

@(private = "file")
mouse_buttons := [?]microui.Mouse {
	sapp.Mousebutton.LEFT   = microui.Mouse.LEFT,
	sapp.Mousebutton.RIGHT  = microui.Mouse.RIGHT,
	sapp.Mousebutton.MIDDLE = microui.Mouse.MIDDLE,
}

ui_input :: proc(ui_state: ^Ui_State, event: ^sapp.Event) {
	#partial switch event.type {
	case .MOUSE_MOVE:
		microui.input_mouse_move(&ui_state.ctx, i32(event.mouse_x), i32(event.mouse_y))
	case .MOUSE_DOWN:
		if event.mouse_button == .INVALID {break}
		btn := mouse_buttons[event.mouse_button]
		microui.input_mouse_down(&ui_state.ctx, i32(event.mouse_x), i32(event.mouse_y), btn)
	case .MOUSE_UP:
		if event.mouse_button == .INVALID {break}
		btn := mouse_buttons[event.mouse_button]
		microui.input_mouse_up(&ui_state.ctx, i32(event.mouse_x), i32(event.mouse_y), btn)

	case .MOUSE_SCROLL:
		microui.input_scroll(&ui_state.ctx, i32(event.scroll_x), i32(-event.scroll_y))
	case .KEY_DOWN:
		key := to_microui_key(event.key_code) or_break
		microui.input_key_down(&ui_state.ctx, key)
	case .KEY_UP:
		key := to_microui_key(event.key_code) or_break
		microui.input_key_up(&ui_state.ctx, key)
	case .CHAR:
		// don't input Backspace as character (required to make Backspace work in text input fields)
		if event.char_code == 127 {break}
		str := utf8.runes_to_string([]rune{rune(event.char_code)})
		defer delete(str)

		textbox.input_text(&ui_state.text_store, str)
	}
}


@(private = "file")
to_microui_key :: proc(kc: sapp.Keycode) -> (key: microui.Key, ok: bool) {
	ok = true
	#partial switch kc {
	case .LEFT_SHIFT, .RIGHT_SHIFT:
		key = microui.Key.SHIFT
	case .LEFT_CONTROL, .RIGHT_CONTROL:
		key = microui.Key.CTRL
	case .LEFT_ALT, .RIGHT_ALT:
		key = microui.Key.ALT
	case .BACKSPACE:
		key = microui.Key.BACKSPACE
	case .DELETE:
		key = microui.Key.DELETE
	case .ENTER:
		key = microui.Key.RETURN
	case .LEFT:
		key = microui.Key.LEFT
	case .RIGHT:
		key = microui.Key.RIGHT
	case .HOME:
		key = microui.Key.HOME
	case .END:
		key = microui.Key.END
	case .A:
		key = microui.Key.A
	case .X:
		key = microui.Key.X
	case .C:
		key = microui.Key.C
	case .V:
		key = microui.Key.V
	case:
		ok = false
	}
	return
}
