package game

import "camera"
import "core:fmt"
import "logic"
import "shape"

// Combat Components and Callbacks
//
// This file defines the combat-related data structures and callback implementations
// that integrate with the game feel systems (blink, shake, particles, camera effects).

// Hitpoint component - tracks entity health
Hitpoint :: struct {
    current: int,
    max:     int,
}

hitpoint_init :: proc(max_hp: int) -> Hitpoint {
    return Hitpoint{current = max_hp, max = max_hp}
}

hitpoint_damage :: proc(hp: ^Hitpoint, amount: int) -> bool {
    hp.current -= amount
    hp.current = max(hp.current, 0)
    return hp.current <= 0  // Returns true if dead
}

hitpoint_heal :: proc(hp: ^Hitpoint, amount: int) {
    hp.current += amount
    hp.current = min(hp.current, hp.max)
}

hitpoint_is_dead :: proc(hp: ^Hitpoint) -> bool {
    return hp.current <= 0
}

// Callback type aliases for clarity
On_Hit_Callback :: proc(w: ^World, src: int, target: int)
On_Hurt_Callback :: proc(w: ^World, src: int, target: int)

// On_Hit types - what happens when THIS entity hits something
On_Hit_Type :: enum {
    Bullet,           // Player bullet hits enemy
    Enemy_Collider,   // Enemy body hits player
}

// On_Hurt types - what happens when THIS entity gets hurt
On_Hurt_Type :: enum {
    Player,   // Player takes damage
    Enemy,    // Enemy takes damage
}

// Callback lookup tables
on_hit_fn := [On_Hit_Type]On_Hit_Callback{
    .Bullet = on_hit_bullet,
    .Enemy_Collider = on_hit_enemy_collider,
}

on_hurt_fn := [On_Hurt_Type]On_Hurt_Callback{
    .Player = on_hurt_player,
    .Enemy = on_hurt_enemy,
}

// =============================================================================
// ON_HIT CALLBACKS - Called on the entity that deals damage
// =============================================================================

// Bullet hits an enemy
on_hit_bullet :: proc(w: ^World, src: int, target: int) {
    // Get positions for effects
    src_pos, src_ok := logic.get_component(&w.position, src)
    target_pos, target_ok := logic.get_component(&w.position, target)
    
    if src_ok && target_ok {
        pixel_pos := to_pixelf(target_pos^)
        
        // Direction: bullet travel direction (for blood spray)
        dir: f32 = 0.0
        if vel, vel_ok := logic.get_component(&w.velocity, src); vel_ok {
            dir = vel.x > 0 ? 0.0 : 3.14159  // Same as travel direction
        }
        
        // Impact flash
        fx_hit_entity(&w.particles, pixel_pos.x, pixel_pos.y, dir)
        
        // Blood spray!
        fx_blood(&w.particles, pixel_pos.x, pixel_pos.y, dir, 1.0)
    }
    
    // Delete the bullet
    entity_delete(w, src)
    
    // Apply damage to target
    if hp, ok := logic.get_component(&w.hitpoint, target); ok {
        dead := hitpoint_damage(hp, 1)
        
        if dead {
            // Enemy died - could spawn death effects here
            fmt.printfln("Entity %d killed!", target)
        }
    }
}

// Enemy body collides with player (contact damage)
on_hit_enemy_collider :: proc(w: ^World, src: int, target: int) {
    // Apply damage to player
    if hp, ok := logic.get_component(&w.hitpoint, target); ok {
        hitpoint_damage(hp, 1)
    }
}

// =============================================================================
// ON_HURT CALLBACKS - Called on the entity that receives damage
// =============================================================================

// Player takes damage
on_hurt_player :: proc(w: ^World, src: int, target: int) {
    fmt.printfln("Player hurt by entity %d", src)
    
    // Visual feedback - white blink
    if blink, ok := logic.get_component(&w.blink, target); ok {
        blink_red(blink)
    }
    
    // Sprite shake
    if shake, ok := logic.get_component(&w.sprite_shake, target); ok {
        sprite_shake_heavy(shake)
    }
    
    // Camera shake
    camera.camera_shake(&w.cam, 4.0, 4.0, 0.2)
    
    // Screen flash (red for damage)
    screen_flash_red(&w.screen_flash)
    
    // Invincibility frames - temporarily disable player hurt box
    disable_hurt_box(w, &w.player_hurt, target, 60)  // 1 second at 60fps
}

// Enemy takes damage
on_hurt_enemy :: proc(w: ^World, src: int, target: int) {
    fmt.printfln("Enemy %d hurt by entity %d", target, src)
    
    // Visual feedback - white blink (damage flash)
    if blink, ok := logic.get_component(&w.blink, target); ok {
        blink_white(blink)
    }
    
    // Squash effect on hit
    if squash, ok := logic.get_component(&w.squash, target); ok {
        squash_on_hit(squash)
    }
    
    // Sprite shake
    if shake, ok := logic.get_component(&w.sprite_shake, target); ok {
        sprite_shake_medium(shake)
    }
    
    // Knockback - push enemy away from damage source
    apply_knockback(w, src, target, 3 * UNIT)
    
    // Camera effects for impact
    camera.camera_shake(&w.cam, 2.0, 2.0, 0.1)
    camera.camera_bump_zoom(&w.cam, 0.02)
    
    // Note: Blood and impact particles are spawned in on_hit_bullet
    // This callback is for the enemy's reaction (blink, shake, knockback)
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

// Apply knockback velocity from src toward target
apply_knockback :: proc(w: ^World, src: int, target: int, power: int) {
    src_pos, src_ok := logic.get_component(&w.position, src)
    target_pos, target_ok := logic.get_component(&w.position, target)
    target_vel, vel_ok := logic.get_component(&w.velocity, target)
    
    if !src_ok || !target_ok || !vel_ok {
        return
    }
    
    // Direction from src to target
    dx := target_pos.x - src_pos.x
    
    // Apply horizontal knockback
    if dx >= 0 {
        target_vel.x = power
    } else {
        target_vel.x = -power
    }
    
    // Small upward pop (Y+ is UP)
    target_vel.y = power / 2
}

// =============================================================================
// INVINCIBILITY FRAMES SYSTEM
// =============================================================================

// Temporarily disable a hurt box and restore it after some frames
// This creates invincibility frames (i-frames)

@(private = "file")
Hurt_Restore :: struct($T: typeid) {
    entity:  int,
    storage: ^logic.Component_Storage(T),
    comp:    T,
}

disable_hurt_box :: proc(w: ^World, storage: ^logic.Component_Storage($T), entity: int, frames: int) {
    comp, ok := logic.get_component(storage, entity)
    if !ok {
        return
    }
    
    // Store the component data
    data := new(Hurt_Restore(T))
    data.storage = storage
    data.comp = comp^
    data.entity = entity
    
    // Remove the hurt box (makes entity invincible)
    logic.delete_component(storage, entity)
    
    // Create a timer to restore it
    timer_entity := create_entity(w)
    timer := timer_create(frames, restore_hurt_box_callback(T))
    timer.data = data
    logic.add_component(&w.timer, timer_entity, timer)
}

@(private = "file")
restore_hurt_box_callback :: proc($T: typeid) -> proc(w: ^World, entity: int, data: rawptr) {
    return proc(w: ^World, entity: int, data: rawptr) {
        if data == nil {
            return
        }
        
        restore := cast(^Hurt_Restore(T))data
        logic.add_component(restore.storage, restore.entity, restore.comp)
        
        // Timer system will free the data
    }
}
