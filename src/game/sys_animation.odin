package game

import "logic"

// Animation system - advances animation frames and updates sprite components
//
// This system:
// 1. Advances frame timer based on delta time and speed
// 2. Switches frames when timer exceeds frame duration
// 3. Handles looping and stopping at end
// 4. Updates the entity's Sprite component UV from current frame
// 5. Fires callbacks on loop and frame change

sys_animation :: proc(w: ^World, dt: f32) {
	view := logic.view(&w.animation, &w.sprite)

	for id, anim, sprite in logic.each(&view) {
		// Skip if no animation definition or not playing
		if anim.def == nil || !anim.playing {
			continue
		}

		frames := anim.def.frames
		if len(frames) == 0 {
			continue
		}

		// Store previous frame for callback
		prev_frame := anim.frame_index

		// Advance timer
		anim.frame_timer += dt * anim.speed

		// Get current frame duration
		current_frame := &frames[anim.frame_index]

		// Check if we need to advance frames
		for anim.frame_timer >= current_frame.duration {
			anim.frame_timer -= current_frame.duration
			anim.frame_index += 1

			// Handle end of animation
			if anim.frame_index >= len(frames) {
				if anim.def.looping {
					// Loop back to start
					anim.frame_index = 0
					if anim.on_loop != nil {
						anim.on_loop(w, id)
					}
				} else {
					// Stop at last frame
					anim.frame_index = len(frames) - 1
					anim.frame_timer = 0
					anim.playing = false
					break
				}
			}

			// Update current frame reference for next iteration
			current_frame = &frames[anim.frame_index]
		}

		// Fire frame changed callback if frame changed
		if anim.frame_index != prev_frame && anim.on_frame != nil {
			anim.on_frame(w, id, anim.frame_index)
		}

		// Update sprite component from current animation frame
		frame := &frames[anim.frame_index]
		sprite.uv = atlas_get_uv(&w.sprite_atlas, frame.uv_index)
		sprite.offset = frame.offset
		sprite.flip = frame.flip
	}
}
