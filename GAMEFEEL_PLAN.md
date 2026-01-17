# Game Feel Implementation Plan

This document outlines the features to implement from the [deepnight/gamefeel](https://github.com/deepnight/gamefeel) demo, adapted for our Odin/Sokol ECS architecture.

**Design Principle**: Features are implemented as components/systems. Adding a component or enabling a system acts as a toggle.

---

## Quick Status Checklist

### Phase 1: Foundation
- [x] **1.1 Camera System** - Tracking, shake, bump, zoom effects
- [x] **1.2 Timer/Cooldown System** - Frame-based timers with callbacks
- [x] **1.3 Input Buffering** - Queue inputs during lock states
- [x] **1.4 Coyote Time** - Jump grace period after leaving ground

### Phase 2: Visual Feedback
- [x] **2.1 Squash & Stretch** - Sprite distortion on events
- [ ] **2.2 Entity Blink** - Flash on damage
- [ ] **2.3 Sprite Shake** - Per-entity shake
- [ ] **2.4 Screen Flash** - Full-screen color flash

### Phase 3: Particles
- [ ] **3.1 GPU Particle System** - Pooled particles with physics

### Phase 4: Combat Effects
- [ ] **4.1 Gun/Weapon Effects** - Muzzle flash, cartridges, recoil
- [ ] **4.2 Impact Effects** - Hit particles, blood, wall burns
- [ ] **4.3 Enemy Reactions** - Knockback, ground pound

### Phase 5: Movement Abilities
- [ ] **5.1 Double Jump** - Air jump with effects
- [ ] **5.2 Dash Ability** - Quick movement with trail
- [ ] **5.3 Traversal Helpers** - Auto step-up, cliff grab

### Phase 6: Game State
- [ ] **6.1 Slow Motion** - Time dilation effects
- [ ] **6.2 Control Locks** - Temporary input disable
- [ ] **6.3 Affect System** - Status effects (stun, slow)

### Phase 7: Animation
- [ ] **7.1 Basic Animations** - Idle, run, jump states
- [ ] **7.2 Weapon Animations** - Aim, shoot, recoil

---

## Completed Features

### 1.1 Camera System ✅

**Location**: `src/game/camera/camera.odin`

**How it works**:

The camera is a singleton struct stored in `World.cam` (not a component). It provides smooth tracking with dead zones, plus visual effects (shake, bump, zoom bump).

**Key structures**:
```odin
Camera :: struct {
    position:        [2]f32,      // Current camera position in pixels
    zoom:            f32,         // Target zoom level
    current_zoom:    f32,         // Smoothed zoom (interpolates to target)
    target_entity:   int,         // Entity ID to follow (-1 = none)
    target_offset:   [2]f32,      // Offset from target
    config:          Camera_Config,
    shake:           Shake_State, // Active shake effect
    bump:            Bump_State,  // Active bump offset
    zoom_bump:       f32,         // Instant zoom change that decays
    velocity:        [2]f32,      // For smooth movement
}
```

**Usage**:
```odin
// Track an entity
camera.camera_track(&w.cam, player_id, immediate = true)

// Trigger effects
camera.camera_shake(&w.cam, power_x, power_y, duration_seconds)
camera.camera_bump(&w.cam, offset_x, offset_y)
camera.camera_bump_zoom(&w.cam, zoom_amount)

// Get render matrix (in render.odin)
viewport := [2]f32{sapp.widthf(), sapp.heightf()}
matrix := camera.camera_get_matrix(&w.cam, viewport)
```

**Integration points**:
- `world.odin`: `sys_camera()` runs every frame, updates camera based on tracked entity
- `render.odin`: `update_ortho()` uses `camera_get_matrix()` for view transform
- `sys_movement.odin`: Triggers shake/bump on landing and jumping
- `main.odin`: Debug keys F1-F5 for testing effects

**Debug controls** (debug builds only):
- **F1**: Test camera shake
- **F2**: Test camera bump
- **F4**: Test zoom bump
- **F5**: Toggle zoom (1x ↔ 2x)

**Effect triggers currently implemented**:
- Landing from height → shake + bump (power based on fall velocity)
- Heavy landing → zoom bump
- Jump start → small upward bump

---

## Phase 1: Foundation Systems

### 1.1 Camera System
**Priority**: HIGH | **Status**: ✅ DONE

The camera is the player's window into the game world. A good camera system makes everything feel more responsive and impactful.

| Feature | Description | Trigger | Status |
|---------|-------------|---------|--------|
| **Smooth Tracking** | Camera follows target with configurable speed and dead zones | Always | ✅ |
| **Camera Shake** | Shake the camera horizontally or vertically | Player shoots (X), lands from height (Y) | ✅ |
| **Camera Bump** | Abruptly offset the camera for a short period | Player shoots, lands, dashes | ✅ |
| **Camera Zoom Bump** | Abruptly zoom-in the camera briefly | Player lands, dashes | ✅ |
| **Level Bounds Clamping** | Keep camera within level boundaries | Always | ✅ |

**Files created**:
- `src/game/camera/camera.odin` - All camera logic in one file

**Implementation Notes**:
- Camera uses f32 for smooth sub-pixel movement
- Effects (shake, bump) are additive and decay with friction
- Matrix generation happens at render time via `camera_get_matrix()`
- See "Completed Features" section above for detailed usage

---

### 1.2 Timer/Cooldown System
**Priority**: HIGH | **Status**: ✅ DONE

Foundation for timed effects, abilities, and state management.

**Location**: `src/game/sys_timer.odin`

**How it works**:

The Timer is a component that counts down frames and triggers callbacks. It can be used for timed effects, delayed actions, cooldowns, and particle lifetimes.

**Key structures**:
```odin
Timer :: struct {
    frames:             int,     // Remaining frames (decrements each tick)
    data:               rawptr,  // Optional data pointer for callbacks
    disable_autofree:   bool,    // If true, don't free `data` on complete
    delete_on_complete: bool,    // If true, delete entity when timer ends
    on_update:          proc(w: ^World, entity: int, data: rawptr),
    on_complete:        proc(w: ^World, entity: int, data: rawptr),
}
```

**Usage**:
```odin
// Simple timer that deletes entity on completion
timer := timer_create(60, on_complete_proc)  // 60 frames = 1 second at 60fps
logic.set_component(&w.timer, entity_id, timer)

// Timer with update callback (for effects that change over time)
timer := timer_create_with_update(30, on_update_proc, on_complete_proc)

// Get progress ratio for animations
ratio := timer_get_ratio(&timer, original_frames)  // 0.0 -> 1.0
remaining := timer_get_remaining_ratio(&timer, original_frames)  // 1.0 -> 0.0
```

**Integration points**:
- `world.odin`: `sys_timer()` runs in fixed update loop
- Timer component stored in `World.timer`
- Cleanup in `entity_delete()` and `world_cleanup()`

---

### 1.3 Input Buffering & 1.4 Coyote Time
**Priority**: HIGH | **Status**: ✅ DONE

These two systems work together to make jumping feel responsive:

**Location**: `src/game/input_buffer.odin`

**How it works**:

1. **INPUT BUFFERING**: If you press jump slightly BEFORE landing, the jump is buffered and executes when you land. Prevents "I pressed jump!" frustration.

2. **COYOTE TIME**: If you walk off a ledge, you have a brief grace period where you can still jump. Named after Wile E. Coyote running off cliffs.

**Key structures**:
```odin
JumpInput :: struct {
    pressed:              bool,  // Is jump button held this frame
    just_pressed:         bool,  // Was jump button pressed this frame
    buffer_frames:        int,   // Frames remaining in jump buffer
    coyote_frames:        int,   // Frames remaining for coyote time
    was_grounded:         bool,  // Was grounded last frame
}
```

**Configuration** (in `input_buffer.odin`):
```odin
JUMP_BUFFER_FRAMES :: 8   // ~0.13s - how long to remember a jump press
COYOTE_TIME_FRAMES :: 6   // ~0.1s - grace period after leaving ground
```

**Usage**:
```odin
// In movement update, call this to check if jump should execute
should_jump := jump_input_update(&state.jump_input, is_grounded, jump_button_down)
if should_jump {
    // Execute jump
}

// Helper functions for visual feedback
in_coyote := jump_input_in_coyote(&state.jump_input)
has_buffer := jump_input_has_buffer(&state.jump_input)
```

**Integration**:
- `JumpInput` is embedded in `JumpState` struct
- `update_movement_vertical()` calls `jump_input_update()` automatically
- Works with existing collision system that sets `can_jump`

---

## Phase 2: Visual Feedback

### 2.1 Squash & Stretch
**Priority**: HIGH | **Status**: ✅ DONE

> "Distort the hero/enemies like a jelly ball in reaction to external events."

Makes entities feel alive and reactive.

**Location**: `src/game/squash_stretch.odin`, `src/game/sys_squash.odin`

**How it works**:

The SquashStretch component modifies sprite scale with spring-like auto-recovery. Values bounce back to 1.0 naturally, creating a "jelly" effect.

**Key structures**:
```odin
SquashStretch :: struct {
    scale_x:     f32,  // Current X scale multiplier (1.0 = normal)
    scale_y:     f32,  // Current Y scale multiplier (1.0 = normal)
    velocity_x:  f32,  // Velocity for smooth spring animation
    velocity_y:  f32,
}
```

**Configuration** (in `squash_stretch.odin`):
```odin
SQUASH_RECOVERY_SPEED :: 0.15  // Spring strength (higher = faster recovery)
SQUASH_MIN :: 0.5              // Minimum scale allowed
SQUASH_MAX :: 1.5              // Maximum scale allowed
```

**Usage**:
```odin
// Add component to entity
logic.add_component(&w.squash, entity_id, squash_init())

// Trigger effects
squash_on_jump(&squash)           // Stretch vertically (0.8, 1.25)
squash_on_land(&squash, power)    // Squash vertically (power 0-1)
squash_on_dash(&squash, facing)   // Stretch horizontally (1.3, 0.8)
squash_on_hit(&squash)            // Quick squash (0.7, 1.3)

// Or set directly
squash_set(&squash, 0.7, 1.3)
squash_set_preserve_volume(&squash, 0.7)  // Auto-calculates Y
```

**Integration**:
- `sys_squash()` runs in fixed update loop, updates all squash components
- `render_sprite()` applies squash scale to sprite size
- `sys_movement()` triggers squash on jump and landing

**Current triggers**:
- Jump start → stretch vertically (0.8, 1.25)
- Landing → squash vertically (intensity based on fall speed)

---

### 2.2 Entity Blink
**Priority**: MEDIUM | **Status**: Pending

> "Produce a short white flash on entities when bullets hit."

Immediate visual feedback for damage.

**Components to create**:
- `BlinkEffect` - Color overlay with decay

---

### 2.3 Sprite Shake
**Priority**: MEDIUM | **Status**: Pending

Per-entity shake effect, independent of camera.

**Components to create**:
- `SpriteShake` - Shake power X/Y with duration

---

### 2.4 Screen Flash
**Priority**: LOW | **Status**: Pending

> "Produce a screen yellow flash when player shoots."

Full-screen color overlay for impactful moments.

**Implementation Notes**:
- Render colored quad over everything
- Fade out quickly (~0.1s)

---

## Phase 3: Particle System

### 3.1 GPU Particle System
**Priority**: MEDIUM | **Status**: Pending

Pooled particle system using GPU instancing.

| Feature | Description |
|---------|-------------|
| **Particle Pool** | Pre-allocated particle buffer |
| **Multiple Layers** | Background, main, foreground |
| **Blend Modes** | Normal, additive |
| **Physics** | Velocity, gravity, friction |
| **Visual** | Color animation, fade, scale |

**Collision Approach**:
- Particles check collision in compute/update pass
- Store collision state in particle data
- On collision: modify velocity, change behavior

**Particle Effects to Implement**:

| Effect | Description | Trigger |
|--------|-------------|---------|
| **Jump Smoke** | Small smoke puff | Player jumps, double-jumps, lands |
| **Dash Trail** | Lines of blue light | Player dashes |
| **Climb Dust** | Small dust particles | Player climbs step/cliff |
| **Landing Impact** | Dust cloud | Player lands from height |

---

## Phase 4: Combat Effects

### 4.1 Gun/Weapon Effects
**Priority**: MEDIUM | **Status**: Pending

| Effect | Description | Trigger |
|--------|-------------|---------|
| **Muzzle Flash** | Brief burst particles at weapon | Player shoots |
| **Cartridge Ejection** | Small particles that bounce | Player shoots |
| **Bullet Trail** | Short tail of light on bullets | Bullet moves |
| **Gun Recoil (Visual)** | Offset sprite without affecting physics | Player shoots |
| **Gun Recoil (Physical)** | Slight entity movement | Player shoots |
| **Randomize Bullets** | Slight spread variation | Player shoots |

---

### 4.2 Impact Effects
**Priority**: MEDIUM | **Status**: Pending

| Effect | Description | Trigger |
|--------|-------------|---------|
| **Impact Particles** | Brief particles at impact point | Bullet hits anything |
| **Impact Dust** | Falling dust particles | Bullet hits anything |
| **Wall Burn** | Particles that fade yellow->red | Bullet hits wall |
| **Blood Particles** | Stick to walls, long-lasting | Bullet hits enemy |
| **Light Spot** | Yellow halo particle | Shoot or impact |

---

### 4.3 Enemy Reactions
**Priority**: MEDIUM | **Status**: Pending

> "Physical movements of enemy entities. They may fall from a cliff because of these."

| Effect | Description | Trigger |
|--------|-------------|---------|
| **Knockback** | Push enemies on hit | Bullet hits enemy |
| **Ground Pound** | Push nearby enemies | Player lands from height |
| **Cadavers** | Dead enemy becomes physics object | Enemy dies |

---

## Phase 5: Movement Abilities

### 5.1 Double Jump
**Priority**: LOW | **Status**: Pending

Air jump with visual feedback.

| Feature | Description |
|---------|-------------|
| **Air Jump** | One additional jump in air |
| **Visual Feedback** | Smoke puff, squash effect |
| **Reduced Gravity** | Brief gravity reduction after jump |

---

### 5.2 Dash Ability
**Priority**: LOW | **Status**: Pending

> "Quick dash movement with trail effects."

| Feature | Description |
|---------|-------------|
| **Dash Movement** | Quick horizontal burst |
| **Dash Trail** | Blue light trail particles |
| **Slow Motion** | Brief slow-mo during dash |
| **Control Lock** | Brief input lock during dash |
| **Cooldown** | Prevent spam |

---

### 5.3 Traversal Helpers
**Priority**: LOW | **Status**: Pending

| Feature | Description |
|---------|-------------|
| **Small Steps** | Auto-jump small obstacles when walking |
| **Cliff Grab** | Auto-grab ledge when missing by few pixels |
| **Climb Dust** | Particle effect on assist |

**Implementation Notes**:
- Mark tiles/areas with step/cliff metadata
- Check during horizontal movement
- Apply small velocity adjustment

---

## Phase 6: Game State

### 6.1 Slow Motion System
**Priority**: MEDIUM | **Status**: Pending

> "Slow down the game to give slightly more time for movement anticipation."

| Feature | Description | Trigger |
|---------|-------------|---------|
| **Cumulative Slow-Mo** | Multiple sources stack | Dash, big hits |
| **Smooth Transition** | Lerp to target speed | Always |
| **Stop Frame** | 1-frame pause for impact | Big hits |

**Implementation Notes**:
- Modify `sim_frame_length` or time multiplier
- Some systems (UI, input) run at real-time

---

### 6.2 Control Locks
**Priority**: LOW | **Status**: Pending

> "Briefly lock player controls to simulate a short 'stun' moment after intense events."

| Feature | Description | Trigger |
|---------|-------------|---------|
| **Landing Stun** | Brief lock after high fall | Land from height |
| **Hit Stun** | Brief lock when damaged | Take damage |
| **Action Lock** | Lock during certain actions | Shooting, dashing |

---

### 6.3 Affect/Status System
**Priority**: LOW | **Status**: Pending

Temporary gameplay effects with duration.

| Feature | Description |
|---------|-------------|
| **Stun** | Cannot act |
| **Slow** | Reduced speed |
| **Invincible** | Cannot take damage |

---

## Phase 7: Animation & Rendering

### 7.1 Basic Animations
**Priority**: LOW | **Status**: Pending

> "Activate simple animations for the player."

| Animation | States |
|-----------|--------|
| **Idle** | Standing still |
| **Run** | Moving horizontally |
| **Jump Up** | Rising in air |
| **Jump Down** | Falling |
| **Land** | Brief landing pose |

---

### 7.2 Weapon Animations
**Priority**: LOW | **Status**: Pending

> "Activate weapon related animations (aiming and shooting)."

| Animation | States |
|-----------|--------|
| **Ready Weapon** | Preparing to shoot |
| **Idle Weapon** | Holding weapon ready |
| **Shoot** | Firing animation |
| **Recoil** | Post-shot recovery |

---

## Missing Mechanics (Not in GameFeel Demo)

These are common game mechanics not covered by the demo:

### Core Mechanics
| Mechanic | Description | Priority |
|----------|-------------|----------|
| **Health System** | HP, damage, death | HIGH |
| **Invincibility Frames** | Brief immunity after damage | HIGH |
| **Respawn/Checkpoint** | Death handling | MEDIUM |
| **Collectibles** | Coins, items, powerups | MEDIUM |

### Movement
| Mechanic | Description | Priority |
|----------|-------------|----------|
| **Wall Jump** | Jump off walls | MEDIUM |
| **Wall Slide** | Slow fall on walls | MEDIUM |
| **Crouch/Slide** | Duck under obstacles | LOW |
| **Swimming** | Water physics | LOW |
| **Climbing** | Ladders, ropes | LOW |

### Combat
| Mechanic | Description | Priority |
|----------|-------------|----------|
| **Melee Attack** | Close-range combat | MEDIUM |
| **Combo System** | Chained attacks | LOW |
| **Blocking/Parry** | Defensive options | LOW |
| **Enemy AI** | Basic enemy behaviors | MEDIUM |
| **Boss Patterns** | Complex enemy behaviors | LOW |

### World
| Mechanic | Description | Priority |
|----------|-------------|----------|
| **Moving Platforms** | Platforms that move | MEDIUM |
| **Hazards** | Spikes, lava, etc. | MEDIUM |
| **Doors/Switches** | Interactive elements | MEDIUM |
| **Destructibles** | Breakable objects | LOW |
| **Secrets** | Hidden areas | LOW |

### Meta
| Mechanic | Description | Priority |
|----------|-------------|----------|
| **Save/Load** | Game persistence | MEDIUM |
| **Level Transitions** | Scene changes | MEDIUM |
| **Pause Menu** | Game pause with menu | MEDIUM |
| **Settings** | Audio, controls, etc. | LOW |
| **Achievements** | Progress tracking | LOW |

---

## Implementation Order

Recommended order based on dependencies and impact:

```
Phase 1: Foundation (do first)
  1.1 Camera System ✅ DONE
  1.2 Timer/Cooldown System ✅ DONE
  1.3 Input Buffering ✅ DONE
  1.4 Coyote Time ✅ DONE

Phase 2: Visual Feedback
  2.1 Squash & Stretch ✅ DONE
  2.2 Entity Blink ← NEXT
  2.3 Sprite Shake
  2.4 Screen Flash

Phase 3: Particles
  3.1 GPU Particle System

Phase 4: Combat (if game has combat)
  4.1 Gun/Weapon Effects
  4.2 Impact Effects
  4.3 Enemy Reactions

Phase 5: Movement
  5.1 Double Jump
  5.2 Dash Ability
  5.3 Traversal Helpers

Phase 6: Game State
  6.1 Slow Motion
  6.2 Control Locks
  6.3 Affect System

Phase 7: Animation
  7.1 Basic Animations
  7.2 Weapon Animations
```

---

## File Structure (Proposed)

```
src/game/
├── camera/
│   └── camera.odin          # Camera state, effects, matrix generation ✅
├── effects/
│   ├── squash_stretch.odin  # Squash & stretch component
│   ├── blink.odin           # Entity blink effect
│   ├── shake.odin           # Sprite shake effect
│   └── screen_flash.odin    # Full-screen flash
├── particles/
│   ├── particle_system.odin # GPU particle pool
│   ├── particle_types.odin  # Particle configurations
│   └── emitters.odin        # Particle emitter helpers
├── input/
│   ├── input_buffer.odin    # Input buffering system
│   └── control_lock.odin    # Control lock component
├── timing/
│   ├── cooldown.odin        # Cooldown system
│   ├── slow_motion.odin     # Time dilation
│   └── affect.odin          # Status effects
└── movement/
    ├── coyote_time.odin     # Jump grace period
    ├── double_jump.odin     # Air jump
    ├── dash.odin            # Dash ability
    └── traversal.odin       # Step/cliff helpers
```

---

## Notes

- All timing uses subpixel integers where applicable
- Effects are components that systems process
- Adding/removing components toggles features
- Particle collision uses grid lookup (same as entity collision)
