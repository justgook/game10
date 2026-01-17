package screen_flash

import sg "../../sokol/gfx"

// Screen Flash Renderer
//
// Renders a fullscreen colored quad with additive blending.
// Uses the fullscreen triangle trick - no vertex buffer needed.

Screen_Flash_Renderer :: struct {
	pip: sg.Pipeline,
}

init :: proc() -> Screen_Flash_Renderer {
	r := Screen_Flash_Renderer{}

	// Pipeline with additive blending
	pip_desc := sg.Pipeline_Desc {
		shader = sg.make_shader(screen_flash_shader_desc(sg.query_backend())),
		primitive_type = .TRIANGLES,
		// Additive blending: src + dst
		colors = {
			0 = {
				blend = {
					enabled          = true,
					src_factor_rgb   = .SRC_ALPHA,
					dst_factor_rgb   = .ONE, // Additive
					src_factor_alpha = .ONE,
					dst_factor_alpha = .ONE,
				},
			},
		},
		// No depth testing for fullscreen overlay
		depth = {write_enabled = false, compare = .ALWAYS},
	}
	r.pip = sg.make_pipeline(pip_desc)

	return r
}

cleanup :: proc(r: ^Screen_Flash_Renderer) {
	sg.destroy_pipeline(r.pip)
}

// Draw the flash overlay
// color: RGBA where A is the flash intensity
draw :: proc(r: ^Screen_Flash_Renderer, color: [4]f32) {
	// Skip if fully transparent
	if color.a <= 0 {
		return
	}

	fs_params := Fs_Params {
		flash_color = color,
	}

	sg.apply_pipeline(r.pip)
	sg.apply_uniforms(UB_fs_params, {ptr = &fs_params, size = size_of(fs_params)})

	// Draw fullscreen triangle (3 vertices, generated from vertex ID)
	sg.draw(0, 3, 1)
}
