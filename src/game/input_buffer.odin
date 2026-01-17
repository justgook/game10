package game

// Input Buffering & Coyote Time
// 
// These two systems work together to make jumping feel responsive:
//
// 1. INPUT BUFFERING: If you press jump slightly BEFORE landing, the jump
//    is buffered and executes when you land. Prevents "I pressed jump!" frustration.
//
// 2. COYOTE TIME: If you walk off a ledge, you have a brief grace period where
//    you can still jump. Named after Wile E. Coyote running off cliffs.
//
// Both are measured in frames at 60fps:
// - 6 frames = 0.1 seconds (tight, responsive)
// - 9 frames = 0.15 seconds (forgiving)
// - 12 frames = 0.2 seconds (very forgiving)

// Configuration
JUMP_BUFFER_FRAMES :: 8   // How long to remember a jump press (~0.13s)
COYOTE_TIME_FRAMES :: 6   // Grace period after leaving ground (~0.1s)

// Jump input state with buffering and coyote time
JumpInput :: struct {
    // Current frame input
    pressed:              bool,  // Is jump button held this frame
    just_pressed:         bool,  // Was jump button pressed this frame (not held from last)
    
    // Input buffer - remembers recent jump presses
    buffer_frames:        int,   // Frames remaining in jump buffer (counts down)
    
    // Coyote time - grace period after leaving ground
    coyote_frames:        int,   // Frames remaining where we can still jump (counts down)
    was_grounded:         bool,  // Was grounded last frame (to detect leaving ground)
}

// Call this every frame to update jump input state
// Returns true if a jump should be executed this frame
jump_input_update :: proc(input: ^JumpInput, is_grounded: bool, jump_button_down: bool) -> bool {
    // Update press state
    input.just_pressed = jump_button_down && !input.pressed
    input.pressed = jump_button_down
    
    // Update input buffer
    if input.just_pressed {
        input.buffer_frames = JUMP_BUFFER_FRAMES
    } else if input.buffer_frames > 0 {
        input.buffer_frames -= 1
    }
    
    // Update coyote time
    if is_grounded {
        // Reset coyote time while grounded
        input.coyote_frames = COYOTE_TIME_FRAMES
    } else if input.was_grounded && !is_grounded {
        // Just left ground - start coyote countdown
        // (coyote_frames already set from being grounded)
    } else if input.coyote_frames > 0 {
        // In air, count down coyote time
        input.coyote_frames -= 1
    }
    
    input.was_grounded = is_grounded
    
    // Check if we should jump
    // Jump if: (grounded OR in coyote time) AND (just pressed OR buffered input)
    can_jump := is_grounded || input.coyote_frames > 0
    wants_jump := input.just_pressed || input.buffer_frames > 0
    
    if can_jump && wants_jump {
        // Consume the buffer and coyote time
        input.buffer_frames = 0
        input.coyote_frames = 0
        return true
    }
    
    return false
}

// Reset jump input (e.g., when respawning)
jump_input_reset :: proc(input: ^JumpInput) {
    input^ = JumpInput{}
}

// Check if we're in coyote time (useful for visual feedback)
jump_input_in_coyote :: proc(input: ^JumpInput) -> bool {
    return input.coyote_frames > 0 && !input.was_grounded
}

// Check if we have a buffered jump (useful for visual feedback)
jump_input_has_buffer :: proc(input: ^JumpInput) -> bool {
    return input.buffer_frames > 0
}
