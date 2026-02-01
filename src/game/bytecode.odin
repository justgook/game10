package game

import "core:fmt"
import "core:mem"
import "logic"

bytecode_load :: proc(w: ^World, data: []byte) {
	ctx := &Prefab_Context{world = w}
	reg := &Prefab_Registry{}

	bytecode_register(reg, decode_entity)
	bytecode_register(reg, decode_atlas)
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
