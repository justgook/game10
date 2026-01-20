package bytcode

Bytecode_Opcode :: distinct u16

Prefab_Decoder :: proc($A, $B: typeid, ctx: ^Prefab_Context(A, B), data: []byte)


Prefab_Registry :: struct($A, $B: typeid) {
	decoders: [dynamic]Prefab_Decoder(A, B),
}

Prefab_Context :: struct($A, $B: typeid) {
	world:           ^A,
	offset:          int,
	entity:          B,
	animation_index: int,
}

register_loader :: proc(reg: ^Prefab_Registry($A, $B), d: Prefab_Decoder) -> Bytecode_Opcode {
	idx := len(reg.decoders)
	append(&reg.decoders, d)
	return Bytecode_Opcode(idx)
}

load_bytecode :: proc(reg: ^Prefab_Registry, w: ^$T, data: []byte) {
	ctx := Prefab_Context {
		world  = w,
		offset = 0,
		entity = 1,
	}

	for ctx.offset < len(data) {
		opcode := (^Bytecode_Opcode)(&data[ctx.offset])^
		ctx.offset += size_of(Bytecode_Opcode)

		// opcode := read(u16, data, &ctx.offset)

		assert(int(opcode) < len(reg.decoders))
		reg.decoders[opcode](&ctx, data)
	}
}
