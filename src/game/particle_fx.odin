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
fx_land_smoke :: proc(pool: ^Particle_Pool, x, y: f32, intensity: f32 = 1.0) {
    count := int(20 * intensity)
    
    for i := 0; i < count; i += 1 {
        dir: f32 = i % 2 == 0 ? 1.0 : -1.0
        
        p := particle_alloc(pool, .Main, .Normal, 
            x + particle_rnd(0, 6) * dir,
            y + particle_rnd_centered(2))
        if p == nil { return }
        
        particle_set_color_hex(p, 0xb78662)  // Dusty brown
        particle_set_alpha(p, particle_rnd(0.1, 0.2) * intensity)
        particle_set_fade(p, p.alpha, 0, particle_rnd(0.5, 1.5))
        
        particle_set_scale(p, particle_rnd(0.3, 0.5))
        particle_set_scale_mul(p, particle_rnd(1.0, 1.002))
        
        particle_set_velocity(p, particle_rnd(0.1, 1.0) * dir, -particle_rnd(0.1, 0.4))
        particle_set_friction(p, particle_rnd(0.92, 0.94))
        
        particle_set_rotation(p, particle_rnd(0, math.TAU))
        particle_set_rotation_speed(p, particle_rnd_centered(0.002))
        
        particle_set_life(p, particle_rnd(0.3, 0.9))
    }
}

// Double jump effect - upward lines
fx_double_jump :: proc(pool: ^Particle_Pool, x, y: f32) {
    // Upward lines
    for i := 0; i < 15; i += 1 {
        dir: f32 = i % 2 == 0 ? 1.0 : -1.0
        
        p := particle_alloc(pool, .Main, .Additive,
            x + particle_rnd(0, 8) * dir,
            y - particle_rnd(0, 3))
        if p == nil { return }
        
        particle_set_color_hex(p, 0x616986)  // Bluish gray
        particle_set_alpha(p, particle_rnd(0.08, 0.12))
        particle_set_fade(p, p.alpha, 0, particle_rnd(5, 10))
        
        particle_set_scale_xy(p, particle_rnd(0.2, 0.5), 1.0)
        particle_set_scale_mul(p, particle_rnd(0.98, 0.99))
        
        particle_set_velocity(p, 0, -particle_rnd(0.5, 1.0))
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
        particle_set_alpha(p, particle_rnd(0.08, 0.14))
        particle_set_fade(p, p.alpha, 0, particle_rnd(0.3, 1.0))
        
        particle_set_scale(p, particle_rnd(0.3, 0.6))
        particle_set_scale_mul(p, particle_rnd(1.0, 1.002))
        
        particle_set_velocity(p, 0, -particle_rnd(0.2, 2.0))
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
fx_gun_shot :: proc(pool: ^Particle_Pool, x, y: f32, dir: f32) {
    // Main flash line
    p := particle_alloc(pool, .Main, .Additive, x, y)
    if p != nil {
        particle_set_pivot(p, 0, 0.5)
        particle_set_alpha(p, 1.0)
        particle_set_fade(p, 1.0, 0, 30)
        particle_set_color_hex(p, 0xffb600)  // Orange-yellow
        particle_set_color_anim_hex(p, 0xff4a00, 15)  // Fade to red-orange
        particle_set_scale_xy(p, dir * particle_rnd(1.5, 2.0), particle_rnd(1.2, 1.4))
        particle_set_life(p, 0.12)
    }
    
    // Core sparks
    for i := 0; i < 6; i += 1 {
        p := particle_alloc(pool, .Main, .Additive,
            x + particle_rnd_centered(1),
            y + particle_rnd_centered(1))
        if p == nil { return }
        
        particle_set_pivot(p, 0, 0.5)
        particle_set_alpha(p, particle_rnd(0.8, 1.0))
        particle_set_fade(p, p.alpha, 0, 30)
        particle_set_color_hex(p, 0xffb600)
        particle_set_color_anim_hex(p, 0xff4a00, particle_rnd(0, 15))
        particle_set_scale_xy(p, dir * particle_rnd(0.7, 1.5), particle_rnd(1.5, 2.5))
        particle_set_life(p, particle_rnd(0.03, 0.06))
    }
    
    // Radial sparks
    n := 9 + int(particle_rnd(0, 2))
    for i := 0; i < n; i += 1 {
        base_ang: f32 = dir > 0 ? 0 : math.PI
        ang := base_ang - 0.9 + 1.8 * f32(i + 1) / f32(n) + particle_rnd_centered(0.1)
        
        p := particle_alloc(pool, .Main, .Additive, x, y)
        if p == nil { return }
        
        particle_set_alpha(p, particle_rnd(0.6, 0.9))
        particle_set_fade(p, p.alpha, 0, 20)
        particle_set_rotation(p, ang)
        particle_move_angle(p, ang, particle_rnd(4, 8))
        particle_set_color_hex(p, 0xef5100)
        particle_set_scale_xy(p, particle_rnd(0.2, 0.4), particle_rnd(1, 2))
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
fx_hit_wall :: proc(pool: ^Particle_Pool, x, y: f32, normal_dir: f32) {
    // Main impact flash
    p := particle_alloc(pool, .Main, .Additive,
        x - normal_dir * particle_rnd(1, 3),
        y + particle_rnd_centered(2))
    if p != nil {
        particle_set_pivot(p, 0, 0.5)
        particle_set_alpha(p, 1.0)
        particle_set_fade(p, 1.0, 0, 30)
        particle_set_color_hex(p, 0xffb600)
        particle_set_color_anim_hex(p, 0xff4a00, 15)
        particle_set_scale_xy(p, normal_dir * particle_rnd(0.7, 1.0), particle_rnd(2, 3))
        particle_set_scale_mul_xy(p, 0.94, 0.91)
        particle_set_life(p, 0.12)
    }
    
    // Falling sparks
    for i := 0; i < 5; i += 1 {
        p := particle_alloc(pool, .Main, .Additive,
            x, y + particle_rnd_centered(2))
        if p == nil { return }
        
        particle_set_alpha(p, particle_rnd(0.5, 0.9))
        particle_set_fade(p, p.alpha, 0, particle_rnd(2, 5))
        particle_set_color_hex(p, 0xffd524)
        particle_set_color_anim_hex(p, 0x990000, particle_rnd(3, 20))
        particle_set_velocity(p, normal_dir * particle_rnd(0.3, 2), particle_rnd(-1, 0.5))
        particle_set_gravity(p, 0, particle_rnd(0.1, 0.2))
        particle_set_friction(p, particle_rnd(0.92, 0.95))
        particle_set_life(p, particle_rnd(0.4, 2))
    }
}

// Cartridge ejection
fx_cartridge :: proc(pool: ^Particle_Pool, x, y: f32, dir: f32) {
    p := particle_alloc(pool, .Main, .Normal,
        x + particle_rnd_centered(1), y)
    if p == nil { return }
    
    particle_set_alpha(p, 1.0)
    particle_set_fade(p, 1.0, 0, particle_rnd(0.15, 0.2))
    particle_set_color_hex(p, 0xefc04b)  // Brass color
    particle_set_velocity(p, dir * particle_rnd(0.7, 2.8), -particle_rnd(3, 4))
    particle_set_scale_xy(p, particle_rnd(1, 1.5), 0.5)
    particle_set_gravity(p, 0, 0.25)
    particle_set_friction(p, 0.96)
    particle_set_rotation_speed(p, dir * particle_rnd(0.1, 0.2))
    particle_set_life(p, particle_rnd(12, 15))
}
