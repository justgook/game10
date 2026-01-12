package menu

// Odin bindings for sokol_nuklear and menu C library
// Provides Nuklear UI integration for the game
//
// Usage:
//   1. Build C libraries: cd src/game/menu && ./build_macos.sh (or appropriate script)
//   2. In game_init(): menu.init()
//   3. In game_event(): if menu.handle_event(e) { return }
//   4. In render_frame(): ctx := menu.new_frame(); menu.draw(ctx); ... menu.render(w, h)
//   5. In game_cleanup(): menu.shutdown()

import "core:c"
import sg "../sokol/gfx"
import sapp "../sokol/app"
import slog "../sokol/log"

// ============ Build Configuration ============
// Matches sokol bindings pattern

SOKOL_DEBUG :: #config(SOKOL_DEBUG, ODIN_DEBUG)
DEBUG :: #config(SOKOL_MENU_DEBUG, SOKOL_DEBUG)
USE_GL :: #config(SOKOL_USE_GL, false)
USE_DLL :: #config(SOKOL_DLL, false)

// ============ Foreign Imports ============
// Platform-specific library imports following sokol pattern

when ODIN_OS == .Windows {
    when USE_GL {
        when DEBUG {
            foreign import snk_clib { "lib/sokol_nuklear_windows_x64_gl_debug.lib" }
            foreign import menu_clib { "lib/menu_windows_x64_gl_debug.lib" }
        } else {
            foreign import snk_clib { "lib/sokol_nuklear_windows_x64_gl_release.lib" }
            foreign import menu_clib { "lib/menu_windows_x64_gl_release.lib" }
        }
    } else {
        when DEBUG {
            foreign import snk_clib { "lib/sokol_nuklear_windows_x64_d3d11_debug.lib" }
            foreign import menu_clib { "lib/menu_windows_x64_d3d11_debug.lib" }
        } else {
            foreign import snk_clib { "lib/sokol_nuklear_windows_x64_d3d11_release.lib" }
            foreign import menu_clib { "lib/menu_windows_x64_d3d11_release.lib" }
        }
    }
} else when ODIN_OS == .Darwin {
    when USE_GL {
        when ODIN_ARCH == .arm64 {
            when DEBUG {
                foreign import snk_clib { "lib/sokol_nuklear_macos_arm64_gl_debug.a" }
                foreign import menu_clib { "lib/menu_macos_arm64_gl_debug.a" }
            } else {
                foreign import snk_clib { "lib/sokol_nuklear_macos_arm64_gl_release.a" }
                foreign import menu_clib { "lib/menu_macos_arm64_gl_release.a" }
            }
        } else {
            when DEBUG {
                foreign import snk_clib { "lib/sokol_nuklear_macos_x64_gl_debug.a" }
                foreign import menu_clib { "lib/menu_macos_x64_gl_debug.a" }
            } else {
                foreign import snk_clib { "lib/sokol_nuklear_macos_x64_gl_release.a" }
                foreign import menu_clib { "lib/menu_macos_x64_gl_release.a" }
            }
        }
    } else {
        when ODIN_ARCH == .arm64 {
            when DEBUG {
                foreign import snk_clib { "lib/sokol_nuklear_macos_arm64_metal_debug.a" }
                foreign import menu_clib { "lib/menu_macos_arm64_metal_debug.a" }
            } else {
                foreign import snk_clib { "lib/sokol_nuklear_macos_arm64_metal_release.a" }
                foreign import menu_clib { "lib/menu_macos_arm64_metal_release.a" }
            }
        } else {
            when DEBUG {
                foreign import snk_clib { "lib/sokol_nuklear_macos_x64_metal_debug.a" }
                foreign import menu_clib { "lib/menu_macos_x64_metal_debug.a" }
            } else {
                foreign import snk_clib { "lib/sokol_nuklear_macos_x64_metal_release.a" }
                foreign import menu_clib { "lib/menu_macos_x64_metal_release.a" }
            }
        }
    }
} else when ODIN_OS == .Linux {
    when DEBUG {
        foreign import snk_clib { "lib/sokol_nuklear_linux_x64_gl_debug.a", "system:GL", "system:dl", "system:pthread" }
        foreign import menu_clib { "lib/menu_linux_x64_gl_debug.a" }
    } else {
        foreign import snk_clib { "lib/sokol_nuklear_linux_x64_gl_release.a", "system:GL", "system:dl", "system:pthread" }
        foreign import menu_clib { "lib/menu_linux_x64_gl_release.a" }
    }
} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    // For WASM, feed sokol_nuklear_wasm_gl_*.a and menu_wasm_gl_*.a into emscripten
    foreign import snk_clib { "env.o" }
    foreign import menu_clib { "env.o" }
} else {
    #panic("This OS is currently not supported")
}

// ============ Types ============

// Nuklear context - opaque pointer to nk_context
Nk_Context :: rawptr

// Memory allocator override
Allocator :: struct {
    alloc_fn:  proc "c" (size: c.size_t, user_data: rawptr) -> rawptr,
    free_fn:   proc "c" (ptr: rawptr, user_data: rawptr),
    user_data: rawptr,
}

// Logger callback
Logger :: struct {
    func: proc "c" (
        tag: cstring,
        log_level: u32,
        log_item_id: u32,
        message_or_null: cstring,
        line_nr: u32,
        filename_or_null: cstring,
        user_data: rawptr,
    ),
    user_data: rawptr,
}

// sokol_nuklear setup descriptor
Desc :: struct {
    max_vertices:            c.int,            // default: 65536
    image_pool_size:         c.int,            // default: 256
    color_format:            sg.Pixel_Format,  // default: SG_PIXELFORMAT_RGBA8
    depth_format:            sg.Pixel_Format,  // default: SG_PIXELFORMAT_DEPTHSTENCIL
    sample_count:            c.int,            // default: 1
    dpi_scale:               f32,              // default: 1.0
    no_default_font:         bool,             // default: false
    enable_set_mouse_cursor: bool,             // default: false
    allocator:               Allocator,
    logger:                  Logger,
}

// Handle for custom images
Image :: struct {
    id: u32,
}

// Image descriptor for snk_make_image
Image_Desc :: struct {
    texture_view: sg.View,
    sampler:      sg.Sampler,
}

// ============ sokol_nuklear Functions ============

@(default_calling_convention = "c", link_prefix = "snk_")
foreign snk_clib {
    // Initialize sokol_nuklear
    setup :: proc(#by_ptr desc: Desc) ---

    // Call at start of frame, returns nuklear context for UI building
    new_frame :: proc() -> Nk_Context ---

    // Render the UI (call before sg.end_pass())
    render :: proc(width, height: c.int) ---

    // Shutdown sokol_nuklear
    shutdown :: proc() ---

    // Handle input event, returns true if event was consumed by UI
    handle_event :: proc(event: ^sapp.Event) -> bool ---

    // Image management
    make_image :: proc(#by_ptr desc: Image_Desc) -> Image ---
    destroy_image :: proc(img: Image) ---
    query_image_desc :: proc(img: Image) -> Image_Desc ---
}

// ============ Menu Functions (from menu.c) ============

@(default_calling_convention = "c", link_prefix = "menu_")
foreign menu_clib {
    // Draw the game menu UI
    draw :: proc(ctx: Nk_Context) ---
}

// ============ Convenience Functions ============

// Initialize sokol_nuklear with sensible defaults
// Call this in game_init() after sg.setup()
init :: proc() {
    setup({
        dpi_scale = sapp.dpi_scale(),
        logger = {func = slog.func},
    })
}
