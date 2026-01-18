package game

import "core:math"

// Particle System Update
//
// Updates all particles in the pool each frame.
// Handles physics, visual effects, and lifetime.

sys_particles :: proc(w: ^World, dt: f32) {
    pool := &w.particles
    
    for &p in pool.particles {
        if !p.alive {
            continue
        }
        
        // Update lifetime
        p.life -= dt
        if p.life <= 0 {
            particle_kill(pool, &p)
            continue
        }
        
        // Physics: apply gravity
        p.dx += p.gx * dt * 60.0  // Scale to ~60fps equivalent
        p.dy += p.gy * dt * 60.0
        
        // Physics: apply friction
        if p.frict != 1.0 {
            frict_frame := math.pow(p.frict, dt * 60.0)
            p.dx *= frict_frame
            p.dy *= frict_frame
        }
        
        // Physics: apply velocity
        p.x += p.dx * dt * 60.0
        p.y += p.dy * dt * 60.0
        
        // Scale: apply scale velocity
        if p.ds != 0 {
            p.scale_x += p.ds * dt * 60.0
            p.scale_y += p.ds * dt * 60.0
            
            // Apply scale velocity friction
            if p.ds_frict != 1.0 {
                p.ds *= math.pow(p.ds_frict, dt * 60.0)
            }
        }
        
        // Scale: apply scale multiplier
        if p.scale_mul_x != 1.0 || p.scale_mul_y != 1.0 {
            mul_x := math.pow(p.scale_mul_x, dt * 60.0)
            mul_y := math.pow(p.scale_mul_y, dt * 60.0)
            p.scale_x *= mul_x
            p.scale_y *= mul_y
        }
        
        // Rotation: apply rotation velocity
        if p.dr != 0 {
            p.rotation += p.dr * dt * 60.0
        }
        
        // Color animation
        if p.color_speed > 0 {
            lerp_amount := min(p.color_speed * dt, 1.0)
            p.color_r = math.lerp(p.color_r, p.color_target_r, lerp_amount)
            p.color_g = math.lerp(p.color_g, p.color_target_g, lerp_amount)
            p.color_b = math.lerp(p.color_b, p.color_target_b, lerp_amount)
        }
        
        // Alpha fade
        if p.fade_speed > 0 {
            if p.alpha > p.alpha_target {
                p.alpha = max(p.alpha - p.fade_speed * dt, p.alpha_target)
            } else if p.alpha < p.alpha_target {
                p.alpha = min(p.alpha + p.fade_speed * dt, p.alpha_target)
            }
        }
        
        // Kill if fully transparent
        if p.alpha <= 0.001 {
            particle_kill(pool, &p)
        }
    }
}

// Get life ratio (0 = dead, 1 = just spawned)
particle_get_life_ratio :: proc(p: ^Particle) -> f32 {
    if p.max_life <= 0 {
        return 0
    }
    return p.life / p.max_life
}

// Get inverse life ratio (0 = just spawned, 1 = about to die)
particle_get_progress :: proc(p: ^Particle) -> f32 {
    return 1.0 - particle_get_life_ratio(p)
}
