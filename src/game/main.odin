package game

import "../entry"
import "core:fmt"
import "core:text/i18n"
import menu "menu"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"


Game_Memory :: struct {
	world:  World,
	render: Render,
}

@(private = "file")
g: ^Game_Memory

@(export)
game_app_default_desc :: proc() -> sapp.Desc {
	return {
		width = 1280,
		height = 720,
		sample_count = 4,
		window_title = "Game",
		icon = {sokol_default = true},
		logger = {func = slog.func},
		html5 = {update_document_title = true},
	}
}


@(export)
game_init :: proc() {
	// err: i18n.Error
	// mo_data, _ := entry.read_entire_file(LOCALES_DIR + "/ru/messages.mo", context.temp_allocator)
	// i18n.ACTIVE, err = i18n.parse_mo(mo_data)
	// if err != nil {
	// 	fmt.eprintfln("error while parsing", "error", err)
	// 	return
	// }

	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	menu.init()
	g = new(Game_Memory)

	world_init(&g.world)
	render_init(&g.render)
}

@(export)
game_frame :: proc() {
	world_frame(&g.world)


	render_frame(&g.world, &g.render)
	// free_all(context.temp_allocator)
	reset_input_state_for_next_frame()
}


force_reset: bool

@(export)
game_event :: proc(e: ^sapp.Event) {

	#partial switch e.type {
	case .KEY_DOWN:
		if e.key_code == .F6 {
			force_reset = true
			return
		}
		// Toggle menu with ESC key
		if e.key_code == .ESCAPE {
			menu.toggle()
			return
		}
		// Toggle debug HUD with F3 key
		if e.key_code == .F3 {
			menu.toggle_debug_hud()
			return
		}
	}

	// Let menu handle event if it's visible
	if menu.handle_event(e) {
		return // UI consumed the event
	}

	globalEventHandler(e)
}

@(export)
game_cleanup :: proc() {
	world_cleanup(&g.world)
	render_cleanup(&g.render)
	menu.shutdown()
	sg.shutdown()
	free(g)
	i18n.destroy()
}

@(export)
game_memory :: proc() -> rawptr {
	return g
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g = (^Game_Memory)(mem)
	fmt.println("game_hot_reloaded")
	render_reloaded(&g.render) // This handles menu reinit

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside
	// `g`. Then that state carries over between hot reloads.
}

@(export)
game_force_restart :: proc() -> bool {
	return force_reset
}
