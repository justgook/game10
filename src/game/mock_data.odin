package game

import "camera"
import "grid"
import "logic"
import "shape"

// ============================================================================
// Animation Atlas Indices
// ============================================================================
// These indices map to animations in the animation_atlas.
// Order follows AnimSetPlatformer struct layout with Right/Left pairs.

// Placeholder UV for sprites that don't have real animation yet
@(private = "file")
PLACEHOLDER_UV :: UV{0.7410926, 0.45657569, 0.78384799, 0.53101736}

// Standard offset for character sprites
@(private = "file")
CHAR_OFFSET :: [2]i32{0, 16 * UNIT}

// ============================================================================
// Animation Sets (created from animation_atlas)
// ============================================================================

// Hero animation set - created from animation_atlas
// Initialized in create_mock_data after atlas is set up
@(private = "file")
hero_anims: AnimSetPlatformer

// Enemy animation set - reuses hero animations for now
// TODO: Add proper enemy animations
@(private = "file")
enemy_anims: AnimSetPlatformer

// Helper to create AnimSetPlatformer from animation_atlas indices
@(private = "file")
create_hero_animset :: proc(atlas: ^AnimationAtlas) -> AnimSetPlatformer {
	return AnimSetPlatformer {
		idle = {.Right = atlas_get_anim(atlas, 0), .Left = atlas_get_anim(atlas, 1)},
		run = {.Right = atlas_get_anim(atlas, 2), .Left = atlas_get_anim(atlas, 3)},
		jump_up = {.Right = atlas_get_anim(atlas, 4), .Left = atlas_get_anim(atlas, 5)},
		jump_down = {.Right = atlas_get_anim(atlas, 6), .Left = atlas_get_anim(atlas, 7)},
		land = {.Right = atlas_get_anim(atlas, 8), .Left = atlas_get_anim(atlas, 9)},
		dash = {.Right = atlas_get_anim(atlas, 10), .Left = atlas_get_anim(atlas, 11)},
		hurt = {.Right = atlas_get_anim(atlas, 12), .Left = atlas_get_anim(atlas, 13)},
	}
}

// ============================================================================
// World Creation
// ============================================================================

create_mock_data :: proc(w: ^World) {
	// Note: animation_atlas and sprite_atlas are populated by bytecode_load
	// from binary game data. We just need to create AnimSets from the atlas.

	w.grid = grid.create_grid(-5000 * UNIT, -5000 * UNIT, 5000 * UNIT, 5000 * UNIT, 16 * UNIT)

	// Create animation sets from atlas
	// These reference AnimDefs in the animation_atlas by index
	hero_anims = create_hero_animset(&w.animation_atlas)
	// Enemy uses hero animations for now (TODO: add proper enemy animations)
	enemy_anims = create_hero_animset(&w.animation_atlas)

	// Get initial animation def for entities
	initial_anim := atlas_get_anim(&w.animation_atlas, 1)

	// Create player entity
	player := create_entity(w)
	logic.add_component(&w.velocity, player, Velocity{})
	logic.add_component(&w.position, player, Position{150 * UNIT, 128 * UNIT})
	logic.add_component(
		&w.sprite,
		player,
		Sprite {
			offset = [2]int{int(CHAR_OFFSET[0]), int(CHAR_OFFSET[1])},
			uv = PLACEHOLDER_UV,
			flip = FLIP_NONE,
		},
	)
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
		shape.Capsule{y = 10 * UNIT, radius = 6 * UNIT, height = 14 * UNIT},
	)
	logic.add_component(&w.on_hurt, player, on_hurt_fn[.Player])
	logic.add_component(&w.trigger, player, trigger_init_gun())
	// Animation components
	logic.add_component(&w.animation, player, animation_create(initial_anim))
	logic.add_component(&w.anim_controller, player, anim_controller_create(&hero_anims))

	// Set up camera to track player
	w.player_entity = player
	camera.camera_track(&w.cam, player, true)
	camera.camera_center_on(&w.cam, to_pixelf(Position{64 * UNIT, 128 * UNIT}))

	// Create enemy entity
	enemy := create_entity(w)
	logic.add_component(&w.position, enemy, Position{300 * UNIT, 128 * UNIT})
	logic.add_component(&w.velocity, enemy, Velocity{})
	logic.add_component(
		&w.sprite,
		enemy,
		Sprite {
			offset = [2]int{int(CHAR_OFFSET[0]), int(CHAR_OFFSET[1])},
			uv = PLACEHOLDER_UV,
			flip = FLIP_NONE,
		},
	)
	logic.add_component(&w.collider, enemy, shape.Capsule{y = 14 * UNIT, radius = 7 * UNIT, height = 14 * UNIT})
	logic.add_component(&w.jump, enemy, JumpState{})
	// AI brain (non-zero = AI controlled, walks and turns at walls)
	logic.add_component(&w.brain, enemy, Brain(1))
	logic.add_component(&w.input, enemy, Input{x = -1}) // Start walking left
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
	// Animation components (uses hero animations for now)
	logic.add_component(&w.animation, enemy, animation_create(initial_anim))
	logic.add_component(&w.anim_controller, enemy, anim_controller_create(&enemy_anims))

	// Level geometry
	append(&w.segments, Segment{64 * UNIT, 64 * UNIT, 576 * UNIT, 64 * UNIT})
	append(&w.segments, Segment{576 * UNIT, 320 * UNIT, 64 * UNIT, 320 * UNIT})
	append(&w.segments, Segment{64 * UNIT, 320 * UNIT, 64 * UNIT, 64 * UNIT})
	append(&w.segments, Segment{576 * UNIT, 64 * UNIT, 576 * UNIT, 320 * UNIT})

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
