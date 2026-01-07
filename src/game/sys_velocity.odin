package game

import "logic"

Velocity :: [2]int
sys_velocity :: proc(w: ^World) {
	view := logic.view(&w.position, &w.velocity)
	for _, pos, vel in logic.each(&view) {
		pos.x += vel.x * 2
		pos.y += vel.y
	}
}
