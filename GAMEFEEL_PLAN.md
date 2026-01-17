# Game Feel Implementation Plan

This document outlines the features to implement from the [deepnight/gamefeel](https://github.com/deepnight/gamefeel) demo, adapted for our Odin/Sokol ECS architecture.

**Design Principle**: Features are implemented as components/systems. Adding a component or enabling a system acts as a toggle.

---

## Phase 1: Foundation Systems

### 1.1 Camera System
**Priority**: HIGH | **Status**: Pending

The camera is the player's window into the game world. A good camera system makes everything feel more responsive and impactful.

| Feature | Description | Trigger |
|---------|-------------|---------|
| **Smooth Tracking** | Camera follows target with configurable speed and dead zones | Always |
| **Camera Shake** | Shake the camera horizontally or vertically | Player shoots (X), lands from height (Y) |
| **Camera Bump** | Abruptly offset the camera for a short period | Player shoots, lands, dashes |
| **Camera Zoom Bump** | Abruptly zoom-in the camera briefly | Player lands, dashes |
| **Level Bounds Clamping** | Keep camera within level boundaries | Always |

**Components to create**:
- `Camera` - Main camera state (position, zoom, target, dead zones)
- `CameraShake` - Active shake effect
- `CameraBump` - Active bump offset

**Implementation Notes**:
- Camera position uses subpixel integers internally
- Final matrix conversion happens at render time
- Shake/bump effects are additive and decay over time

---

### 1.2 Cooldown System
**Priority**: HIGH | **Status**: Pending

Foundation for timed effects, abilities, and state management.

| Feature | Description |
|---------|-------------|
| **Named Cooldowns** | Set/check/get cooldowns by ID |
| **Real-time Cooldowns** | Unaffected by slow-mo (for UI, etc.) |
| **Ratio Access** | Get remaining ratio for animations |

**Components to create**:
- `Cooldowns` - Map of cooldown timers per entity

---

### 1.3 Input Buffering
**Priority**: HIGH | **Status**: Pending

> "Queue Player inputs to avoid losing them when the Player is 'locked' (eg. stunned)."

Prevents frustrating input drops during brief lock states.

| Feature | Description |
|---------|-------------|
| **Input Queue** | Buffer inputs for ~0.1-0.15s |
| **Consume on Unlock** | Execute buffered input when controls unlock |

**Implementation Notes**:
- Store last N frames of input with timestamps
- Check buffer when action becomes available

---

### 1.4 Coyote Time (Just-In-Time Jump)
**Priority**: HIGH | **Status**: Pending

> "Allows the Player to jump even if it's no longer on the ground."

One of the most impactful platformer feel improvements.

| Feature | Description |
|---------|-------------|
| **Grace Period** | ~0.1-0.15s window after leaving ground |
| **Jump Buffering** | Accept jump input slightly before landing |

**Implementation Notes**:
- Track `time_since_grounded` 
- Allow jump if `time_since_grounded < COYOTE_TIME`

---

## Phase 2: Visual Feedback

### 2.1 Squash & Stretch
**Priority**: HIGH | **Status**: Pending

> "Distort the hero/enemies like a jelly ball in reaction to external events."

Makes entities feel alive and reactive.

| Feature | Description | Trigger |
|---------|-------------|---------|
| **Hero Squash** | Distort player sprite | Jumps, lands, dashes, shoots |
| **Enemy Squash** | Distort enemy sprites | Hit by bullets |

**Components to create**:
- `SquashStretch` - Current scale X/Y with auto-recovery

**Implementation Notes**:
- `squash_x` and `squash_y` multiply sprite scale
- Auto-lerp back to 1.0 each frame
- Preserve volume: if X shrinks, Y grows (and vice versa)

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
  1.1 Camera System ← START HERE
  1.2 Cooldown System
  1.3 Input Buffering  
  1.4 Coyote Time

Phase 2: Visual Feedback
  2.1 Squash & Stretch
  2.2 Entity Blink
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
│   ├── camera.odin          # Camera component & system
│   └── camera_effects.odin  # Shake, bump, zoom effects
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
