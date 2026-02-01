package game

import "../entry"
import "camera"
import "core:c"
import "core:fmt"
import "core:image/qoi"
import "core:math/linalg"
import "logic"
import "menu"
import "render/debug_draw"
import "render/particles"
import "render/screen_flash"
import "render/sprites"
import "render/tilemap"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"


Render :: struct {
	//assets
	tex0:                     sg.Image,

	//Drawing targets
	draw_default_pass:        sg.Pass_Action,
	draw_minimap_pass:        sg.Pass_Action,
	draw_minimap_attachments: sg.Attachments,
	world_ortho:              linalg.Matrix4f32,

	// pipelines
	world_sprites:            ^sprites.Sprites,
	tilemap_front:            ^tilemap.Tilemap_Manager,
	tilemap_back:             ^tilemap.Tilemap_Manager,
	screen_flash_renderer:    screen_flash.Screen_Flash_Renderer,
	particle_renderer:        particles.Particle_Renderer,
}

render_init :: proc(r: ^Render) {
	fmt.println("Render init")
	// test_img, success := load_test_img("assets/1.png")
	// success := load_test_img("assets/dd-000-000__FINAL__ATLAS.qoi", r)
	success := load_test_img("assets/atlas.qoi", r)

	assert(success, "fail load img")
	fmt.println("test_img", success, r.tex0)

	r.world_sprites = sprites.sprites_init()
	sprites.sprites_set_texture(r.tex0, r.world_sprites)

	/*================================================================================*/

	// default pass action: clear to black
	r.draw_default_pass = {
		colors = {0 = {load_action = .CLEAR, clear_value = {0, 0, 0, 1}}},
	}

	/*--------------------------------------------------------------------------------*/
	// Ofscreen Render to texture
	r.draw_minimap_pass = {
		colors = {0 = {load_action = .CLEAR, clear_value = {0, 0, 0, 1}}},
	}

	color_img_desc := sg.Image_Desc {
		usage = {color_attachment = true},
		width = 256,
		height = 256,
		pixel_format = .RGBA8,
		sample_count = 1, //OFFSCREEN_SAMPLE_COUNT,
	}
	depth_img_desc := sg.Image_Desc {
		usage = {depth_stencil_attachment = true},
		width = 256,
		height = 256,
		pixel_format = .DEPTH,
		sample_count = 1, //OFFSCREEN_SAMPLE_COUNT,
	}
	color_img := sg.make_image(color_img_desc)
	depth_img := sg.make_image(depth_img_desc)
	r.draw_minimap_attachments = {
		colors = {0 = sg.make_view({color_attachment = {image = color_img}})},
		depth_stencil = sg.make_view({depth_stencil_attachment = {image = depth_img}}),
	}


	when ODIN_DEBUG {
		debug_state.draw = debug_draw.init_debug_draw()
	}

	// Initialize screen flash renderer
	r.screen_flash_renderer = screen_flash.init()

	// Initialize particle renderer
	r.particle_renderer = particles.init()
	particles.set_texture(&r.particle_renderer, r.tex0)
}

render_frame :: proc(w: ^World, r: ^Render) {
	// Prepare HUD data
	hud_data := prepare_hud_data(w, r)

	// Start nuklear frame and draw UI
	ctx := menu.new_frame()
	menu.draw_with_hud(ctx, hud_data)

	r.world_sprites.count = 0
	render_sprite(w, r)
	render_particles(w, r)
	update_ortho(w, r)

	/*====================================================================================================*/
	/*                                          DRAWING                                                   */
	/*====================================================================================================*/
	sg.begin_pass({action = r.draw_minimap_pass, attachments = r.draw_minimap_attachments})
	sg.end_pass()
	/*====================================================================================================*/
	sg.begin_pass({action = r.draw_default_pass, swapchain = sglue.swapchain()})


	when ODIN_DEBUG {
		debug_frame(w, r)
		debug_draw.draw(&debug_state.draw, &r.world_ortho)
	}


	sprites.sprites_draw(r.world_sprites, &r.world_ortho)

	// Draw particles (after sprites)
	particles.draw(&r.particle_renderer, &r.world_ortho)

	// Draw screen flash (after sprites, before UI)
	if screen_flash_is_active(&w.screen_flash) {
		screen_flash.draw(&r.screen_flash_renderer, screen_flash_get_color(&w.screen_flash))
	}

	// FIX: Update mouse position right before render to minimize cursor lag
	// This ensures we use the most recent mouse position for cursor drawing
	menu.update_mouse()
	menu.render(sapp.width(), sapp.height())
	sg.end_pass()
	/*====================================================================================================*/
	sg.commit()

}

render_cleanup :: proc(r: ^Render) {
	fmt.println("RENDER cleanup")
	sprites.sprites_cleanup(r.world_sprites)

	if r.tilemap_front != nil {
		tilemap.destory_render_tilemap(r.tilemap_front)
	}
	if r.tilemap_back != nil {
		tilemap.destory_render_tilemap(r.tilemap_back)
	}

	screen_flash.cleanup(&r.screen_flash_renderer)
	particles.cleanup(&r.particle_renderer)

	when ODIN_DEBUG {
		debug_draw.destroy_debug_draw(&debug_state.draw)
	}
}

render_reloaded :: proc(r: ^Render) {
	fmt.println("RENDER reload")

	// Reinitialize nuklear (its internal state doesn't survive hot reload)
	menu.init()

	sprites.sprites_cleanup(r.world_sprites)
	r.world_sprites = sprites.sprites_init()
	sprites.sprites_set_texture(r.tex0, r.world_sprites)

	if r.tilemap_front != nil {
		tilemap.destory_render_tilemap(r.tilemap_front)
		r.tilemap_front = nil
	}
	if r.tilemap_back != nil {
		tilemap.destory_render_tilemap(r.tilemap_back)
		r.tilemap_back = nil
	}

	when ODIN_DEBUG {
		debug_draw.destroy_debug_draw(&debug_state.draw)
		debug_state.draw = debug_draw.init_debug_draw()
	}

	// Reinitialize screen flash renderer
	screen_flash.cleanup(&r.screen_flash_renderer)
	r.screen_flash_renderer = screen_flash.init()

	// Reinitialize particle renderer
	particles.cleanup(&r.particle_renderer)
	r.particle_renderer = particles.init()
	particles.set_texture(&r.particle_renderer, r.tex0)
}

@(private = "file")
update_ortho :: proc(w: ^World, r: ^Render) {
	viewport := [2]f32{sapp.widthf(), sapp.heightf()}
	r.world_ortho = camera.camera_get_matrix(&w.cam, viewport)
}

@(require_results)
load_test_img :: proc(filename: string, r: ^Render) -> (ok: bool) {
	img_data := entry.read_entire_file(filename, context.temp_allocator) or_return

	img, img_err := qoi.load_from_bytes(img_data, allocator = context.temp_allocator)
	if img_err != nil {
		return
	}
	desc := sg.Image_Desc {
		width        = i32(img.width),
		height       = i32(img.height),
		pixel_format = .RGBA8,
	}

	desc.data.mip_levels[0] = {
		ptr  = raw_data(img.pixels.buf),
		size = uint(img.width * img.height * 4),
	}

	r.tex0 = sg.make_image(desc)

	return true
}

@(private = "file")
prepare_hud_data :: proc(w: ^World, r: ^Render) -> menu.Hud_Data {
	hud: menu.Hud_Data

	// Try to find player entity (entity ID 0 is usually player in mock data)
	// This is a simple approach - you might want to track player ID in World
	player_id := 0

	// Get player position
	if pos, ok := logic.get_component(&w.position, player_id); ok {
		hud.player_pos_x = c.int(pos.x)
		hud.player_pos_y = c.int(pos.y)
	}

	// Get player velocity
	if vel, ok := logic.get_component(&w.velocity, player_id); ok {
		hud.player_vel_x = c.int(vel.x)
		hud.player_vel_y = c.int(vel.y)
	}

	// Get jump state
	if jump, ok := logic.get_component(&w.jump, player_id); ok {
		hud.is_grounded = c.int(jump.can_jump ? 1 : 0)
		hud.is_rising = c.int(jump.is_rising ? 1 : 0)
		hud.is_facing_right = c.int(jump.facing_right ? 1 : 0)
		hud.jump_hold_frames = c.int(jump.jump_hold_frames)
	}

	// World info
	hud.entity_count = c.int(w.next_entity_id) // Total entities created
	hud.paused = c.int(w.pasued ? 1 : 0)

	// Camera
	cam_pos := camera.camera_get_render_position(&w.cam)
	hud.camera_x = cam_pos.x
	hud.camera_y = cam_pos.y
	hud.zoom = camera.camera_get_render_zoom(&w.cam)

	// Performance
	hud.fps = 1.0 / f32(sapp.frame_duration())
	hud.frame_time_ms = f32(sapp.frame_duration() * 1000.0)

	// Window size
	hud.window_width = sapp.width()
	hud.window_height = sapp.height()

	return hud
}
