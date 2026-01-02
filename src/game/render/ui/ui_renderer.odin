package ui

import sapp "../../sokol/app"
import sg "../../sokol/gfx"
import microui "./microui2"
import "core:c"
import "core:fmt"


BASE_VERTICES := [?][2]f32{{-.5, -.5}, {-.5, .5}, {.5, -.5}, {.5, .5}}

BASE_INDICES := [?]u16{0, 1, 2, 2, 1, 3}


UI_MAX_QUADS :: 8192

Ui_Render_Instance :: struct #packed {
	position: [2]f32, // Screen position where to place this quad
	size:     [2]f32, // Width and height of this quad
	uv:       [4]f32, // Atlas coordinates (x, y, width, height)
	color:    [4]f32, // RGBA color
	clip:     [4]f32,
}


@(private = "file")
ui_push_quad :: proc(
	ui_state: ^Ui_State,
	dst: microui.Rect,
	src: microui.Rect,
	c: microui.Color,
	clip: [4]f32,
) {
	item := &ui_state.instances[ui_state.count]
	item.color = {f32(c.r) / 255, f32(c.g) / 255, f32(c.b) / 255, f32(c.a) / 255}
	item.position = {f32(dst.x), f32(dst.y)}
	item.size = {f32(dst.w), f32(dst.h)}
	item.uv = {
		f32(src.x) / microui.DEFAULT_ATLAS_WIDTH,
		f32(src.y) / microui.DEFAULT_ATLAS_WIDTH,
		f32(src.w) / microui.DEFAULT_ATLAS_WIDTH,
		f32(src.h) / microui.DEFAULT_ATLAS_WIDTH,
	}
	item.clip = clip

	ui_state.count += 1
}

@(private = "file")
ui_draw_text :: proc(
	ui_state: ^Ui_State,
	text: string,
	pos: microui.Vec2,
	color: microui.Color,
	clip: [4]f32,
) {
	dst := microui.Rect{pos.x, pos.y, 0, 0}
	for ch in text {
		// Skip UTF-8 continuation bytes
		if (ch & 0xc0) == 0x80 {continue}

		// Convert to ASCII and clamp to 127
		chr := min(cast(u8)ch, 127)

		// Get the glyph rect from atlas
		src := microui.default_atlas[microui.DEFAULT_ATLAS_FONT + int(chr)]

		dst.w = src.w
		dst.h = src.h

		ui_push_quad(ui_state, dst, src, color, clip)
		dst.x += dst.w
	}
}


@(private = "file")
ui_draw_icon :: proc(
	ui_state: ^Ui_State,
	id: microui.Icon,
	rect: microui.Rect,
	color: microui.Color,
	clip: [4]f32,
) {
	src := microui.default_atlas[int(id)]
	x := rect.x + (rect.w - src.w) / 2
	y := rect.y + (rect.h - src.h) / 2
	ui_push_quad(ui_state, microui.Rect{x, y, src.w, src.h}, src, color, clip)
}

draw_ui :: proc(ui_state: ^Ui_State) {
	ctx := &ui_state.ctx
	ui_state.count = 0
	white := microui.default_atlas[microui.DEFAULT_ATLAS_WHITE]
	screen_size := [2]f32{sapp.widthf(), sapp.heightf()}
	clip := [4]f32{0, 0, screen_size.x, screen_size.y}

	cmd: ^microui.Command
	for variant in microui.next_command_iterator(ctx, &cmd) {
		switch v in variant {
		case ^microui.Command_Text:
			// v.container_id
			ui_draw_text(ui_state, v.str, v.pos, v.color, clip)
		case ^microui.Command_Clip:
			clip = {f32(v.rect.x), f32(v.rect.y), f32(v.rect.w), f32(v.rect.h)}
		case ^microui.Command_Rect:
			ui_push_quad(ui_state, v.rect, white, v.color, clip)
		case ^microui.Command_Jump:
		case ^microui.Command_Icon:
			ui_draw_icon(ui_state, v.id, v.rect, v.color, clip)
		}
	}

	if ui_state.count < 1 {
		return
	}

	sg.update_buffer(
		ui_state.bind.vertex_buffers[1],
		{ptr = &ui_state.instances, size = c.size_t(ui_state.count * size_of(Ui_Render_Instance))},
	)

	vs_params := Vs_Params {
		screen_size = screen_size,
	}
	sg.apply_pipeline(ui_state.pip)
	sg.apply_bindings(ui_state.bind)
	sg.apply_uniforms(UB_vs_params, {ptr = &vs_params, size = size_of(Vs_Params)})
	sg.draw(0, 6, ui_state.count)
}

@(private = "file")
ui_init_texture :: proc() -> sg.View {
	desc := sg.Image_Desc {
		width        = microui.DEFAULT_ATLAS_WIDTH,
		height       = microui.DEFAULT_ATLAS_HEIGHT,
		pixel_format = .R8,
	}

	desc.data.mip_levels[0] = {
		ptr  = raw_data(microui.default_atlas_alpha[:]),
		size = microui.DEFAULT_ATLAS_WIDTH * microui.DEFAULT_ATLAS_HEIGHT, // Size in bytes for R8 format is just w*h
	}

	img := sg.make_image(desc)
	return sg.make_view({texture = {image = img}})
}

ui_init_renderer :: proc(ui_state: ^Ui_State) {
	ui_state.ctx.text_width = microui.default_atlas_text_width
	ui_state.ctx.text_height = microui.default_atlas_text_height


	ui_state.bind.views[VIEW_atlas] = ui_init_texture()
	ui_state.bind.samplers[SMP_atlas_smp] = sg.make_sampler({})

	ui_state.bind.vertex_buffers[0] = sg.make_buffer(
		{
			usage = sg.Buffer_Usage{vertex_buffer = true, immutable = true},
			data = {ptr = &BASE_VERTICES, size = size_of(BASE_VERTICES)},
		},
	)
	ui_state.bind.index_buffer = sg.make_buffer(
		{
			usage = sg.Buffer_Usage{index_buffer = true, immutable = true},
			data = {ptr = &BASE_INDICES, size = size_of(BASE_INDICES)},
		},
	)

	ui_state.bind.vertex_buffers[1] = sg.make_buffer(
		{
			usage = sg.Buffer_Usage{vertex_buffer = true, stream_update = true},
			size = UI_MAX_QUADS * size_of(Ui_Render_Instance),
		},
	)

	pipeline_desc: sg.Pipeline_Desc = {
		shader = sg.make_shader(microui_shader_desc(sg.query_backend())),
		index_type = .UINT16,
		//cull_mode = .BACK,
		//depth = {compare = .LESS_EQUAL, write_enabled = true},
		//depth = {compare = .ALWAYS, write_enabled = false},
		layout = {
			buffers = {1 = {step_func = .PER_INSTANCE}},
			attrs = {
				ATTR_microui_position = {format = .FLOAT2, buffer_index = 0},
				ATTR_microui_i_position = {format = .FLOAT2, buffer_index = 1},
				ATTR_microui_i_size = {format = .FLOAT2, buffer_index = 1},
				ATTR_microui_i_uv = {format = .FLOAT4, buffer_index = 1},
				ATTR_microui_i_color = {format = .FLOAT4, buffer_index = 1},
				ATTR_microui_i_clip = {format = .FLOAT4, buffer_index = 1},
			},
		},
	}
	blend_state: sg.Blend_State = { 	// Proper alpha blending
		enabled          = true,
		src_factor_rgb   = .SRC_ALPHA,
		dst_factor_rgb   = .ONE_MINUS_SRC_ALPHA,
		op_rgb           = .ADD,
		src_factor_alpha = .ONE,
		dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
		op_alpha         = .ADD,
	}

	pipeline_desc.colors[0] = {
		blend = blend_state,
	}

	ui_state.pip = sg.make_pipeline(pipeline_desc)
}
