package game

import "core:math"

// Entity Blink Effect
//
// Produces a short color flash on entities (typically white when damaged).
// The blink color is added to the sprite's existing color, making it flash.
//
// Based on the gamefeel demo implementation:
// - Set a blink color with intensity
// - Color decays over time with different rates per channel
// - Results in a quick flash that fades naturally

// Blink component - stores the current blink color
Blink :: struct {
    color: [3]f32,     // RGB color to add (0-1 range)
    intensity: f32,    // Current intensity (0-1, decays over time)
    keep_frames: int,  // Frames to keep full intensity before decay
}

// Initialize with no blink
blink_init :: proc() -> Blink {
    return Blink{}
}

// Trigger a blink with a color
// Common colors:
//   White: {1, 1, 1} - damage flash
//   Red:   {1, 0, 0} - critical hit
//   Blue:  {0, 0.5, 1} - heal/buff
blink_trigger :: proc(b: ^Blink, r, g, blue: f32, keep_frames: int = 4) {
    b.color = {r, g, blue}
    b.intensity = 1.0
    b.keep_frames = keep_frames
}

// Convenience functions for common blink types
blink_white :: proc(b: ^Blink) {
    blink_trigger(b, 1, 1, 1, 4)
}

blink_red :: proc(b: ^Blink) {
    blink_trigger(b, 1, 0.2, 0.2, 4)
}

blink_blue :: proc(b: ^Blink) {
    blink_trigger(b, 0.2, 0.5, 1, 4)
}

blink_yellow :: proc(b: ^Blink) {
    blink_trigger(b, 1, 0.9, 0.3, 4)
}

// Update blink - call every frame
// Returns true if still blinking
blink_update :: proc(b: ^Blink) -> bool {
    if b.intensity <= 0 {
        return false
    }
    
    // Keep full intensity for a few frames
    if b.keep_frames > 0 {
        b.keep_frames -= 1
        return true
    }
    
    // Decay intensity (different rates create nice color shift)
    // Faster decay = quicker fade
    decay_rate: f32 = 0.4  // Decay 40% per frame
    b.intensity *= (1.0 - decay_rate)
    
    // Also decay individual color channels at slightly different rates
    // This creates a subtle color shift as it fades
    b.color.r *= 0.60
    b.color.g *= 0.55
    b.color.b *= 0.50
    
    // Stop when intensity is negligible
    if b.intensity < 0.01 {
        b.intensity = 0
        return false
    }
    
    return true
}

// Get the color to add to sprite (for rendering)
blink_get_color_add :: proc(b: ^Blink) -> [4]f32 {
    return {b.color.r, b.color.g, b.color.b, b.intensity}
}

// Check if currently blinking
blink_is_active :: proc(b: ^Blink) -> bool {
    return b.intensity > 0
}
