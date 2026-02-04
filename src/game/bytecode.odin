package game

import "core:fmt"
import "core:mem"
import "logic"

bytecode_load :: proc(w: ^World, data: []byte) {
	ctx := &Prefab_Context{world = w}
	reg := &Prefab_Registry{}

	// Opcode 0: Entity marker
	bytecode_register(reg, decode_entity)
	// Opcode 1: Atlas UVs
	bytecode_register(reg, decode_atlas)
	// Opcode 2: Animations
	bytecode_register(reg, decode_animations)
	// Opcode 3: Tilemap layer
	bytecode_register(reg, decode_tilemap)
	// Opcode 4: Position component
	bytecode_register(reg, proc(ctx: ^Prefab_Context, data: []byte) {decode_comp(ctx, data, &ctx.world.position)})

	bytecode_loader(reg, w, data)
}


@(private = "file")
decode_entity :: proc(ctx: ^Prefab_Context, data: []byte) {
	fmt.println("decode_entity")
	ctx.entity = create_entity(ctx.world)
}

@(private = "file")
decode_comp :: proc(ctx: ^Prefab_Context, data: []byte, storage: ^logic.Component_Storage($T)) {
	comp := (^T)(&data[ctx.offset])^
	ctx.offset += size_of(T)
	fmt.println("setting component", "comp", comp)
	logic.add_component(storage, ctx.entity, comp)
}

@(private = "file")
decode_atlas :: proc(ctx: ^Prefab_Context, data: []byte) {
	count := int((^u32)(&data[ctx.offset])^)
	ctx.offset += size_of(u32)

	// Point directly into the byte data (zero-copy)
	uvs := mem.slice_ptr((^UV)(&data[ctx.offset]), count)
	ctx.offset += count * size_of(UV)

	fmt.println("decoding atlas", "uvs", uvs)
	ctx.world.sprite_atlas = SpriteAtlas {
		uvs = uvs,
	}
}

@(private = "file")
decode_animations :: proc(ctx: ^Prefab_Context, data: []byte) {
	// Header: def_count (u32), frame_count (u32)
	def_count := int((^u32)(&data[ctx.offset])^)
	ctx.offset += size_of(u32)

	frame_count := int((^u32)(&data[ctx.offset])^)
	ctx.offset += size_of(u32)

	// Point directly into byte data (zero-copy)
	defs := mem.slice_ptr((^AnimDef)(&data[ctx.offset]), def_count)
	ctx.offset += def_count * size_of(AnimDef)

	frames := mem.slice_ptr((^AnimFrame)(&data[ctx.offset]), frame_count)
	ctx.offset += frame_count * size_of(AnimFrame)

	fmt.println("decoding animations", "defs", def_count, "frames", frame_count)
	fmt.println("the data", "defs", defs)
	fmt.println("the data", "frames", frames)
	ctx.world.animation_atlas = AnimationAtlas {
		defs   = defs,
		frames = frames,
	}
}

@(private = "file")
decode_tilemap :: proc(ctx: ^Prefab_Context, data: []byte) {
	// Binary format (34 bytes total):
	// [position_x: f32] [position_y: f32]
	// [tile_size_x: f32] [tile_size_y: f32]
	// [tileset_uv_index: u32] [lut_uv_index: u32]
	// [map_width: u32] [map_height: u32]
	
	position := (^[2]f32)(&data[ctx.offset])^
	ctx.offset += size_of([2]f32)
	
	tile_size := (^[2]f32)(&data[ctx.offset])^
	ctx.offset += size_of([2]f32)
	
	tileset_uv_idx := (^u32)(&data[ctx.offset])^
	ctx.offset += size_of(u32)
	
	lut_uv_idx := (^u32)(&data[ctx.offset])^
	ctx.offset += size_of(u32)
	
	map_size := (^[2]u32)(&data[ctx.offset])^
	ctx.offset += size_of([2]u32)
	
	layer := TilemapLayer {
		position       = position,
		tile_size      = tile_size,
		tileset_uv_idx = tileset_uv_idx,
		lut_uv_idx     = lut_uv_idx,
		map_size       = map_size,
	}
	
	append(&ctx.world.tilemaps, layer)
	
	fmt.println("decoding tilemap layer", "pos", position, "tile_size", tile_size, 
		"tileset_uv", tileset_uv_idx, "lut_uv", lut_uv_idx, "map_size", map_size)
}


@(private = "file")
Bytecode_Opcode :: distinct u16


@(private = "file")
Prefab_Decoder :: proc(tx: ^Prefab_Context, data: []byte)


@(private = "file")
Prefab_Registry :: struct {
	decoders: [dynamic]Prefab_Decoder,
}


@(private = "file")
Prefab_Context :: struct {
	world:  ^World,
	offset: int,
	entity: int,
}


@(private = "file")
bytecode_register :: proc(reg: ^Prefab_Registry, d: Prefab_Decoder) -> Bytecode_Opcode {
	idx := len(reg.decoders)
	append(&reg.decoders, d)

	return Bytecode_Opcode(idx)
}

@(private = "file")
bytecode_loader :: proc(reg: ^Prefab_Registry, w: ^World, data: []byte) {
	ctx := Prefab_Context {
		world  = w,
		offset = 0,
		entity = 1,
	}

	for ctx.offset < len(data) {
		opcode := (^Bytecode_Opcode)(&data[ctx.offset])^
		ctx.offset += size_of(Bytecode_Opcode)
		fmt.println("DECODER", "opcode", opcode)


		assert(int(opcode) < len(reg.decoders))
		reg.decoders[opcode](&ctx, data)
	}
}
