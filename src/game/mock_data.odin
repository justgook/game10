package game
import "grid"
import "logic"
import "shape"

create_mock_data :: proc(w: ^World) {
	w.grid = grid.create_grid(-5000 * UNIT, -5000 * UNIT, 5000 * UNIT, 5000 * UNIT, 16 * UNIT)

	player := create_entity(w)
	logic.add_component(&w.velocity, player, Velocity{})
	logic.add_component(&w.position, player, Position{64 * UNIT, 128 * UNIT})
	logic.add_component(&w.sprite, player, Sprite{uv = {0.7410926, 0.45657569, 0.78384799, 0.53101736}})
	logic.add_component(&w.collider, player, shape.Capsule{y = 14 * UNIT, radius = 7 * UNIT, height = 14 * UNIT})
	logic.add_component(&w.input, player, Input{})
	logic.add_component(&w.jump, player, JumpState{})
	logic.add_component(&w.brain, player, Brain{})


	append(&w.segments, Segment{32 * UNIT, 64 * UNIT, 128 * UNIT, 64 * UNIT})

	for &i in w.segments {
		grid.add_segment(&w.grid, &i)
	}

}
