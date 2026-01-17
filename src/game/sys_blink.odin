package game

import "logic"

// Blink system - updates all blink components each frame
sys_blink :: proc(w: ^World) {
    view := logic.view(&w.blink)
    for _, blink in logic.each(&view) {
        blink_update(blink)
    }
}
