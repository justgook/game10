package game

import "render/particles"

// Render Particles
//
// Converts particles from the game's particle pool to GPU instances
// for rendering.

// Default UV for a simple white pixel (adjust based on your atlas)
// This should point to a small white square in your texture atlas
DEFAULT_PARTICLE_UV :: [4]f32{0, 0, 1.0/256.0, 1.0/256.0}  // Tiny corner of atlas

render_particles :: proc(w: ^World, r: ^Render) {
    // Clear previous frame's particles
    particles.clear(&r.particle_renderer)
    
    // Convert each alive particle to a GPU instance
    for &p in w.particles.particles {
        if !p.alive {
            continue
        }
        
        // Create GPU instance
        inst := particles.Particle_Instance{
            pos      = {p.x, p.y},
            scale    = {p.scale_x * 8, p.scale_y * 8},  // Base size 8 pixels
            rotation = p.rotation,
            color    = {p.color_r, p.color_g, p.color_b, p.alpha},
            uv       = DEFAULT_PARTICLE_UV,  // TODO: Use tile_id to look up UV
            pivot    = {p.pivot_x, p.pivot_y},
        }
        
        // Add to appropriate batch based on blend mode
        particles.add(&r.particle_renderer, p.blend == .Additive, inst)
    }
}
