package game

// Animation System
//
// Two-level architecture:
// 1. AnimDef - Shared animation definition (frames, timing, looping)
// 2. Animation - Per-entity playback state (current frame, timer, callbacks)
//
// UV coordinates are stored in a shared SpriteAtlas. Animation frames reference
// UVs by index, allowing reuse without duplication.
//
// Usage:
//   // Define frames referencing UV indices from the atlas
//   idle_frames := []AnimFrame{
//       {uv_index = 0, duration = 0.5},  // Uses atlas.uvs[0]
//       {uv_index = 1, duration = 0.5},  // Uses atlas.uvs[1]
//   }
//   idle_def := AnimDef{frames = idle_frames[:], looping = true}
//
//   // Add component to entity
//   logic.add_component(&w.animation, entity, animation_create(&idle_def))
//
//   // Change animation
//   animation_play(&anim, &run_def)

// Single frame of animation
AnimFrame :: struct {
	uv_index: int, // Index into SpriteAtlas.uvs (shared UV storage)
	offset:   [2]int, // Sprite offset adjustment in subpixels
	duration: f32, // Seconds this frame displays
	flip:     Flip, // Flip flags for this frame (FLIP_X, FLIP_Y, FLIP_XY)
}

// Animation definition - shared data, multiple entities can reference same def
AnimDef :: struct {
	frames:  []AnimFrame,
	looping: bool,
}

// Per-entity animation playback state
Animation :: struct {
	def:         ^AnimDef, // Pointer to animation definition (nil = no animation)
	frame_index: int, // Current frame index
	frame_timer: f32, // Time accumulated in current frame
	playing:     bool, // Is animation playing
	speed:       f32, // Playback speed multiplier (1.0 = normal, 0.5 = half speed)
	// Callbacks (optional, can be nil)
	on_loop:     proc(w: ^World, entity: int), // Called when animation loops
	on_frame:    proc(w: ^World, entity: int, frame: int), // Called when frame changes
}

// Animation IDs for registry lookup
AnimId :: enum {
	None,
	// Hero animations
	Hero_Idle,
	Hero_Run,
	Hero_Jump_Up,
	Hero_Jump_Down,
	Hero_Land,
	Hero_Dash,
	Hero_Hurt,
	// Enemy animations
	Enemy_Idle,
	Enemy_Walk,
	Enemy_Hurt,
	Enemy_Death,
}

// Global animation registry - indexed by AnimId
Animation_Registry :: [AnimId]AnimDef

// Create a new Animation component pointing to a definition
animation_create :: proc(def: ^AnimDef) -> Animation {
	return Animation {
		def         = def,
		frame_index = 0,
		frame_timer = 0,
		playing     = true,
		speed       = 1.0,
		on_loop     = nil,
		on_frame    = nil,
	}
}

// Create Animation component in stopped state
animation_create_stopped :: proc(def: ^AnimDef) -> Animation {
	anim := animation_create(def)
	anim.playing = false
	return anim
}

// Start playing an animation from the beginning
animation_play :: proc(anim: ^Animation, def: ^AnimDef) {
	anim.def = def
	anim.frame_index = 0
	anim.frame_timer = 0
	anim.playing = true
}

// Play animation only if it's different from current
animation_play_if_different :: proc(anim: ^Animation, def: ^AnimDef) {
	if anim.def != def {
		animation_play(anim, def)
	}
}

// Stop animation at current frame
animation_stop :: proc(anim: ^Animation) {
	anim.playing = false
}

// Resume animation from current position
animation_resume :: proc(anim: ^Animation) {
	anim.playing = true
}

// Reset animation to first frame
animation_reset :: proc(anim: ^Animation) {
	anim.frame_index = 0
	anim.frame_timer = 0
}

// Check if animation has finished (only meaningful for non-looping)
animation_is_finished :: proc(anim: ^Animation) -> bool {
	if anim.def == nil {
		return true
	}
	if anim.def.looping {
		return false
	}
	return anim.frame_index >= len(anim.def.frames) - 1 && !anim.playing
}

// Get current frame (nil if no animation)
animation_get_frame :: proc(anim: ^Animation) -> ^AnimFrame {
	if anim.def == nil || len(anim.def.frames) == 0 {
		return nil
	}
	return &anim.def.frames[anim.frame_index]
}

// Get animation progress (0.0 to 1.0)
animation_get_progress :: proc(anim: ^Animation) -> f32 {
	if anim.def == nil || len(anim.def.frames) == 0 {
		return 0
	}
	total_frames := len(anim.def.frames)
	if total_frames == 1 {
		return 1.0
	}
	return f32(anim.frame_index) / f32(total_frames - 1)
}

// Set playback speed (1.0 = normal, 2.0 = double speed, 0.5 = half speed)
animation_set_speed :: proc(anim: ^Animation, speed: f32) {
	anim.speed = speed
}

// Helper to calculate total duration of an animation
animdef_total_duration :: proc(def: ^AnimDef) -> f32 {
	if def == nil {
		return 0
	}
	total: f32 = 0
	for &frame in def.frames {
		total += frame.duration
	}
	return total
}
