package textbox

import microui2 ".."
import "./textedit"
import "core:fmt"
import "core:math"
import "core:strconv"
import "core:strings"

MAX_TEXT_STORE :: #config(MICROUI_MAX_TEXT_STORE, 1024)

SLIDER_FMT :: #config(MICROUI_SLIDER_FMT, "%.2f")
MAX_FMT :: #config(MICROUI_MAX_FMT, 127)
Real :: f32


Text_Store :: struct {
	_text_store:    [MAX_TEXT_STORE]u8,
	text_input:     strings.Builder, // uses `_text_store` as backing store with nil_allocator.
	textbox_offset: i32,
}

Number_Store :: struct {
	number_edit_buf: [MAX_FMT]u8,
	number_edit_len: int,
	number_edit_id:  microui2.Id,
}

set_clipboard_fn :: #type proc(user_data: rawptr, text: string) -> (ok: bool)
init_textbox :: proc(
	textbox_state: ^textedit.State,
	text_store: ^Text_Store,
	set_clipboard: set_clipboard_fn = nil,
	get_clipboard: proc(user_data: rawptr) -> (text: string, ok: bool) = nil,
	clipboard_user_data: rawptr = nil,
) {
	textbox_state^ = {} // zero memory
	text_store^ = {} // zero memory
	text_store.text_input = strings.builder_from_bytes(text_store._text_store[:])
	textbox_state.set_clipboard = set_clipboard
	textbox_state.get_clipboard = get_clipboard
	textbox_state.clipboard_user_data = clipboard_user_data
}

frame_end :: proc(text_store: ^Text_Store) {
	strings.builder_reset(&text_store.text_input)
}

input_text :: proc(text_store: ^Text_Store, text: string) {
	strings.write_string(&text_store.text_input, text)
}

textbox :: proc(
	ctx: ^microui2.Context,
	textbox_state: ^textedit.State,
	text_store: ^Text_Store,
	buf: []u8,
	textlen: ^int,
	opt := microui2.Options{},
) -> microui2.Result_Set {
	id := microui2.get_id(ctx, uintptr(&buf[0]))
	r := microui2.layout_next(ctx)

	return textbox_raw(ctx, textbox_state, text_store, buf, textlen, id, r, opt)
}


number_textbox :: proc(
	ctx: ^microui2.Context,
	textbox_state: ^textedit.State,
	text_store: ^Text_Store,
	number_store: ^Number_Store,
	value: ^Real,
	r: microui2.Rect,
	id: microui2.Id,
	fmt_string: string,
) -> bool {
	if ctx.mouse_pressed_bits == {.LEFT} && .SHIFT in ctx.key_down_bits && ctx.hover_id == id {
		number_store.number_edit_id = id
		nstr := fmt.bprintf(number_store.number_edit_buf[:], fmt_string, value^)
		number_store.number_edit_len = len(nstr)
	}
	if number_store.number_edit_id == id {
		res := textbox_raw(
			ctx,
			textbox_state,
			text_store,
			number_store.number_edit_buf[:],
			&number_store.number_edit_len,
			id,
			r,
			{},
		)
		if .SUBMIT in res || ctx.focus_id != id {
			value^, _ = parse_real(
				string(number_store.number_edit_buf[:number_store.number_edit_len]),
			)
			number_store.number_edit_id = 0
		} else {
			return true
		}
	}
	return false
}

slider :: proc(
	ctx: ^microui2.Context,
	textbox_state: ^textedit.State,
	text_store: ^Text_Store,
	number_store: ^Number_Store,
	value: ^Real,
	low, high: Real,
	step: Real = 0.0,
	fmt_string: string = SLIDER_FMT,
	opt: microui2.Options = {.ALIGN_CENTER},
) -> (
	res: microui2.Result_Set,
) {
	last := value^
	v := last
	id := microui2.get_id(ctx, uintptr(value))
	base := microui2.layout_next(ctx)

	/* handle text input mode */
	if number_textbox(ctx, textbox_state, text_store, number_store, &v, base, id, fmt_string) {
		return
	}

	/* handle normal mode */
	microui2.update_control(ctx, id, base, opt)

	/* handle input */
	if ctx.focus_id == id && ctx.mouse_down_bits == {.LEFT} {
		v = low + Real(ctx.mouse_pos.x - base.x) * (high - low) / Real(base.w)
		if step != 0.0 {
			v = math.floor((v + step / 2) / step) * step
		}
	}
	/* clamp and store value, update res */
	v = clamp(v, low, high)
	value^ = v
	if last != v {
		res += {.CHANGE}
	}

	/* draw base */
	microui2.draw_control_frame(ctx, base, .BASE, opt, id)
	/* draw thumb */
	w := ctx.style.thumb_size
	x := i32((v - low) * Real(base.w - w) / (high - low))
	thumb := microui2.Rect{base.x + x, base.y, w, base.h}
	microui2.draw_control_frame(ctx, thumb, .BUTTON, opt, id)
	/* draw text  */
	text_buf: [4096]byte
	microui2.draw_control_text(ctx, fmt.bprintf(text_buf[:], fmt_string, v), base, .TEXT, opt, id)

	return
}


@(private)
parse_real :: #force_inline proc(s: string) -> (Real, bool) {
	f, ok := strconv.parse_f64(s)
	return Real(f), ok
}

@(private)
textbox_raw :: proc(
	ctx: ^microui2.Context,
	textbox_state: ^textedit.State,
	text_store: ^Text_Store,
	textbuf: []u8,
	textlen: ^int,
	id: microui2.Id,
	r: microui2.Rect,
	opt := microui2.Options{},
) -> (
	res: microui2.Result_Set,
) {
	microui2.update_control(ctx, id, r, opt | {.HOLD_FOCUS})

	font := ctx.style.font

	if ctx.focus_id == id {
		/* create a builder backed by the user's buffer */
		builder := strings.builder_from_bytes(textbuf)
		non_zero_resize(&builder.buf, textlen^)
		textbox_state.builder = &builder
		if textbox_state.id != u64(id) {
			textbox_state.id = u64(id)
			textbox_state.selection = {}
		}

		/* check selection bounds */
		if textbox_state.selection[0] > textlen^ || textbox_state.selection[1] > textlen^ {
			textbox_state.selection = {}
		}

		/* handle text input */
		if strings.builder_len(text_store.text_input) > 0 {
			if textedit.input_text(textbox_state, strings.to_string(text_store.text_input)) > 0 {
				textlen^ = strings.builder_len(builder)
				res += {.CHANGE}
			}
		}
		/* handle ctrl+a */
		if .A in ctx.key_pressed_bits &&
		   .CTRL in ctx.key_down_bits &&
		   .ALT not_in ctx.key_down_bits {
			textbox_state.selection = {textlen^, 0}
		}
		/* handle ctrl+x */
		if .X in ctx.key_pressed_bits &&
		   .CTRL in ctx.key_down_bits &&
		   .ALT not_in ctx.key_down_bits {
			if textedit.cut(textbox_state) {
				textlen^ = strings.builder_len(builder)
				res += {.CHANGE}
			}
		}
		/* handle ctrl+c */
		if .C in ctx.key_pressed_bits &&
		   .CTRL in ctx.key_down_bits &&
		   .ALT not_in ctx.key_down_bits {
			textedit.copy(textbox_state)
		}
		/* handle ctrl+v */
		if .V in ctx.key_pressed_bits &&
		   .CTRL in ctx.key_down_bits &&
		   .ALT not_in ctx.key_down_bits {
			if textedit.paste(textbox_state) {
				textlen^ = strings.builder_len(builder)
				res += {.CHANGE}
			}
		}
		/* handle left/right */
		if .LEFT in ctx.key_pressed_bits {
			move: textedit.Translation = .Word_Left if .CTRL in ctx.key_down_bits else .Left
			if .SHIFT in ctx.key_down_bits {
				textedit.select_to(textbox_state, move)
			} else {
				textedit.move_to(textbox_state, move)
			}
		}
		if .RIGHT in ctx.key_pressed_bits {
			move: textedit.Translation = .Word_Right if .CTRL in ctx.key_down_bits else .Right
			if .SHIFT in ctx.key_down_bits {
				textedit.select_to(textbox_state, move)
			} else {
				textedit.move_to(textbox_state, move)
			}
		}
		/* handle home/end */
		if .HOME in ctx.key_pressed_bits {
			if .SHIFT in ctx.key_down_bits {
				textedit.select_to(textbox_state, .Start)
			} else {
				textedit.move_to(textbox_state, .Start)
			}
		}
		if .END in ctx.key_pressed_bits {
			if .SHIFT in ctx.key_down_bits {
				textedit.select_to(textbox_state, .End)
			} else {
				textedit.move_to(textbox_state, .End)
			}
		}
		/* handle backspace/delete */
		if .BACKSPACE in ctx.key_pressed_bits && textlen^ > 0 {
			move: textedit.Translation = .Word_Left if .CTRL in ctx.key_down_bits else .Left
			textedit.delete_to(textbox_state, move)
			textlen^ = strings.builder_len(builder)
			res += {.CHANGE}
		}
		if .DELETE in ctx.key_pressed_bits && textlen^ > 0 {
			move: textedit.Translation = .Word_Right if .CTRL in ctx.key_down_bits else .Right
			textedit.delete_to(textbox_state, move)
			textlen^ = strings.builder_len(builder)
			res += {.CHANGE}
		}
		/* handle return */
		if .RETURN in ctx.key_pressed_bits {
			microui2.set_focus(ctx, 0)
			res += {.SUBMIT}
		}

		/* handle click/drag */
		if .LEFT in ctx.mouse_down_bits {
			idx := textlen^
			for i in 0 ..< textlen^ {
				/* skip continuation bytes */
				if textbuf[i] >= 0x80 && textbuf[i] < 0xc0 {
					continue
				}
				if ctx.mouse_pos.x <
				   r.x + text_store.textbox_offset + ctx.text_width(font, string(textbuf[:i])) {
					idx = i
					break
				}
			}
			textbox_state.selection[0] = idx
			if .LEFT in ctx.mouse_pressed_bits && .SHIFT not_in ctx.key_down_bits {
				textbox_state.selection[1] = idx
			}
		}
	}

	textstr := string(textbuf[:textlen^])

	/* draw */
	microui2.draw_control_frame(ctx, r, .BASE, opt, id)
	if ctx.focus_id == id {
		text_color := ctx.style.colors[.TEXT]
		sel_color := ctx.style.colors[.SELECTION_BG]
		textw := ctx.text_width(font, textstr)
		texth := ctx.text_height(font)
		headx := ctx.text_width(font, textstr[:textbox_state.selection[0]])
		tailx := ctx.text_width(font, textstr[:textbox_state.selection[1]])
		ofmin := max(ctx.style.padding - headx, r.w - textw - ctx.style.padding)
		ofmax := min(r.w - headx - ctx.style.padding, ctx.style.padding)
		text_store.textbox_offset = clamp(text_store.textbox_offset, ofmin, ofmax)
		textx := r.x + text_store.textbox_offset
		texty := r.y + (r.h - texth) / 2
		microui2.push_clip_rect(ctx, r)
		microui2.draw_rect(
			ctx,
			microui2.Rect{textx + min(headx, tailx), texty, abs(headx - tailx), texth},
			sel_color,
		)
		microui2.draw_text(ctx, font, textstr, microui2.Vec2{textx, texty}, text_color)
		microui2.draw_rect(ctx, microui2.Rect{textx + headx, texty, 1, texth}, text_color)
		microui2.pop_clip_rect(ctx)
	} else {
		microui2.draw_control_text(ctx, textstr, r, .TEXT, opt, id)
	}

	return
}
