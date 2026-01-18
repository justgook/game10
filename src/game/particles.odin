package game

import "core:math"
import "core:math/rand"

// GPU Particle System
//
// Pooled particle system using GPU instancing for efficient rendering.
// Based on the gamefeel demo's HParticle system.
//
// Features:
// - Pre-allocated particle pool (no runtime allocation)
// - Physics: velocity, gravity, friction
// - Visual: color, alpha fade, scale, rotation
// - Layers: background (additive), background (normal), main (additive), main (normal)

PARTICLE_POOL_SIZE :: 2048

// Particle blend modes
Particle_Blend :: enum u8 {
    Normal,
    Additive,
}

// Particle layer (render order)
Particle_Layer :: enum u8 {
    BG,    // Behind entities
    Main,  // In front of entities
}

// Single particle data
Particle :: struct {
    // State
    alive:       bool,
    
    // Position & movement
    x, y:        f32,
    dx, dy:      f32,       // Velocity
    gx, gy:      f32,       // Gravity/acceleration
    frict:       f32,       // Friction multiplier (0.9 = 10% slowdown per frame)
    
    // Visual
    scale_x:     f32,
    scale_y:     f32,
    scale_mul_x: f32,       // Scale multiplier per frame
    scale_mul_y: f32,
    ds:          f32,       // Scale velocity (uniform)
    ds_frict:    f32,       // Scale velocity friction
    
    rotation:    f32,       // Radians
    dr:          f32,       // Rotation velocity
    
    // Color (RGB 0-1)
    color_r:     f32,
    color_g:     f32,
    color_b:     f32,
    
    // Color animation
    color_target_r: f32,
    color_target_g: f32,
    color_target_b: f32,
    color_speed:    f32,    // 0 = no animation
    
    // Alpha/fade
    alpha:       f32,
    alpha_target: f32,
    fade_speed:  f32,       // Alpha change per second
    
    // Lifetime
    life:        f32,       // Remaining life in seconds
    max_life:    f32,       // Initial life (for ratio calculations)
    
    // Rendering
    tile_id:     u16,       // Sprite tile index
    pivot_x:     f32,       // 0-1, center ratio
    pivot_y:     f32,
    blend:       Particle_Blend,
    layer:       Particle_Layer,
}

// Particle pool - manages all particles
Particle_Pool :: struct {
    particles:   [PARTICLE_POOL_SIZE]Particle,
    active_count: int,
}

// Initialize particle pool
particle_pool_init :: proc() -> Particle_Pool {
    pool: Particle_Pool
    for &p in pool.particles {
        p.alive = false
    }
    return pool
}

// Allocate a new particle from the pool
// Returns nil if pool is full
particle_alloc :: proc(pool: ^Particle_Pool, layer: Particle_Layer, blend: Particle_Blend, x, y: f32) -> ^Particle {
    // Find first dead particle
    for &p in pool.particles {
        if !p.alive {
            // Initialize with defaults
            p = Particle{
                alive       = true,
                x           = x,
                y           = y,
                dx          = 0,
                dy          = 0,
                gx          = 0,
                gy          = 0,
                frict       = 1.0,  // No friction by default
                scale_x     = 1.0,
                scale_y     = 1.0,
                scale_mul_x = 1.0,
                scale_mul_y = 1.0,
                ds          = 0,
                ds_frict    = 1.0,
                rotation    = 0,
                dr          = 0,
                color_r     = 1.0,
                color_g     = 1.0,
                color_b     = 1.0,
                color_speed = 0,
                alpha       = 1.0,
                alpha_target = 1.0,
                fade_speed  = 0,
                life        = 1.0,
                max_life    = 1.0,
                tile_id     = 0,
                pivot_x     = 0.5,
                pivot_y     = 0.5,
                blend       = blend,
                layer       = layer,
            }
            pool.active_count += 1
            return &p
        }
    }
    return nil  // Pool full
}

// Kill a particle
particle_kill :: proc(pool: ^Particle_Pool, p: ^Particle) {
    if p.alive {
        p.alive = false
        pool.active_count -= 1
    }
}

// Clear all particles
particle_pool_clear :: proc(pool: ^Particle_Pool) {
    for &p in pool.particles {
        p.alive = false
    }
    pool.active_count = 0
}

// ============================================================================
// Particle configuration helpers (chainable style)
// ============================================================================

// Set lifetime in seconds
particle_set_life :: proc(p: ^Particle, seconds: f32) {
    p.life = seconds
    p.max_life = seconds
}

// Set velocity
particle_set_velocity :: proc(p: ^Particle, dx, dy: f32) {
    p.dx = dx
    p.dy = dy
}

// Set velocity from angle and speed
particle_move_angle :: proc(p: ^Particle, angle_rad: f32, speed: f32) {
    p.dx = math.cos(angle_rad) * speed
    p.dy = math.sin(angle_rad) * speed
}

// Set gravity
particle_set_gravity :: proc(p: ^Particle, gx, gy: f32) {
    p.gx = gx
    p.gy = gy
}

// Set friction (0.9 = 10% slowdown per frame)
particle_set_friction :: proc(p: ^Particle, frict: f32) {
    p.frict = frict
}

// Set scale
particle_set_scale :: proc(p: ^Particle, scale: f32) {
    p.scale_x = scale
    p.scale_y = scale
}

particle_set_scale_xy :: proc(p: ^Particle, sx, sy: f32) {
    p.scale_x = sx
    p.scale_y = sy
}

// Set scale multiplier (applied each frame)
particle_set_scale_mul :: proc(p: ^Particle, mul: f32) {
    p.scale_mul_x = mul
    p.scale_mul_y = mul
}

particle_set_scale_mul_xy :: proc(p: ^Particle, mx, my: f32) {
    p.scale_mul_x = mx
    p.scale_mul_y = my
}

// Set rotation
particle_set_rotation :: proc(p: ^Particle, rad: f32) {
    p.rotation = rad
}

// Set rotation velocity
particle_set_rotation_speed :: proc(p: ^Particle, dr: f32) {
    p.dr = dr
}

// Set color (RGB 0-1)
particle_set_color :: proc(p: ^Particle, r, g, b: f32) {
    p.color_r = r
    p.color_g = g
    p.color_b = b
}

// Set color from hex (0xRRGGBB)
particle_set_color_hex :: proc(p: ^Particle, hex: u32) {
    p.color_r = f32((hex >> 16) & 0xFF) / 255.0
    p.color_g = f32((hex >> 8) & 0xFF) / 255.0
    p.color_b = f32(hex & 0xFF) / 255.0
}

// Set color animation (lerp to target over time)
particle_set_color_anim :: proc(p: ^Particle, target_r, target_g, target_b: f32, speed: f32) {
    p.color_target_r = target_r
    p.color_target_g = target_g
    p.color_target_b = target_b
    p.color_speed = speed
}

particle_set_color_anim_hex :: proc(p: ^Particle, target_hex: u32, speed: f32) {
    p.color_target_r = f32((target_hex >> 16) & 0xFF) / 255.0
    p.color_target_g = f32((target_hex >> 8) & 0xFF) / 255.0
    p.color_target_b = f32(target_hex & 0xFF) / 255.0
    p.color_speed = speed
}

// Set alpha
particle_set_alpha :: proc(p: ^Particle, alpha: f32) {
    p.alpha = alpha
}

// Set fade (start alpha, end alpha, fade speed per second)
particle_set_fade :: proc(p: ^Particle, start_alpha, end_alpha, speed: f32) {
    p.alpha = start_alpha
    p.alpha_target = end_alpha
    p.fade_speed = speed
}

// Set pivot/center ratio (0-1)
particle_set_pivot :: proc(p: ^Particle, px, py: f32) {
    p.pivot_x = px
    p.pivot_y = py
}

// Set tile/sprite ID
particle_set_tile :: proc(p: ^Particle, tile_id: u16) {
    p.tile_id = tile_id
}

// ============================================================================
// Random helpers (for particle variation)
// ============================================================================

// Random float in range [min, max]
particle_rnd :: proc(min, max: f32) -> f32 {
    return min + rand.float32() * (max - min)
}

// Random float in range [-half, half] (centered around 0)
particle_rnd_centered :: proc(half: f32) -> f32 {
    return (rand.float32() - 0.5) * 2.0 * half
}

// Random sign (-1 or 1)
particle_rnd_sign :: proc() -> f32 {
    return rand.float32() < 0.5 ? -1.0 : 1.0
}
