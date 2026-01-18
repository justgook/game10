package game

import "camera"
import "core:fmt"
import "core:text/i18n"
import "logic"
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

		// Debug camera effects (F1-F4)
		when ODIN_DEBUG {
			if e.key_code == .F1 {
				// Test camera shake
				camera.camera_shake(&g.world.cam, 3, 3, 0.5)
				fmt.println("Camera shake triggered")
				return
			}
			if e.key_code == .F2 {
				// Test camera bump
				camera.camera_bump(&g.world.cam, 10, 5)
				fmt.println("Camera bump triggered")
				return
			}
			if e.key_code == .F4 {
				// Test zoom bump
				camera.camera_bump_zoom(&g.world.cam, 0.1)
				fmt.println("Camera zoom bump triggered")
				return
			}
			if e.key_code == .F5 {
				// Toggle zoom
				if g.world.cam.zoom > 1.5 {
					camera.camera_set_zoom(&g.world.cam, 1.0)
				} else {
					camera.camera_set_zoom(&g.world.cam, 2.0)
				}
				fmt.printfln("Camera zoom set to %v", g.world.cam.zoom)
				return
			}
			if e.key_code == .F7 {
				// Test blink effect on player
				if blink, ok := logic.get_component(&g.world.blink, g.world.player_entity); ok {
					blink_white(blink)
					fmt.println("Blink triggered on player")
				}
				return
			}
			if e.key_code == .F8 {
				// Test red blink (damage)
				if blink, ok := logic.get_component(&g.world.blink, g.world.player_entity); ok {
					blink_red(blink)
					fmt.println("Red blink triggered on player")
				}
				return
			}
			if e.key_code == .F9 {
				// Test sprite shake on player
				if shake, ok := logic.get_component(&g.world.sprite_shake, g.world.player_entity); ok {
					sprite_shake_medium(shake)
					fmt.println("Sprite shake triggered on player")
				}
				return
			}
			if e.key_code == .F10 {
				// Test screen flash (yellow - shooting style)
				screen_flash_shoot(&g.world.screen_flash)
				fmt.println("Screen flash triggered")
				return
			}
			if e.key_code == .F11 {
				// Test screen flash (white - impact style)
				screen_flash_white(&g.world.screen_flash)
				fmt.println("Screen flash (white) triggered")
				return
			}
			if e.key_code == .F12 {
				// Test particle effects at player position
				if pos, ok := logic.get_component(&g.world.position, g.world.player_entity); ok {
					px := f32(pos.x) / f32(UNIT)
					py := f32(pos.y) / f32(UNIT)

					// Spawn landing smoke
					fx_land_smoke(&g.world.particles, px, py, 1.0)
					fmt.printfln(
						"Particles spawned at (%v, %v), active: %v",
						px,
						py,
						g.world.particles.active_count,
					)
				}
				return
			}
			if e.key_code == .P {
				// Test gun shot particles
				if pos, ok := logic.get_component(&g.world.position, g.world.player_entity); ok {
					if jump, jok := logic.get_component(&g.world.jump, g.world.player_entity);
					   jok {
						px := f32(pos.x) / f32(UNIT)
						py := f32(pos.y) / f32(UNIT)
						dir: f32 = jump.facing_right ? 1.0 : -1.0

						fx_gun_shot(&g.world.particles, px + dir * 16, py - 8, dir)
						fx_light_spot(&g.world.particles, px + dir * 20, py - 8, 0xffcc00, 0.8)
						screen_flash_shoot(&g.world.screen_flash)
						fmt.printfln(
							"Gun shot particles, active: %v",
							g.world.particles.active_count,
						)
					}
				}
				return
			}
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
