package game

import "../entry"
import "core:fmt"
import "core:image/qoi"
import "core:math/linalg"
import "render/sprites"
import "render/tilemap"
import "render/ui"
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
	gui:                      ^ui.Ui_State,
	world_sprites:            ^sprites.Sprites,
	tilemap_front:            ^tilemap.Tilemap_Manager,
	tilemap_back:             ^tilemap.Tilemap_Manager,
}

render_init :: proc(r: ^Render) {
	fmt.println("Render init")
	// test_img, success := load_test_img("assets/1.png")
	success := load_test_img("assets/dd-000-000__FINAL__ATLAS.qoi", r)

	assert(success, "fail load img")
	fmt.println("test_img", success, r.tex0)

	r.gui = ui.init_ui()
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
}

render_frame :: proc(w: ^World, r: ^Render) {
	r.world_sprites.count = 0
	render_sprite(w, r)

	render_menu(w, r)
	update_ortho(w, r)


	/*====================================================================================================*/
	/*                                          DRAWING                                                   */
	/*====================================================================================================*/
	sg.begin_pass({action = r.draw_minimap_pass, attachments = r.draw_minimap_attachments})
	sg.end_pass()
	/*====================================================================================================*/
	sg.begin_pass({action = r.draw_default_pass, swapchain = sglue.swapchain()})

	sprites.sprites_draw(r.world_sprites, &r.world_ortho)

	ui.draw_ui(r.gui)

	sg.end_pass()
	/*====================================================================================================*/
	sg.commit()

}

render_cleanup :: proc(r: ^Render) {
	fmt.println("RENDER cleanup")
	sprites.sprites_cleanup(r.world_sprites)
	ui.destryoy_ui(r.gui)
}

render_reloaded :: proc(r: ^Render) {
	fmt.println("RENDER reload")

	sprites.sprites_cleanup(r.world_sprites)
	r.world_sprites = sprites.sprites_init()
	sprites.sprites_set_texture(r.tex0, r.world_sprites)
}

@(private = "file")
update_ortho :: proc(w: ^World, r: ^Render) {
	window_w := sapp.widthf()
	window_h := sapp.heightf()
	ortho := linalg.matrix_ortho3d_f32(window_w * -0.5, window_w * 0.5, window_h * -0.5, window_h * 0.5, -1, 1)
	translate_mat := linalg.matrix4_translate_f32({-w.camera.x, -w.camera.y, 0.0})
	scale_mat := linalg.matrix4_scale_f32({1.0 / w.zoom, 1.0 / w.zoom, 1.0})

	r.world_ortho = ortho * translate_mat * scale_mat
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
