package game

import "core:fmt"
import "logic"
import "shape"

// Combat System
//
// Handles hit/hurt box collision detection and triggers callbacks.
// Based on the odin-game reference implementation.
//
// Hit boxes (circles) deal damage - attached to bullets, enemy attacks
// Hurt boxes (capsules) receive damage - attached to player, enemies

sys_combat :: proc(w: ^World) {
    // Player bullets hit enemies
    hit_hurt_test(w, &w.player_hit, &w.enemy_hurt)
    
    // Enemy attacks hit player
    hit_hurt_test(w, &w.enemy_hit, &w.player_hurt)
}

@(private = "file")
hit_hurt_test :: proc(
    w: ^World,
    hit: ^logic.Component_Storage(shape.Circle),
    hurt: ^logic.Component_Storage(shape.Capsule),
) {
    hit_view := logic.view(&w.position, hit)
    hurt_view := logic.view(&w.position, hurt)
    
    for src, src_pos, src_hit in logic.each(&hit_view) {
        // Get absolute hit box position
        hit_abs := src_hit^
        shape.move(&hit_abs, src_pos^)
        
        // Reset hurt view for each hit box
        hurt_view.current_index = 0
        
        for target, target_pos, target_hurt in logic.each(&hurt_view) {
            // Skip self-collision
            if src == target {
                continue
            }
            
            // Get absolute hurt box position
            hurt_abs := target_hurt^
            shape.move(&hurt_abs, target_pos^)
            
            // Test collision
            if !shape.test(&hurt_abs, &hit_abs) {
                continue
            }
            
            // Collision detected! Call callbacks
            if on_hit, ok := logic.get_component(&w.on_hit, src); ok {
                on_hit^(w, src, target)
            }
            
            if on_hurt, ok := logic.get_component(&w.on_hurt, target); ok {
                on_hurt^(w, src, target)
            }
        }
    }
}
