package game

import "core:math"

// Particle Effects
//
// Pre-built particle effect functions based on the gamefeel demo.
// These create bursts of particles with specific behaviors.

// ============================================================================
// Jump/Landing Effects
// ============================================================================

// Smoke puff when jumping or landing
// Note: Y+ is UP in this engine
fx_land_smoke :: proc(pool: ^Particle_Pool, x, y: f32, intensity: f32 = 1.0) {
    count := int(20 * intensity)
    
    for i := 0; i < count; i += 1 {
        dir: f32 = i % 2 == 0 ? 1.0 : -1.0
        
        p := particle_alloc(pool, .Main, .Normal, 
            x + particle_rnd(0, 6) * dir,
            y + particle_rnd_centered(2))
        if p == nil { return }
        
        particle_set_color_hex(p, 0xb78662)  // Dusty brown
        particle_set_alpha(p, particle_rnd(0.3, 0.5) * intensity)  // More visible
        particle_set_fade(p, p.alpha, 0, particle_rnd(0.5, 1.5))
        
        particle_set_scale(p, particle_rnd(0.2, 0.4))  // Smaller scale
        particle_set_scale_mul(p, particle_rnd(1.0, 1.002))
        
        // Y+ is up, so positive Y velocity goes up
        particle_set_velocity(p, particle_rnd(0.1, 1.0) * dir, particle_rnd(0.1, 0.4))
        particle_set_friction(p, particle_rnd(0.92, 0.94))
        
        particle_set_rotation(p, particle_rnd(0, math.TAU))
        particle_set_rotation_speed(p, particle_rnd_centered(0.002))
        
        particle_set_life(p, particle_rnd(0.3, 0.9))
    }
}

// Double jump effect - downward lines (Y+ is up, so lines go down from player)
fx_double_jump :: proc(pool: ^Particle_Pool, x, y: f32) {
    // Downward lines (below player)
    for i := 0; i < 15; i += 1 {
        dir: f32 = i % 2 == 0 ? 1.0 : -1.0
        
        p := particle_alloc(pool, .Main, .Additive,
            x + particle_rnd(0, 8) * dir,
            y + particle_rnd(0, 3))  // Below player
        if p == nil { return }
        
        particle_set_color_hex(p, 0x616986)  // Bluish gray
        particle_set_alpha(p, particle_rnd(0.15, 0.25))  // More visible
        particle_set_fade(p, p.alpha, 0, particle_rnd(5, 10))
        
        particle_set_scale_xy(p, particle_rnd(0.1, 0.3), 0.5)  // Smaller
        particle_set_scale_mul(p, particle_rnd(0.98, 0.99))
        
        particle_set_velocity(p, 0, -particle_rnd(0.5, 1.0))  // Go down
        particle_set_friction(p, particle_rnd(0.78, 0.82))
        
        particle_set_life(p, particle_rnd(0.1, 0.2))
    }
    
    // Smoke puffs
    for i := 0; i < 10; i += 1 {
        dir: f32 = i % 2 == 0 ? 1.0 : -1.0
        
        p := particle_alloc(pool, .Main, .Normal,
            x + particle_rnd(0, 5) * dir,
            y + particle_rnd_centered(2))
        if p == nil { return }
        
        particle_set_color_hex(p, 0x616986)
        particle_set_alpha(p, particle_rnd(0.15, 0.25))  // More visible
        particle_set_fade(p, p.alpha, 0, particle_rnd(0.3, 1.0))
        
        particle_set_scale(p, particle_rnd(0.2, 0.4))  // Smaller
        particle_set_scale_mul(p, particle_rnd(1.0, 1.002))
        
        particle_set_velocity(p, 0, -particle_rnd(0.2, 2.0))  // Go down
        particle_set_friction(p, particle_rnd(0.92, 0.94))
        
        particle_set_rotation(p, particle_rnd(0, math.TAU))
        particle_set_rotation_speed(p, particle_rnd_centered(0.002))
        
        particle_set_life(p, particle_rnd(0.3, 0.9))
    }
}

// ============================================================================
// Dash Effects
// ============================================================================

// Dash trail - blue light lines
fx_dash :: proc(pool: ^Particle_Pool, x, y: f32, dir: f32) {
    for i := 0; i < 30; i += 1 {
        p := particle_alloc(pool, .Main, .Additive,
            x + particle_rnd(6, 10) * dir,
            y + particle_rnd_centered(8))
        if p == nil { return }
        
        particle_set_color_hex(p, 0x2f3caf)  // Blue
        particle_set_alpha(p, particle_rnd(0.20, 0.35))
        particle_set_fade(p, p.alpha, 0, particle_rnd(10, 15))
        
        particle_set_rotation(p, dir > 0 ? 0 : math.PI)
        
        particle_set_velocity(p, dir * particle_rnd(4, 8), 0)
        particle_set_friction(p, particle_rnd(0.78, 0.82))
        
        particle_set_scale_xy(p, particle_rnd(0.5, 1.5), 0.2)
        particle_set_scale_mul_xy(p, particle_rnd(0.98, 0.99), 1.0)
        
        particle_set_life(p, particle_rnd(0.04, 0.08))
    }
}

// ============================================================================
// Combat Effects
// ============================================================================

// Gun shot muzzle flash
// dir: angle in radians (0 = right, PI = left)
fx_gun_shot :: proc(pool: ^Particle_Pool, x, y: f32, dir: f32) {
    // Direction multiplier: 1 for right, -1 for left
    dir_mul: f32 = math.cos(dir) >= 0 ? 1.0 : -1.0
    
    // Main flash line - offset in firing direction
    flash_x := x + dir_mul * 8
    p := particle_alloc(pool, .Main, .Additive, flash_x, y)
    if p != nil {
        particle_set_pivot(p, 0, 0.5)
        particle_set_alpha(p, 0.8)
        particle_set_fade(p, 0.8, 0, 30)
        particle_set_color_hex(p, 0xffb600)  // Orange-yellow
        particle_set_color_anim_hex(p, 0xff4a00, 15)  // Fade to red-orange
        // Smaller scale, direction affects X scale sign
        particle_set_scale_xy(p, dir_mul * particle_rnd(0.3, 0.5), particle_rnd(0.15, 0.25))
        particle_set_life(p, 0.08)
    }
    
    // Core sparks - smaller
    for i := 0; i < 4; i += 1 {
        p := particle_alloc(pool, .Main, .Additive,
            flash_x + particle_rnd_centered(2),
            y + particle_rnd_centered(2))
        if p == nil { return }
        
        particle_set_alpha(p, particle_rnd(0.6, 0.8))
        particle_set_fade(p, p.alpha, 0, 30)
        particle_set_color_hex(p, 0xffb600)
        particle_set_color_anim_hex(p, 0xff4a00, particle_rnd(0, 15))
        particle_set_scale_xy(p, particle_rnd(0.05, 0.15), particle_rnd(0.05, 0.15))
        particle_set_velocity(p, dir_mul * particle_rnd(1, 3), particle_rnd_centered(1))
        particle_set_friction(p, 0.9)
        particle_set_life(p, particle_rnd(0.03, 0.06))
    }
    
    // Radial sparks - smaller and fewer
    n := 5 + int(particle_rnd(0, 2))
    for i := 0; i < n; i += 1 {
        // Spread around the firing direction
        ang := dir - 0.5 + 1.0 * f32(i + 1) / f32(n) + particle_rnd_centered(0.1)
        
        p := particle_alloc(pool, .Main, .Additive, flash_x, y)
        if p == nil { return }
        
        particle_set_alpha(p, particle_rnd(0.5, 0.7))
        particle_set_fade(p, p.alpha, 0, 20)
        particle_set_rotation(p, ang)
        particle_move_angle(p, ang, particle_rnd(2, 4))
        particle_set_color_hex(p, 0xef5100)
        particle_set_scale_xy(p, particle_rnd(0.03, 0.08), particle_rnd(0.1, 0.2))
        particle_set_scale_mul_xy(p, particle_rnd(0.97, 0.99), 1.0)
        particle_set_friction(p, particle_rnd(0.82, 0.84))
        particle_set_life(p, particle_rnd(0.03, 0.06))
    }
}

// Light spot/halo effect
fx_light_spot :: proc(pool: ^Particle_Pool, x, y: f32, color_hex: u32, alpha: f32 = 1.0) {
    p := particle_alloc(pool, .Main, .Additive, x, y)
    if p == nil { return }
    
    particle_set_scale(p, particle_rnd(2, 3))
    particle_set_alpha(p, alpha)
    particle_set_fade(p, alpha, 0, 3)
    particle_set_color_hex(p, color_hex)
    p.ds = 0.1
    p.ds_frict = 0.9
    particle_set_scale_mul(p, 0.92)
    particle_set_life(p, 0.1)
}

// ============================================================================
// Impact Effects
// ============================================================================

// Bullet impact on wall
// normal_dir: angle in radians pointing away from wall
fx_hit_wall :: proc(pool: ^Particle_Pool, x, y: f32, normal_dir: f32) {
    dir_mul: f32 = math.cos(normal_dir) >= 0 ? 1.0 : -1.0
    
    // Main impact flash - smaller
    p := particle_alloc(pool, .Main, .Additive,
        x + dir_mul * particle_rnd(1, 3),
        y + particle_rnd_centered(2))
    if p != nil {
        particle_set_pivot(p, 0, 0.5)
        particle_set_alpha(p, 0.8)
        particle_set_fade(p, 0.8, 0, 30)
        particle_set_color_hex(p, 0xffb600)
        particle_set_color_anim_hex(p, 0xff4a00, 15)
        particle_set_scale_xy(p, dir_mul * particle_rnd(0.1, 0.2), particle_rnd(0.15, 0.25))
        particle_set_scale_mul_xy(p, 0.94, 0.91)
        particle_set_life(p, 0.08)
    }
    
    // Falling sparks - gravity pulls DOWN (negative Y)
    for i := 0; i < 5; i += 1 {
        p := particle_alloc(pool, .Main, .Additive,
            x, y + particle_rnd_centered(2))
        if p == nil { return }
        
        particle_set_alpha(p, particle_rnd(0.5, 0.9))
        particle_set_fade(p, p.alpha, 0, particle_rnd(2, 5))
        particle_set_color_hex(p, 0xffd524)
        particle_set_color_anim_hex(p, 0x990000, particle_rnd(3, 20))
        // Sparks go in normal direction and slightly up, then fall
        particle_set_velocity(p, dir_mul * particle_rnd(0.3, 2), particle_rnd(0.5, 1.5))
        // Gravity DOWN (negative Y)
        particle_set_gravity(p, 0, -particle_rnd(0.1, 0.2))
        particle_set_friction(p, particle_rnd(0.92, 0.95))
        particle_set_scale(p, particle_rnd(0.03, 0.06))  // Smaller
        particle_set_life(p, particle_rnd(0.4, 1.0))
    }
}

// Cartridge ejection
// dir: angle in radians (0 = right, PI = left)
// Cartridge ejects upward and opposite to firing direction
fx_cartridge :: proc(pool: ^Particle_Pool, x, y: f32, dir: f32) {
    // Eject opposite to firing direction
    dir_mul: f32 = math.cos(dir) >= 0 ? -1.0 : 1.0  // Opposite of firing
    
    p := particle_alloc(pool, .Main, .Normal,
        x + particle_rnd_centered(1), y)
    if p == nil { return }
    
    particle_set_alpha(p, 1.0)
    particle_set_fade(p, 1.0, 0, particle_rnd(0.15, 0.2))
    particle_set_color_hex(p, 0xefc04b)  // Brass color
    // Eject upward (positive Y) and to the side
    particle_set_velocity(p, dir_mul * particle_rnd(0.7, 2.0), particle_rnd(2, 3.5))
    particle_set_scale_xy(p, particle_rnd(0.08, 0.12), particle_rnd(0.03, 0.05))  // Much smaller
    // Gravity pulls DOWN (negative Y)
    particle_set_gravity(p, 0, -0.15)
    particle_set_friction(p, 0.96)
    particle_set_rotation_speed(p, dir_mul * particle_rnd(0.1, 0.2))
    particle_set_life(p, particle_rnd(0.8, 1.2))  // Shorter life
}
