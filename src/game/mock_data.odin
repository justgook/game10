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
	// Combat components
	logic.add_component(&w.hitpoint, player, hitpoint_init(10))
	logic.add_component(
		&w.player_hurt,
		player,
		shape.Capsule{y = 14 * UNIT, radius = 6 * UNIT, height = 12 * UNIT},
	)
	logic.add_component(&w.on_hurt, player, on_hurt_fn[.Player])
	logic.add_component(&w.trigger, player, trigger_init_gun())

	// Set up camera to track player
	w.player_entity = player
	camera.camera_track(&w.cam, player, true)
	// Center camera on player's initial position
	camera.camera_center_on(&w.cam, to_pixelf(Position{64 * UNIT, 128 * UNIT}))

	// Create enemy entity
	enemy := create_entity(w)
	logic.add_component(&w.position, enemy, Position{300 * UNIT, 128 * UNIT})
	logic.add_component(&w.velocity, enemy, Velocity{})
	logic.add_component(&w.sprite, enemy, Sprite{uv = {0.7410926, 0.45657569, 0.78384799, 0.53101736}}) // Same sprite for now
	logic.add_component(&w.collider, enemy, shape.Capsule{y = 14 * UNIT, radius = 7 * UNIT, height = 14 * UNIT})
	logic.add_component(&w.jump, enemy, JumpState{})
	// Combat components
	logic.add_component(&w.hitpoint, enemy, hitpoint_init(5))
	logic.add_component(&w.enemy_hurt, enemy, shape.Capsule{y = 14 * UNIT, radius = 8 * UNIT, height = 16 * UNIT})
	logic.add_component(&w.on_hurt, enemy, on_hurt_fn[.Enemy])
	// Enemy can damage player on contact
	logic.add_component(&w.enemy_hit, enemy, shape.Circle{y = 14 * UNIT, radius = 10 * UNIT})
	logic.add_component(&w.on_hit, enemy, on_hit_fn[.Enemy_Collider])
	// Visual feedback components
	logic.add_component(&w.squash, enemy, squash_init())
	logic.add_component(&w.blink, enemy, blink_init())
	logic.add_component(&w.sprite_shake, enemy, sprite_shake_init())

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
