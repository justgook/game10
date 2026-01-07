package game
import "grid"
import "logic"

create_mock_data :: proc(w: ^World) {
	w.grid = grid.create_grid(-5000 * UNIT, -5000 * UNIT, 5000 * UNIT, 5000 * UNIT, 16 * UNIT)

	player := create_entity(w)
	logic.add_component(&w.velocity, player, Velocity{10, 0})
	logic.add_component(&w.position, player, Position{0, 0})
	logic.add_component(&w.sprite, player, Sprite{uv = {0.7410926, 0.45657569, 0.78384799, 0.53101736}})

	append(&w.segments, Segment{32 * UNIT, 64 * UNIT, 128 * UNIT, 128 * UNIT})

	for &i in w.segments {
		grid.add_segment(&w.grid, &i)
	}

}
