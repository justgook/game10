package game

bytecode_load :: proc(w: ^World, data: []byte) {
	ctx := &Prefab_Context{world = w}
	reg := &Prefab_Registry{}
	bytecode_register(reg, decode_entity)
}


@(private = "file")
decode_entity :: proc(ctx: ^Prefab_Context, data: []byte) {
	ctx.entity = create_entity(ctx.world)
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
	world:           ^World,
	offset:          int,
	entity:          int,
	animation_index: int,
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


		assert(int(opcode) < len(reg.decoders))
		reg.decoders[opcode](&ctx, data)
	}
}
