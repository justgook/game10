package particles

import sg "../../sokol/gfx"
import "core:math/linalg"

// Particle Renderer
//
// GPU instanced particle rendering with support for:
// - Normal and additive blending
// - Texture atlas UV mapping
// - Per-particle color, scale, rotation

PARTICLE_RENDER_MAX :: 4096

// Base quad vertices (unit quad centered at origin)
BASE_VERTICES := [?][2]f32{{-0.5, -0.5}, {-0.5, 0.5}, {0.5, -0.5}, {0.5, 0.5}}
BASE_INDICES := [?]u16{0, 1, 2, 2, 1, 3}

// Per-instance data sent to GPU
Particle_Instance :: struct {
    pos:      [2]f32,  // World position
    scale:    [2]f32,  // Scale X, Y
    rotation: f32,     // Rotation in radians
    color:    [4]f32,  // RGBA
    uv:       [4]f32,  // UV rect: xy = min, zw = max
    pivot:    [2]f32,  // Pivot point (0-1)
}

// Particle renderer for a specific blend mode
Particle_Batch :: struct {
    instances: [PARTICLE_RENDER_MAX]Particle_Instance,
    count:     int,
    pip:       sg.Pipeline,
    bind:      sg.Bindings,
}

// Full particle renderer with both blend modes
Particle_Renderer :: struct {
    // Batches for different blend modes
    normal:   Particle_Batch,
    additive: Particle_Batch,
    
    // Shared resources
    vertex_buffer: sg.Buffer,
    index_buffer:  sg.Buffer,
}

init :: proc() -> Particle_Renderer {
    r: Particle_Renderer
    
    // Create shared vertex/index buffers
    r.vertex_buffer = sg.make_buffer({
        usage = {vertex_buffer = true, immutable = true},
        data = {ptr = &BASE_VERTICES, size = size_of(BASE_VERTICES)},
    })
    
    r.index_buffer = sg.make_buffer({
        usage = {index_buffer = true, immutable = true},
        data = {ptr = &BASE_INDICES, size = size_of(BASE_INDICES)},
    })
    
    // Initialize normal blend batch
    r.normal = init_batch(r.vertex_buffer, r.index_buffer, false)
    
    // Initialize additive blend batch
    r.additive = init_batch(r.vertex_buffer, r.index_buffer, true)
    
    return r
}

@(private="file")
init_batch :: proc(vertex_buffer, index_buffer: sg.Buffer, additive: bool) -> Particle_Batch {
    batch: Particle_Batch
    
    // Instance buffer
    instance_buffer := sg.make_buffer({
        usage = {vertex_buffer = true, stream_update = true},
        size = PARTICLE_RENDER_MAX * size_of(Particle_Instance),
    })
    
    // Blend state
    blend_state: sg.Blend_State
    if additive {
        blend_state = {
            enabled = true,
            src_factor_rgb = .SRC_ALPHA,
            dst_factor_rgb = .ONE,  // Additive
            src_factor_alpha = .ONE,
            dst_factor_alpha = .ONE,
        }
    } else {
        blend_state = {
            enabled = true,
            src_factor_rgb = .SRC_ALPHA,
            dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
            src_factor_alpha = .ONE,
            dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
        }
    }
    
    // Pipeline
    pip_desc := sg.Pipeline_Desc{
        shader = sg.make_shader(particle_shader_desc(sg.query_backend())),
        index_type = .UINT16,
        cull_mode = .NONE,  // Particles can face any direction
        depth = {
            compare = .LESS_EQUAL,
            write_enabled = false,  // Particles don't write depth
        },
        layout = {
            buffers = {1 = {step_func = .PER_INSTANCE}},
            attrs = {
                ATTR_particle_pos = {format = .FLOAT2, buffer_index = 0},
                ATTR_particle_inst_pos = {format = .FLOAT2, buffer_index = 1},
                ATTR_particle_inst_scale = {format = .FLOAT2, buffer_index = 1},
                ATTR_particle_inst_rotation = {format = .FLOAT, buffer_index = 1},
                ATTR_particle_inst_color = {format = .FLOAT4, buffer_index = 1},
                ATTR_particle_inst_uv = {format = .FLOAT4, buffer_index = 1},
                ATTR_particle_inst_pivot = {format = .FLOAT2, buffer_index = 1},
            },
        },
        colors = {0 = {blend = blend_state}},
    }
    
    batch.pip = sg.make_pipeline(pip_desc)
    batch.bind.vertex_buffers[0] = vertex_buffer
    batch.bind.vertex_buffers[1] = instance_buffer
    batch.bind.index_buffer = index_buffer
    
    return batch
}

cleanup :: proc(r: ^Particle_Renderer) {
    sg.destroy_buffer(r.vertex_buffer)
    sg.destroy_buffer(r.index_buffer)
    sg.destroy_pipeline(r.normal.pip)
    sg.destroy_pipeline(r.additive.pip)
    sg.destroy_buffer(r.normal.bind.vertex_buffers[1])
    sg.destroy_buffer(r.additive.bind.vertex_buffers[1])
}

set_texture :: proc(r: ^Particle_Renderer, tex: sg.Image) {
    view := sg.make_view({texture = {image = tex}})
    r.normal.bind.views[VIEW_tex0] = view
    r.additive.bind.views[VIEW_tex0] = view
    
    sampler := sg.make_sampler({})
    r.normal.bind.samplers[SMP_default_sampler] = sampler
    r.additive.bind.samplers[SMP_default_sampler] = sampler
}

// Clear all batches (call at start of frame)
clear :: proc(r: ^Particle_Renderer) {
    r.normal.count = 0
    r.additive.count = 0
}

// Add a particle to the appropriate batch
add :: proc(r: ^Particle_Renderer, additive: bool, inst: Particle_Instance) {
    batch := additive ? &r.additive : &r.normal
    if batch.count >= PARTICLE_RENDER_MAX {
        return  // Batch full
    }
    batch.instances[batch.count] = inst
    batch.count += 1
}

// Draw all particles
draw :: proc(r: ^Particle_Renderer, ortho: ^linalg.Matrix4f32) {
    vs_params := Vs_Params{ortho = ortho^}
    
    // Draw normal blend particles
    if r.normal.count > 0 {
        draw_batch(&r.normal, &vs_params)
    }
    
    // Draw additive blend particles (on top)
    if r.additive.count > 0 {
        draw_batch(&r.additive, &vs_params)
    }
}

@(private="file")
draw_batch :: proc(batch: ^Particle_Batch, vs_params: ^Vs_Params) {
    // Update instance buffer
    sg.update_buffer(
        batch.bind.vertex_buffers[1],
        {ptr = &batch.instances, size = uint(batch.count * size_of(Particle_Instance))},
    )
    
    sg.apply_pipeline(batch.pip)
    sg.apply_bindings(batch.bind)
    sg.apply_uniforms(UB_vs_params, {ptr = vs_params, size = size_of(Vs_Params)})
    sg.draw(0, 6, batch.count)
}
