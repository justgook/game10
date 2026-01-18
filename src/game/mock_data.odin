package game

import "camera"
import "grid"
import "logic"
import "shape"

create_mock_data :: proc(w: ^World) {
	w.grid = grid.create_grid(-5000 * UNIT, -5000 * UNIT, 5000 * UNIT, 5000 * UNIT, 16 * UNIT)

	player := create_entity(w)
	logic.add_component(&w.velocity, player, Velocity{})
	logic.add_component(&w.position, player, Position{150 * UNIT, 128 * UNIT})
	logic.add_component(&w.sprite, player, Sprite{uv = {0.7410926, 0.45657569, 0.78384799, 0.53101736}})
	logic.add_component(&w.collider, player, shape.Capsule{y = 14 * UNIT, radius = 7 * UNIT, height = 14 * UNIT})
	logic.add_component(&w.input, player, Input{})
	logic.add_component(&w.jump, player, JumpState{})
	logic.add_component(&w.brain, player, Brain{})
	logic.add_component(&w.squash, player, squash_init())
	logic.add_component(&w.blink, player, blink_init())
	logic.add_component(&w.sprite_shake, player, sprite_shake_init())

	// Set up camera to track player
	w.player_entity = player
	camera.camera_track(&w.cam, player, true)
	// Center camera on player's initial position
	camera.camera_center_on(&w.cam, to_pixelf(Position{64 * UNIT, 128 * UNIT}))

	append(&w.segments, Segment{64 * UNIT, 64 * UNIT, 576 * UNIT, 64 * UNIT})
	append(&w.segments, Segment{576 * UNIT, 320 * UNIT, 64 * UNIT, 320 * UNIT})
	append(&w.segments, Segment{64 * UNIT, 64 * UNIT, 64 * UNIT, 320 * UNIT})
	append(&w.segments, Segment{576 * UNIT, 320 * UNIT, 576 * UNIT, 64 * UNIT})

	append(&w.segments, Segment{128 * UNIT, 128 * UNIT, 256 * UNIT, 128 * UNIT})
	append(&w.segments, Segment{320 * UNIT, 192 * UNIT, 448 * UNIT, 192 * UNIT})
	append(&w.segments, Segment{160 * UNIT, 256 * UNIT, 288 * UNIT, 256 * UNIT})
	append(&w.segments, Segment{352 * UNIT, 256 * UNIT, 416 * UNIT, 256 * UNIT})
	append(&w.segments, Segment{448 * UNIT, 128 * UNIT, 512 * UNIT, 128 * UNIT})


	append(&w.segments, Segment{320 * UNIT, 64 * UNIT, 320 * UNIT, 192 * UNIT})
	append(&w.segments, Segment{352 * UNIT, 192 * UNIT, 352 * UNIT, 64 * UNIT})
	append(&w.segments, Segment{416 * UNIT, 256 * UNIT, 416 * UNIT, 192 * UNIT})
	append(&w.segments, Segment{416 * UNIT, 256 * UNIT, 416 * UNIT, 192 * UNIT})
	append(&w.segments, Segment{400 * UNIT, 192 * UNIT, 400 * UNIT, 256 * UNIT})

	for &i in w.segments {
		grid.add_segment(&w.grid, &i)
	}

}
