package sprites

import sg "../../sokol/gfx"
import "core:c"
import "core:math/linalg"


SPRITE_RENDER_MAX :: 8192
BASE_VERTICES := [?][2]f32{{-.5, -.5}, {-.5, .5}, {.5, -.5}, {.5, .5}}
BASE_INDICES := [?]u16{0, 1, 2, 2, 1, 3}

Sprite_Instance :: struct {
	pos:     [2]f32,
	z:       f32,
	opacity: f32,
	flip:    u8,
	size:    [2]f32,
	uv:      [4]f32,
}

Sprites :: struct {
	instances: [SPRITE_RENDER_MAX]Sprite_Instance,
	count:     int,
	pip:       sg.Pipeline,
	bind:      sg.Bindings,
}

sprites_cleanup :: proc(manager: ^Sprites) {
    sg.destroy_pipeline(manager.pip)
    free(manager)
}

sprites_set_texture :: proc(tex0: sg.Image, manager: ^Sprites) {
	manager.bind.views[VIEW_tex0] = sg.make_view({texture = {image = tex0}})
}

sprites_init :: proc() -> ^Sprites {
	manager := new(Sprites)
	manager.bind.samplers[SMP_default_sampler] = sg.make_sampler({})

	manager.bind.vertex_buffers[0] = sg.make_buffer(
		{
			usage = sg.Buffer_Usage{vertex_buffer = true, immutable = true},
			data = {ptr = &BASE_VERTICES, size = size_of(BASE_VERTICES)},
		},
	)

	manager.bind.index_buffer = sg.make_buffer(
		{
			usage = sg.Buffer_Usage{index_buffer = true, immutable = true},
			data = {ptr = &BASE_INDICES, size = size_of(BASE_INDICES)},
		},
	)

	manager.bind.vertex_buffers[1] = sg.make_buffer(
		{
			usage = sg.Buffer_Usage{vertex_buffer = true, stream_update = true},
			size = SPRITE_RENDER_MAX * size_of(Sprite_Instance),
		},
	)

	pipeline_desc: sg.Pipeline_Desc = {
		shader = sg.make_shader(sprite_shader_desc(sg.query_backend())),
		cull_mode = .BACK,
		depth = {compare = .LESS_EQUAL, write_enabled = true},
		index_type = .UINT16,
		layout = {
			buffers = {1 = {step_func = .PER_INSTANCE}},
			attrs = {
				ATTR_sprite_pos = {format = .FLOAT2, buffer_index = 0},
				ATTR_sprite_inst_pos = {format = .FLOAT2, buffer_index = 1},
				ATTR_sprite_inst_z = {format = .FLOAT, buffer_index = 1},
				ATTR_sprite_inst_opacity = {format = .FLOAT, buffer_index = 1},
				ATTR_sprite_inst_flip_flags = {format = .UBYTE4, buffer_index = 1},
				ATTR_sprite_inst_size = {format = .FLOAT2, buffer_index = 1},
				ATTR_sprite_inst_uv = {format = .FLOAT4, buffer_index = 1},
			},
		},
	}

	blend_state: sg.Blend_State = {
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

	manager.pip = sg.make_pipeline(pipeline_desc)

	return manager
}

sprites_draw :: proc(manager: ^Sprites, ortho: ^linalg.Matrix4f32) {
	if manager.count < 1 {
		return
	}

	vs_params := Vs_Params {
		ortho = ortho^,
	}

	// update instance data
	sg.update_buffer(
		manager.bind.vertex_buffers[1],
		{ptr = &manager.instances, size = c.size_t(manager.count * size_of(Sprite_Instance))},
	)

	sg.apply_pipeline(manager.pip)
	sg.apply_bindings(manager.bind)
	sg.apply_uniforms(UB_vs_params, {ptr = &vs_params, size = size_of(vs_params)})
	sg.draw(0, 6, manager.count)
}
