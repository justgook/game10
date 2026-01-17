package game

// Screen Flash Effect
//
// Full-screen color overlay for impactful moments (shooting, big hits).
// Based on the gamefeel demo's flashBangS() function.
//
// Key characteristics:
// - Renders a colored quad over everything (before UI)
// - Uses additive blending for the "flash" look
// - Fades out quickly (~0.1s default)
// - Global effect (not per-entity)

// Screen flash state - stored in World (not a component)
ScreenFlash :: struct {
    color:       [3]f32,  // RGB color (0-1 range)
    alpha:       f32,     // Current alpha (decays over time)
    duration:    f32,     // Total duration in seconds
    elapsed:     f32,     // Time elapsed
    initial_alpha: f32,   // Starting alpha for interpolation
}

// Initialize with no flash
screen_flash_init :: proc() -> ScreenFlash {
    return ScreenFlash{}
}

// Trigger a screen flash
// color: RGB values 0-1
// alpha: initial alpha (typically 0.03-0.1 for subtle, 0.2-0.5 for strong)
// duration: fade time in seconds (typically 0.1)
screen_flash_trigger :: proc(sf: ^ScreenFlash, r, g, b: f32, alpha: f32 = 0.05, duration: f32 = 0.1) {
    sf.color = {r, g, b}
    sf.alpha = alpha
    sf.initial_alpha = alpha
    sf.duration = duration
    sf.elapsed = 0
}

// Convenience: Yellow flash (shooting) - matches gamefeel demo
screen_flash_shoot :: proc(sf: ^ScreenFlash) {
    // 0xffcc00 = RGB(255, 204, 0) = (1.0, 0.8, 0.0)
    screen_flash_trigger(sf, 1.0, 0.8, 0.0, 0.04, 0.1)
}

// Convenience: White flash (impact/damage)
screen_flash_white :: proc(sf: ^ScreenFlash) {
    screen_flash_trigger(sf, 1.0, 1.0, 1.0, 0.06, 0.08)
}

// Convenience: Red flash (critical hit/danger)
screen_flash_red :: proc(sf: ^ScreenFlash) {
    screen_flash_trigger(sf, 1.0, 0.2, 0.1, 0.08, 0.12)
}

// Convenience: Blue flash (special ability)
screen_flash_blue :: proc(sf: ^ScreenFlash) {
    screen_flash_trigger(sf, 0.2, 0.5, 1.0, 0.06, 0.1)
}

// Update flash - call every frame with delta time
// Returns true if still flashing
screen_flash_update :: proc(sf: ^ScreenFlash, dt: f32) -> bool {
    if sf.alpha <= 0 {
        return false
    }
    
    sf.elapsed += dt
    
    // Linear fade out
    if sf.elapsed >= sf.duration {
        sf.alpha = 0
        return false
    }
    
    // Interpolate alpha from initial to 0
    t := sf.elapsed / sf.duration
    sf.alpha = sf.initial_alpha * (1.0 - t)
    
    return true
}

// Check if currently flashing
screen_flash_is_active :: proc(sf: ^ScreenFlash) -> bool {
    return sf.alpha > 0
}

// Get color with alpha for rendering (RGBA)
screen_flash_get_color :: proc(sf: ^ScreenFlash) -> [4]f32 {
    return {sf.color.r, sf.color.g, sf.color.b, sf.alpha}
}
