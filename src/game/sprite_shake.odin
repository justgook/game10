package game

import "core:math"
import "core:math/rand"

// Sprite Shake Effect
//
// Per-entity shake effect that offsets the sprite position randomly.
// Independent of camera shake - useful for individual entity reactions.
//
// Based on the gamefeel demo:
// - shakePowX/Y control the maximum offset
// - Shake decays over time based on remaining ratio
// - Uses sin/cos with time for smooth random-looking motion

// Sprite Shake component
SpriteShake :: struct {
    power_x:     f32,   // Maximum X offset in pixels
    power_y:     f32,   // Maximum Y offset in pixels
    duration:    f32,   // Total duration in seconds
    elapsed:     f32,   // Time elapsed
    seed:        f32,   // Random seed for variation between entities
}

// Initialize with no shake
sprite_shake_init :: proc() -> SpriteShake {
    return SpriteShake{
        seed = rand.float32() * 100,  // Random seed for variation
    }
}

// Trigger a shake effect
// power_x/y: maximum offset in pixels
// duration: how long the shake lasts in seconds
sprite_shake_trigger :: proc(s: ^SpriteShake, power_x, power_y, duration: f32) {
    s.power_x = power_x
    s.power_y = power_y
    s.duration = duration
    s.elapsed = 0
    s.seed = rand.float32() * 100  // New seed each shake
}

// Convenience functions for common shake types
sprite_shake_light :: proc(s: ^SpriteShake) {
    sprite_shake_trigger(s, 2, 2, 0.2)
}

sprite_shake_medium :: proc(s: ^SpriteShake) {
    sprite_shake_trigger(s, 4, 4, 0.3)
}

sprite_shake_heavy :: proc(s: ^SpriteShake) {
    sprite_shake_trigger(s, 8, 6, 0.4)
}

sprite_shake_horizontal :: proc(s: ^SpriteShake, power: f32 = 4) {
    sprite_shake_trigger(s, power, 0, 0.25)
}

sprite_shake_vertical :: proc(s: ^SpriteShake, power: f32 = 4) {
    sprite_shake_trigger(s, 0, power, 0.25)
}

// Update shake - call every frame with delta time
// Returns true if still shaking
sprite_shake_update :: proc(s: ^SpriteShake, dt: f32) -> bool {
    if s.duration <= 0 || s.elapsed >= s.duration {
        return false
    }
    
    s.elapsed += dt
    return s.elapsed < s.duration
}

// Get the current offset to apply to sprite position
// Returns [x, y] offset in pixels
sprite_shake_get_offset :: proc(s: ^SpriteShake, time: f32) -> [2]f32 {
    if s.duration <= 0 || s.elapsed >= s.duration {
        return {0, 0}
    }
    
    // Calculate remaining ratio (1.0 at start, 0.0 at end)
    ratio := 1.0 - (s.elapsed / s.duration)
    
    // Use sin/cos with different frequencies for pseudo-random motion
    // The seed adds variation between different entities
    t := time + s.seed
    offset_x := math.cos(t * 1.1) * s.power_x * ratio
    offset_y := math.sin(0.3 + t * 1.7) * s.power_y * ratio
    
    return {offset_x, offset_y}
}

// Check if currently shaking
sprite_shake_is_active :: proc(s: ^SpriteShake) -> bool {
    return s.duration > 0 && s.elapsed < s.duration
}

// Get remaining ratio (useful for visual feedback)
sprite_shake_get_ratio :: proc(s: ^SpriteShake) -> f32 {
    if s.duration <= 0 {
        return 0
    }
    return max(0, 1.0 - (s.elapsed / s.duration))
}
