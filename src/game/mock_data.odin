package game

import "camera"
import "grid"
import "logic"
import "shape"

// ============================================================================
// Mock Sprite Atlas
// ============================================================================
// All UV coordinates stored in one place. Animation frames reference by index.
// These are placeholders - update with real UV coordinates from your atlas.

// Placeholder UV (using the original sprite coordinates)
// Original: {0.7410926, 0.45657569, 0.78384799, 0.53101736}
@(private = "file")
PLACEHOLDER_UV :: UV{0.7410926, 0.45657569, 0.78384799, 0.53101736}

// UV indices (for documentation/reference)
UV_HERO_IDLE_1 :: 0
UV_HERO_IDLE_2 :: 1
UV_HERO_RUN_1 :: 2
UV_HERO_RUN_2 :: 3
UV_HERO_RUN_3 :: 4
UV_HERO_RUN_4 :: 5
UV_HERO_JUMP_UP :: 6
UV_HERO_JUMP_DOWN :: 7
UV_HERO_LAND :: 8
UV_HERO_HURT :: 9
UV_ENEMY_IDLE :: 10
UV_ENEMY_WALK_1 :: 11
UV_ENEMY_WALK_2 :: 12
UV_ENEMY_HURT :: 13

// The actual UV atlas - all coordinates stored here
// TODO: Replace placeholder UVs with real coordinates from your sprite atlas
@(private = "file")
mock_atlas_uvs := [?]UV {
	// Hero animations
	PLACEHOLDER_UV, // 0: Hero idle 1
	PLACEHOLDER_UV, // 1: Hero idle 2
	PLACEHOLDER_UV, // 2: Hero run 1
	PLACEHOLDER_UV, // 3: Hero run 2
	PLACEHOLDER_UV, // 4: Hero run 3
	PLACEHOLDER_UV, // 5: Hero run 4
	PLACEHOLDER_UV, // 6: Hero jump up
	PLACEHOLDER_UV, // 7: Hero jump down
	PLACEHOLDER_UV, // 8: Hero land
	PLACEHOLDER_UV, // 9: Hero hurt
	// Enemy animations
	PLACEHOLDER_UV, // 10: Enemy idle
	PLACEHOLDER_UV, // 11: Enemy walk 1
	PLACEHOLDER_UV, // 12: Enemy walk 2
	PLACEHOLDER_UV, // 13: Enemy hurt
}

// ============================================================================
// Mock Animation Definitions (using UV indices)
// ============================================================================

// Standard offset for character sprites
@(private = "file")
CHAR_OFFSET :: [2]int{0, 16 * UNIT}

// Animation definition indices (for referencing defs in the atlas)
ANIM_HERO_IDLE :: 0
ANIM_HERO_RUN :: 1
ANIM_HERO_JUMP_UP :: 2
ANIM_HERO_JUMP_DOWN :: 3
ANIM_HERO_LAND :: 4
ANIM_HERO_HURT :: 5
ANIM_ENEMY_WALK :: 6
ANIM_ENEMY_IDLE :: 7

// All animation frames stored contiguously
// Frame indices:
//   0-1:  Hero idle (2 frames)
//   2-5:  Hero run (4 frames)
//   6:    Hero jump up (1 frame)
//   7:    Hero jump down (1 frame)
//   8:    Hero land (1 frame)
//   9:    Hero hurt (1 frame)
//   10-11: Enemy walk (2 frames)
//   12:   Enemy idle (1 frame)
@(private = "file")
mock_anim_frames := [?]AnimFrame {
	// Hero idle (frames 0-1)
	{uv_index = UV_HERO_IDLE_1, offset = CHAR_OFFSET, duration = 0.5, flip = FLIP_NONE},
	{uv_index = UV_HERO_IDLE_2, offset = {0, 15 * UNIT}, duration = 0.5, flip = FLIP_NONE},
	// Hero run (frames 2-5)
	{uv_index = UV_HERO_RUN_1, offset = CHAR_OFFSET, duration = 0.1, flip = FLIP_NONE},
	{uv_index = UV_HERO_RUN_2, offset = {0, 14 * UNIT}, duration = 0.1, flip = FLIP_NONE},
	{uv_index = UV_HERO_RUN_3, offset = CHAR_OFFSET, duration = 0.1, flip = FLIP_NONE},
	{uv_index = UV_HERO_RUN_4, offset = {0, 14 * UNIT}, duration = 0.1, flip = FLIP_NONE},
	// Hero jump up (frame 6)
	{uv_index = UV_HERO_JUMP_UP, offset = CHAR_OFFSET, duration = 1.0, flip = FLIP_NONE},
	// Hero jump down (frame 7)
	{uv_index = UV_HERO_JUMP_DOWN, offset = CHAR_OFFSET, duration = 1.0, flip = FLIP_NONE},
	// Hero land (frame 8)
	{uv_index = UV_HERO_LAND, offset = {0, 18 * UNIT}, duration = 0.15, flip = FLIP_NONE},
	// Hero hurt (frame 9)
	{uv_index = UV_HERO_HURT, offset = CHAR_OFFSET, duration = 0.3, flip = FLIP_NONE},
	// Enemy walk (frames 10-11)
	{uv_index = UV_ENEMY_WALK_1, offset = CHAR_OFFSET, duration = 0.2, flip = FLIP_NONE},
	{uv_index = UV_ENEMY_WALK_2, offset = {0, 15 * UNIT}, duration = 0.2, flip = FLIP_NONE},
	// Enemy idle (frame 12)
	{uv_index = UV_ENEMY_IDLE, offset = CHAR_OFFSET, duration = 0.5, flip = FLIP_NONE},
}

// Animation definitions referencing frame ranges
@(private = "file")
mock_anim_defs := [?]AnimDef {
	{frame_start = 0, frame_count = 2, looping = true}, // ANIM_HERO_IDLE
	{frame_start = 2, frame_count = 4, looping = true}, // ANIM_HERO_RUN
	{frame_start = 6, frame_count = 1, looping = false}, // ANIM_HERO_JUMP_UP
	{frame_start = 7, frame_count = 1, looping = false}, // ANIM_HERO_JUMP_DOWN
	{frame_start = 8, frame_count = 1, looping = false}, // ANIM_HERO_LAND
	{frame_start = 9, frame_count = 1, looping = false}, // ANIM_HERO_HURT
	{frame_start = 10, frame_count = 2, looping = true}, // ANIM_ENEMY_WALK
	{frame_start = 12, frame_count = 1, looping = true}, // ANIM_ENEMY_IDLE
}

// Hero animation set (pointers into mock_anim_defs)
@(private = "file")
hero_anims := AnimSet {
	idle      = &mock_anim_defs[ANIM_HERO_IDLE],
	run       = &mock_anim_defs[ANIM_HERO_RUN],
	jump_up   = &mock_anim_defs[ANIM_HERO_JUMP_UP],
	jump_down = &mock_anim_defs[ANIM_HERO_JUMP_DOWN],
	land      = &mock_anim_defs[ANIM_HERO_LAND],
	hurt      = &mock_anim_defs[ANIM_HERO_HURT],
	dash      = nil, // TODO: Add dash animation
}

// Enemy animation set
@(private = "file")
enemy_anims := AnimSet {
	idle      = &mock_anim_defs[ANIM_ENEMY_IDLE],
	run       = &mock_anim_defs[ANIM_ENEMY_WALK],
	jump_up   = nil,
	jump_down = nil,
	land      = nil,
	hurt      = nil,
	dash      = nil,
}

// ============================================================================
// World Creation
// ============================================================================

create_mock_data :: proc(w: ^World) {
	// Initialize sprite atlas with UV coordinates
	w.sprite_atlas = SpriteAtlas {
		uvs = mock_atlas_uvs[:],
	}

	// Initialize animation atlas
	w.animation_atlas = AnimationAtlas {
		defs   = mock_anim_defs[:],
		frames = mock_anim_frames[:],
	}

	w.grid = grid.create_grid(-5000 * UNIT, -5000 * UNIT, 5000 * UNIT, 5000 * UNIT, 16 * UNIT)

	// Create player entity
	player := create_entity(w)
	logic.add_component(&w.velocity, player, Velocity{})
	logic.add_component(&w.position, player, Position{150 * UNIT, 128 * UNIT})
	logic.add_component(
		&w.sprite,
		player,
		Sprite{offset = CHAR_OFFSET, uv = PLACEHOLDER_UV, flip = FLIP_NONE},
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
	logic.add_component(&w.animation, player, animation_create(&mock_anim_defs[ANIM_HERO_IDLE]))
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
		Sprite{offset = CHAR_OFFSET, uv = PLACEHOLDER_UV, flip = FLIP_NONE},
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
	// Animation components
	logic.add_component(&w.animation, enemy, animation_create(&mock_anim_defs[ANIM_ENEMY_WALK]))
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
