# Nuklear Menu & HUD System

Minimal C wrapper for Nuklear UI integrated into the Odin game engine.

## Features

- **Debug HUD**: Real-time display of game state
  - Player position, velocity, jump state
  - Entity count, pause state
  - Camera position and zoom
  - FPS and frame time
- **Main Menu**: Pause menu with options
- **Hot Reload Support**: Automatically reinitializes on DLL reload

## Controls

- **ESC**: Toggle main menu
- **F3**: Toggle debug HUD
- **F6**: Force game restart

## File Structure

```
menu/
├── c/
│   ├── nuklear.h          # Nuklear library (from official repo)
│   ├── sokol_nuklear.h    # sokol_nuklear integration
│   ├── sokol_nuklear.c    # Implementation
│   └── menu.c             # Game-specific menu/HUD code
├── lib/                   # Compiled libraries (16 variants)
├── menu.odin              # Odin bindings
├── build_macos.sh         # macOS build script
├── build_linux.sh         # Linux build script
├── build_windows.cmd      # Windows build script
└── build_wasm.sh          # WebAssembly build script
```

## Building

```bash
# macOS (arm64 + x64, Metal + GL, debug + release)
cd src/game/menu && ./build_macos.sh

# Linux (x64, GL, debug + release)
cd src/game/menu && ./build_linux.sh

# Windows (x64, D3D11 + GL, debug + release)
cd src\game\menu && build_windows.cmd

# WebAssembly (GLES3, debug + release)
cd src/game/menu && ./build_wasm.sh
```

## Usage in Game Code

### Initialization (main.odin)

```odin
import menu "menu"

@(export)
game_init :: proc() {
    sg.setup({...})
    menu.init()  // After sg.setup()
}

@(export)
game_event :: proc(e: ^sapp.Event) {
    // Toggle menu/HUD with keys
    if e.key_code == .ESCAPE {
        menu.toggle()
        return
    }
    if e.key_code == .F3 {
        menu.toggle_debug_hud()
        return
    }
    
    // Let menu consume events when visible
    if menu.handle_event(e) {
        return
    }
    // ... rest of event handling
}

@(export)
game_cleanup :: proc() {
    menu.shutdown()
    sg.shutdown()
}
```

### Rendering (render.odin)

```odin
render_frame :: proc(w: ^World, r: ^Render) {
    // Prepare HUD data
    hud_data := prepare_hud_data(w, r)
    
    // Start nuklear frame
    ctx := menu.new_frame()
    menu.draw_with_hud(ctx, hud_data)
    
    // ... game rendering ...
    
    sg.begin_pass({...})
    // ... render sprites, etc ...
    
    // Render UI (before end_pass)
    menu.render(sapp.width(), sapp.height())
    sg.end_pass()
    sg.commit()
}
```

### Hot Reload Support (render.odin)

```odin
render_reloaded :: proc(r: ^Render) {
    // Reinitialize nuklear after DLL reload
    menu.init()
    
    // ... reinit other systems ...
}
```

## Adding Custom Menu Elements

Edit `src/game/menu/c/menu.c` to add new UI elements. Example:

```c
// In menu.c
static void draw_custom_panel(struct nk_context* ctx, const HudData* data) {
    if (nk_begin(ctx, "My Panel", nk_rect(10, 10, 200, 100), NK_WINDOW_BORDER)) {
        nk_layout_row_dynamic(ctx, 20, 1);
        nk_label(ctx, "Hello World", NK_TEXT_LEFT);
        
        if (nk_button_label(ctx, "Click Me")) {
            // Handle button click
        }
    }
    nk_end(ctx);
}
```

Then call it from `menu_draw_with_hud()`.

## Passing Data from Odin to C

1. Add fields to `Hud_Data` struct in both `menu.c` and `menu.odin`
2. Populate data in `prepare_hud_data()` in `render.odin`
3. Use data in `draw_debug_hud()` or custom draw functions in `menu.c`

## Platform Support

- ✅ macOS (arm64 + x64, Metal + GL)
- ✅ Linux (x64, GL)
- ✅ Windows (x64, D3D11 + GL)
- ✅ WebAssembly (GLES3)
- ✅ Hot reload support (macOS/Linux/Windows)

## Notes

- Keep the `sokol/` folder clean - don't modify build scripts there
- All nuklear-related code stays in `menu/` folder
- C code handles UI rendering, Odin handles game state
- Libraries must be rebuilt after modifying `menu.c` or `sokol_nuklear.c`
