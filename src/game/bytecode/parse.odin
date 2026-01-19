package bytcode

World :: struct {}
Entity_ID :: int

Opcode :: distinct u16
Prefab_Decoder :: proc(ctx: ^Prefab_Context, data: []byte)

Prefab_Registry :: struct {
	decoders: [dynamic]Prefab_Decoder,
}

Prefab_Context :: struct {
	world:           ^World,
	offset:          int,
	entity:          Entity_ID,
	animation_index: int,
}

register :: proc(reg: ^Prefab_Registry, d: Prefab_Decoder) -> Opcode {
	idx := len(reg.decoders)
	append(&reg.decoders, d)
	return Opcode(idx)
}

load :: proc(reg: ^Prefab_Registry, w: ^World, data: []byte) {
	ctx := Prefab_Context {
		world  = w,
		offset = 0,
		entity = 1,
	}

	for ctx.offset < len(data) {
		opcode := (^Opcode)(&data[ctx.offset])^
		ctx.offset += size_of(Opcode)

		// opcode := read(u16, data, &ctx.offset)

		assert(int(opcode) < len(reg.decoders))
		reg.decoders[opcode](&ctx, data)
	}
}
