package game

import "core:fmt"
import "logic"
import sapp "sokol/app"


LOCALES_DIR :: #config(LOCALES_DIR, "../../build.nosync/locales")


World :: struct {
	pasued:           bool,
	next_entity_id:   int,
	sim_frame_length: f64,
	accumulator:      f64,
	camera:           [2]f32,
	zoom:             f32,
	// Components
	gui_position:     logic.Component_Storage(Position), // used to position element in absolute coordinates, think how to add click and other system interaction
	position:         logic.Component_Storage(Position),
	velocity:         logic.Component_Storage(Velocity),
	sprite:           logic.Component_Storage(Sprite),
}

world_init :: proc(w: ^World) {
	fmt.println("WORLD init")

	_ = entity_delete
	w.sim_frame_length = 1.0 / 60.0
	w.camera = {sapp.widthf() / 2, sapp.heightf() / 2}
	w.zoom = 1


	// change_scene(w, "build.nosync/dd-000-000.wbin")


	player := create_entity(w)
	logic.add_component(&w.velocity, player, Velocity{1, 0})
	logic.add_component(&w.position, player, Position{0, 0})
	logic.add_component(&w.sprite, player, Sprite{uv = {0.7410926, 0.45657569, 0.78384799, 0.53101736}})
}

world_frame :: proc(w: ^World) {
	// w.pasued = true

	// only tick the game state at the rate of sims_per_second
	// https://gafferongames.com/post/fix_your_timestep/
	if !w.pasued {
		/*====================================================================================================*/
		/*                                          Logic                                                     */
		/*====================================================================================================*/
		w.accumulator += sapp.frame_duration()

		for (w.accumulator >= w.sim_frame_length) {
			sys_velocity(w)
			w.accumulator -= w.sim_frame_length
		}
	}
}

world_cleanup :: proc(w: ^World) {
	fmt.println("WORLD cleanup")

	logic.destroy_storage(&w.position)
	logic.destroy_storage(&w.velocity)
	logic.destroy_storage(&w.sprite)
}


change_scene :: proc(w: ^World, filename: string) {
	fmt.printfln("changing scene %s", filename)
}


// COMPNENTS ???
Position :: [2]int

// Utils
create_entity :: proc(w: ^World) -> int {
	id := w.next_entity_id
	w.next_entity_id += 1

	return id
}

entity_delete :: proc(w: ^World, entity_id: int) {
	logic.delete_component(&w.position, entity_id)
	logic.delete_component(&w.velocity, entity_id)
}
