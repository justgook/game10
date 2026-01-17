package game

import "logic"

// Squash & Stretch system - updates all squash components each frame
sys_squash :: proc(w: ^World) {
    view := logic.view(&w.squash)
    for _, squash in logic.each(&view) {
        squash_update(squash)
    }
}
