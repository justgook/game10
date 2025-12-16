package tilemap

import sg "../../sokol/gfx"
import "core:c"
import "core:image"
import "core:math/linalg"


TILEMAP_RENDER_MAX :: 8192
BASE_VERTICES := [?][2]f32{{-.5, -.5}, {-.5, .5}, {.5, -.5}, {.5, .5}}
BASE_INDICES := [?]u16{0, 1, 2, 2, 1, 3}

Tilemap_Manager :: struct {
	instances:  [TILEMAP_RENDER_MAX]Tilemap_Instance,
	count:      int,
	pip:        sg.Pipeline,
	bind:       sg.Bindings,
	atlas_size: [2]f32,
}

Tilemap_Instance :: struct {
	position:   [2]f32, // World position
	tile_size:  [2]f32, // Size of a single tile
	tileset_uv: [4]f32, // UV region in atlas where tileset is stored
	tilemap_uv: [4]f32, // UV region in atlas where tilemap LUT is stored
}

destory_render_tilemap :: proc(manager: ^Tilemap_Manager) {
	free(manager)
}

tilemap_set_texture :: proc(tex0: sg.Image, manager: ^Tilemap_Manager) {
	manager.bind.images[IMG_atlas] = tex0
}

set_atlas_tilemap :: proc(img: ^image.Image, manager: ^Tilemap_Manager) {
	manager.atlas_size = {f32(img.width), f32(img.height)}
	desc := sg.Image_Desc {
		width        = i32(img.width),
		height       = i32(img.height),
		pixel_format = .RGBA8,
	}

	desc.data.subimage[0][0] = {
		ptr  = raw_data(img.pixels.buf),
		size = auto_cast (img.width * img.height * 4),
	}

	tex0 := sg.make_image(desc)

	manager.bind.images[IMG_atlas] = tex0
}

create_render_tilemap :: proc(img: ^image.Image) -> ^Tilemap_Manager {
	manager := new(Tilemap_Manager)
	set_atlas_tilemap(img, manager)
	manager.bind.samplers[SMP_smp] = sg.make_sampler({})

	manager.bind.vertex_buffers[0] = sg.make_buffer(
	{
		usage = sg.Buffer_Usage{vertex_buffer = true, immutable = true},
		// .IMMUTABLE,
		// type = .VERTEXBUFFER,
		data = {ptr = &BASE_VERTICES, size = size_of(BASE_VERTICES)},
	},
	)
	manager.bind.index_buffer = sg.make_buffer(
	{
		usage = sg.Buffer_Usage{index_buffer = true, immutable = true},

		// type = .INDEXBUFFER,
		data = {ptr = &BASE_INDICES, size = size_of(BASE_INDICES)},
	},
	)

	manager.bind.vertex_buffers[1] = sg.make_buffer(
	{
		usage = sg.Buffer_Usage{vertex_buffer = true, stream_update = true},

		// type = .VERTEXBUFFER,
		// usage = .STREAM,
		size = TILEMAP_RENDER_MAX * size_of(Tilemap_Instance),
	},
	)

	pipeline_desc: sg.Pipeline_Desc = {
		shader = sg.make_shader(tilemap_shader_desc(sg.query_backend())),
		cull_mode = .BACK,
		depth = {compare = .LESS_EQUAL, write_enabled = true},
		index_type = .UINT16,
		layout = {
			buffers = {1 = {step_func = .PER_INSTANCE}},
			attrs = {
				ATTR_tilemap_position = {format = .FLOAT2, buffer_index = 0},
				ATTR_tilemap_i_position = {format = .FLOAT2, buffer_index = 1},
				ATTR_tilemap_i_tile_size = {format = .FLOAT2, buffer_index = 1},
				ATTR_tilemap_i_tileset_uv = {format = .FLOAT4, buffer_index = 1},
				ATTR_tilemap_i_tilemap_uv = {format = .FLOAT4, buffer_index = 1},
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

draw_render_tilemap :: proc(manager: ^Tilemap_Manager, ortho: ^linalg.Matrix4f32) {
	if manager.count < 1 {
		return
	}
	vs_params := Vs_Params {
		ortho      = ortho^,
		atlas_size = manager.atlas_size,
	}
	// update instance data
	sg.update_buffer(
		manager.bind.vertex_buffers[1],
		{ptr = &manager.instances, size = c.size_t(manager.count * size_of(Tilemap_Instance))},
	)

	sg.apply_pipeline(manager.pip)
	sg.apply_bindings(manager.bind)
	sg.apply_uniforms(UB_vs_params, {ptr = &vs_params, size = size_of(vs_params)})
	sg.draw(0, 6, manager.count)
}


// Create new tilemap texture from a 2D array of tile indices
create_tilemap_lut :: proc(tile_indices: [][]int) -> (sg.Image, [2]int) {
	height := len(tile_indices)
	if height == 0 {return {}, {0, 0}}

	width := len(tile_indices[0])
	if width == 0 {return {}, {0, 0}}

	// Create image data - using red channel for tile index
	pixels := make([][4]u8, width * height)
	defer delete(pixels)

	for y := 0; y < height; y += 1 {
		row := tile_indices[y]
		for x := 0; x < min(width, len(row)); x += 1 {
			idx := y * width + x
			// Store tile index in red channel
			pixels[idx] = {u8(row[x]), 0, 0, 255}
		}
	}

	desc := sg.Image_Desc {
		width        = i32(width),
		height       = i32(height),
		pixel_format = .RGBA8,
	}

	desc.data.mip_levels[0] = {
		ptr  = raw_data(pixels),
		size = len(pixels) * size_of([4]u8),
	}


	return sg.make_image(desc), {width, height}
}
