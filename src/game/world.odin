package game

import "camera"
import "core:fmt"
import "grid"
import "logic"
import "shape"
import sapp "sokol/app"


LOCALES_DIR :: #config(LOCALES_DIR, "../../build.nosync/locales")

Segment :: [4]int

World :: struct {
	pasued:           bool,
	next_entity_id:   int,
	sim_frame_length: f64,
	accumulator:      f64,
	// Camera system
	cam:              camera.Camera,
	player_entity:    int, // Track which entity is the player for camera following
	// Components
	position:         logic.Component_Storage(Position),
	velocity:         logic.Component_Storage(Velocity),
	sprite:           logic.Component_Storage(Sprite),
	// TODO: STUFF TO REFACTOR?
	grid:             grid.Grid,
	segments:         [dynamic]Segment,
	input:            logic.Component_Storage(Input),
	jump:             logic.Component_Storage(JumpState),
	collider:         logic.Component_Storage(shape.Capsule),
	on_hit:           logic.Component_Storage(proc(_: ^World, src, target: int)),
	on_hurt:          logic.Component_Storage(proc(_: ^World, src, target: int)),
	enemy_hurt:       logic.Component_Storage(shape.Capsule),
	enemy_hit:        logic.Component_Storage(shape.Circle),
	player_hurt:      logic.Component_Storage(shape.Capsule),
	player_hit:       logic.Component_Storage(shape.Circle),
	brain:            logic.Component_Storage(Brain),
}

world_init :: proc(w: ^World) {
	fmt.println("WORLD init")

	_ = entity_delete
	w.sim_frame_length = 1.0 / 60.0
	
	// Initialize camera
	w.cam = camera.camera_init({sapp.widthf() / 2, sapp.heightf() / 2}, 1.0)
	w.player_entity = -1

	// change_scene(w, "build.nosync/dd-000-000.wbin")
	create_mock_data(w)

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
			sys_brain(w)
			sys_movement(w)

			w.accumulator -= w.sim_frame_length
		}
	}

	// Update camera (runs every frame for smooth movement)
	sys_camera(w)
}

// Camera system - updates camera position based on tracked entity
sys_camera :: proc(w: ^World) {
	// Get target position if we're tracking an entity
	target_pos: Maybe([2]f32)
	if w.player_entity >= 0 {
		if pos, ok := logic.get_component(&w.position, w.player_entity); ok {
			target_pos = to_pixelf(pos^)
		}
	}

	// Update camera
	viewport := [2]f32{sapp.widthf(), sapp.heightf()}
	camera.camera_update(&w.cam, target_pos, f32(sapp.frame_duration()), viewport)
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
	logic.delete_component(&w.sprite, entity_id)
	logic.delete_component(&w.input, entity_id)
	logic.delete_component(&w.jump, entity_id)
	logic.delete_component(&w.collider, entity_id)
	logic.delete_component(&w.on_hit, entity_id)
	logic.delete_component(&w.on_hurt, entity_id)
	logic.delete_component(&w.enemy_hurt, entity_id)
	logic.delete_component(&w.enemy_hit, entity_id)
	logic.delete_component(&w.player_hurt, entity_id)
	logic.delete_component(&w.player_hit, entity_id)
	logic.delete_component(&w.brain, entity_id)
}

world_cleanup :: proc(w: ^World) {
	fmt.println("WORLD cleanup")

	logic.destroy_storage(&w.position)
	logic.destroy_storage(&w.velocity)
	logic.destroy_storage(&w.sprite)
	logic.destroy_storage(&w.input)
	logic.destroy_storage(&w.jump)
	logic.destroy_storage(&w.collider)
	logic.destroy_storage(&w.on_hit)
	logic.destroy_storage(&w.on_hurt)
	logic.destroy_storage(&w.enemy_hurt)
	logic.destroy_storage(&w.enemy_hit)
	logic.destroy_storage(&w.player_hurt)
	logic.destroy_storage(&w.player_hit)
	logic.destroy_storage(&w.brain)


	grid.destroy_grid(&w.grid)
	delete(w.segments)
}
