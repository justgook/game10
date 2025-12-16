package game

import "core:fmt"
import "render/ui"
import mu "render/ui/microui2"
import "render/ui/microui2/textbox"
import sapp "sokol/app"

render_menu :: proc(w: ^World, r: ^Render) {
	ctx := &r.gui.ctx
	// width := i32(sapp.width())
	// height := i32(sapp.height())

	mu.begin(ctx)
	menu_pause(w, r.gui)
	menu_chat(w, r.gui)
	menu_settings(w, &r.gui.ctx)
	menu_tree(w, &r.gui.ctx)
	menu_main(w, &r.gui.ctx)
	menu_game_over(w, &r.gui.ctx)

	mu.end(ctx)
}

@(private = "file")
menu_chat :: proc(w: ^World, state: ^ui.Ui_State) {
	ctx := &state.ctx
	mu.begin_window(ctx, T("CHAT"), {100, 100, 300, 200})

	@(static) buf: [128]byte
	@(static) buf_len: int
	submitted := false
	mu.layout_row(ctx, {-70, -1})

	if .SUBMIT in textbox.textbox(ctx, &state.textbox_state, &state.text_store, buf[:], &buf_len) {
		mu.set_focus(ctx, ctx.last_id)
		submitted = true
	}

	if .SUBMIT in mu.button(ctx, "Submit") {
		submitted = true
	}

	mu.end_window(ctx)
}

@(private = "file")
menu_settings :: proc(w: ^World, ctx: ^mu.Context) {
	@(static) active_tab: mu.Id

	text1 := T("GAME")
	text2 := T("CONTROLS")
	text3 := T("GRAPHICS")
	text4 := T("AUDIO")
	mu.begin_window(ctx, T("SETTING"), {450, 100, 350, 200})
	defer mu.end_window(ctx)

	w1 := ctx.text_width(ctx.style.font, text1)
	w2 := ctx.text_width(ctx.style.font, text2)
	w3 := ctx.text_width(ctx.style.font, text3)
	w4 := ctx.text_width(ctx.style.font, text4)
	mu.layout_row(ctx, {w1, w2, w3, w4})
	btn1 := mu.toggle(ctx, text1)
	btn1_id := ctx.last_id
	btn2 := mu.button(ctx, text2)
	btn2_id := ctx.last_id
	btn3 := mu.button(ctx, text3)
	btn3_id := ctx.last_id
	btn4 := mu.button(ctx, text4)
	btn4_id := ctx.last_id

	if .SUBMIT in btn1 {active_tab = btn1_id
	} else if .SUBMIT in btn2 {
		active_tab = btn2_id
	} else if .SUBMIT in btn3 {
		active_tab = btn3_id
	} else if .SUBMIT in btn4 {
		active_tab = btn4_id
	} else if active_tab == 0 {
		active_tab = btn2_id
	}

	mu.layout_row(ctx, {-1}, -1)
	mu.begin_panel(ctx, "SettingPanel", {.NO_FRAME})
	mu.layout_row(ctx, {-50, -1})
	switch active_tab {
	case btn1_id:
		@(static) screen_shake: bool = true
		@(static) mini_map: bool = true
		mu.label(ctx, T("LANGUAGE"));mu.button(ctx, T("ENGLISH"))
		mu.label(ctx, T("DIFFICULTY"));mu.button(ctx, T("EASY"))
		mu.label(ctx, T("SCREEN SHAKE"));mu.checkbox(ctx, "", &screen_shake)
		mu.label(ctx, T("MINI MAP"));mu.checkbox(ctx, "", &mini_map)
	case btn2_id:
		mu.button(ctx, T("Left"), opt = {});mu.label(ctx, T("A"))
		mu.button(ctx, T("Right"), opt = {});mu.label(ctx, T("D"))
		mu.button(ctx, T("Up"), opt = {});mu.label(ctx, T("W"))
		mu.button(ctx, T("Down"), opt = {});mu.label(ctx, T("S"))
		mu.button(ctx, T("Jump"), opt = {});mu.label(ctx, T("Space"))
		mu.button(ctx, T("Attack"), opt = {});mu.label(ctx, T("Mouse1"))
		mu.button(ctx, T("Heavy Attack"), opt = {});mu.label(ctx, T("Mouse2"))
		mu.button(ctx, T("Pause"), opt = {});mu.label(ctx, T("Esc"))
		mu.button(ctx, T("Inventory"), opt = {});mu.label(ctx, T("I"))
	case btn3_id:
		@(static) windowed: bool
		mu.label(ctx, T("FULL SCREEN"))
		mu.checkbox(ctx, "", &windowed)
	case btn4_id:
		@(static) sfx: bool = true
		@(static) music: bool = true
		@(static) sfx_volume: mu.Real = 75
		@(static) music_volume: mu.Real = 50
		mu.label(ctx, T("SOUND EFFECTS"))
		mu.checkbox(ctx, "", &sfx)
		mu.label(ctx, T("SOUND VOLUME"))
		mu.slider(ctx, &sfx_volume, 0, 100, 1, "%.0f")

		mu.label(ctx, T("MUSIC"))
		mu.checkbox(ctx, "", &music)
		mu.label(ctx, T("MUSIC VOLUME"))
		mu.slider(ctx, &music_volume, 0, 100, 1, "%.0f")
	}
	mu.end_panel(ctx)
}
@(private = "file")
write_log :: proc(input: string) {}

@(private = "file")
menu_tree :: proc(w: ^World, ctx: ^mu.Context) {
	mu.begin_window(ctx, T("TREE"), {900, 100, 300, 200})

	defer mu.end_window(ctx)

	/* tree */
	if mu.header(ctx, "Tree and Text", {.EXPANDED}) != {} {
		mu.layout_row(ctx, []i32{140, -1}, 0)
		mu.layout_begin_column(ctx)
		if mu.begin_treenode(ctx, "Test 1") != {} {
			if mu.begin_treenode(ctx, "Test 1a") != {} {
				mu.label(ctx, "Hello")
				mu.label(ctx, "world")
				mu.end_treenode(ctx)
			}
			if mu.begin_treenode(ctx, "Test 1b") != {} {
				if .SUBMIT in mu.button(ctx, "Button 1") do write_log("Pressed button 1")
				if .SUBMIT in mu.button(ctx, "Button 2") do write_log("Pressed button 2")
				mu.end_treenode(ctx)
			}
			mu.end_treenode(ctx)
		}
		if mu.begin_treenode(ctx, "Test 2") != {} {
			mu.layout_row(ctx, []i32{54, 54}, 0)
			if .SUBMIT in mu.button(ctx, "Button 3") do write_log("Pressed button 3")
			if .SUBMIT in mu.button(ctx, "Button 4") do write_log("Pressed button 4")
			if .SUBMIT in mu.button(ctx, "Button 5") do write_log("Pressed button 5")
			if .SUBMIT in mu.button(ctx, "Button 6") do write_log("Pressed button 6")
			mu.end_treenode(ctx)
		}
		if mu.begin_treenode(ctx, "Test 3") != {} {
			@(static) checks := [3]bool{true, false, true}
			mu.checkbox(ctx, "Checkbox 1", &checks[0])
			mu.checkbox(ctx, "Checkbox 2", &checks[1])
			mu.checkbox(ctx, "Checkbox 3", &checks[2])
			mu.end_treenode(ctx)
		}
		mu.layout_end_column(ctx)

		mu.layout_begin_column(ctx)
		mu.layout_row(ctx, {-1}, 0)
		mu.text(
			ctx,
			"Lorem ipsum\n dolor sit amet, consectetur adipiscing elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus ipsum, eu varius magna felis a nulla.",
		)
		mu.layout_end_column(ctx)
	}
}
@(private = "file")
menu_game_over :: proc(w: ^World, ctx: ^mu.Context) {
	mu.begin_window(ctx, T("The End Game Over"), {900, 400, 300, 200}, {.NO_CLOSE, .NO_RESIZE})
	mu.button(ctx, T("Continue"))
	mu.button(ctx, T("Restart"))
	mu.button(ctx, T("Quit"))
	defer mu.end_window(ctx)
}
@(private = "file")
menu_main :: proc(w: ^World, ctx: ^mu.Context) {
	mu.begin_window(ctx, T("MAIN MENU"), {450, 400, 300, 200}, {.NO_CLOSE, .NO_RESIZE})
	defer mu.end_window(ctx)
	mu.layout_row(ctx, {200}, 0)
	mu.button(ctx, T("Start Game"))
	mu.button(ctx, T("Continue Game"))
	mu.button(ctx, T("Settings"))
	mu.button(ctx, T("Credits"))
	mu.button(ctx, T("Quit"))

}
@(private = "file")
menu_pause :: proc(w: ^World, state: ^ui.Ui_State) {
	ctx := &state.ctx

	mu.begin_window(ctx, T("PAUSED"), {100, 400, 300, 200}, {.NO_CLOSE, .NO_RESIZE})
	cnt := mu.get_current_container(ctx)

	mu.layout_row(ctx, {200}, 0)

	if (.SUBMIT in mu.button(ctx, T("CONTINUE"))) {
		w.pasued = false
	}

	// mu.layout_next(ctx)
	if (.SUBMIT in mu.button(ctx, T("INVENTORY"))) {
		// open_window(ctx, T("THE Settings"))
	}


	if (.SUBMIT in mu.button(ctx, T("SETTINGS"))) {
		// open_window(ctx, "THE Settings")
	}

	// mu.layout_next(ctx)
	if (.SUBMIT in mu.button(ctx, T("MAIN MENU"))) {
		// pause_window.open = false
	}

	// mu.layout_next(ctx)
	if (.SUBMIT in mu.button(ctx, T("QUIT"))) {
		// pause_window.open = false
	}


	mu.end_window(ctx)
}

// @(private = "file")
// open_window :: proc(ctx: ^mu.Context, name: string) {
// 	cnt := mu.get_container(ctx, name)
// 	/* set as hover root so window isn't closed in begin_window()  */
// 	ctx.hover_root = cnt
// 	ctx.next_hover_root = cnt
// 	// cnt.open = true
// 	mu.bring_to_front(ctx, cnt)
// }
