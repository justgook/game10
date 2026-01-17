package game

import "logic"
import sapp "sokol/app"

// Sprite Shake system - updates all sprite shake components each frame
sys_sprite_shake :: proc(w: ^World) {
    dt := f32(w.sim_frame_length)  // Use fixed timestep
    
    view := logic.view(&w.sprite_shake)
    for _, shake in logic.each(&view) {
        sprite_shake_update(shake, dt)
    }
}
