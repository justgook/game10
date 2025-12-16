#+build !freestanding
#+build !js
#+build !orca


package main

/*
For making a release exe that does not use hot reload.

Note how this just uses a `game` package to call the game code. No DLL is loaded.
*/

import game "../../game"
import sapp "../../game/sokol/app"
import "base:runtime"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
// import "core:os/os2"


USE_TRACKING_ALLOCATOR :: #config(USE_TRACKING_ALLOCATOR, true)

track: mem.Tracking_Allocator

_main :: proc() {

	// if exe_dir, exe_dir_err := os2.get_executable_directory(context.temp_allocator);
	//    exe_dir_err == nil {
	// 	os2.set_working_directory(exe_dir)
	// }

	mem.tracking_allocator_init(&track, context.allocator) // set the current context
	context.allocator = mem.tracking_allocator(&track)


	_ = create_logger
	// logger := create_logger(context.allocator)
	// context.logger = logger

	// when USE_TRACKING_ALLOCATOR {
	// 	default_allocator := context.allocator
	// 	tracking_allocator: mem.Tracking_Allocator
	// 	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	// 	context.allocator = mem.tracking_allocator(&tracking_allocator)
	// 	custom_context.allocator = context.allocator
	// }

	app_desc := game.game_app_default_desc()

	app_desc.init_cb = proc "c" () {
		context = context
		context.allocator = mem.tracking_allocator(&track)

		game.game_init()
	}

	app_desc.frame_cb = proc "c" () {
		context = context
		context.allocator = mem.tracking_allocator(&track)

		game.game_frame()
	}

	app_desc.cleanup_cb = proc "c" () {
		context = context
		context.allocator = mem.tracking_allocator(&track)
		game.game_cleanup()
		tracking_allocator_result()
	}

	app_desc.event_cb = proc "c" (e: ^sapp.Event) {
		context = context
		context.allocator = mem.tracking_allocator(&track)

		game.game_event(e)
	}

	sapp.run(app_desc)

}

@(private = "file")
create_logger :: proc(allocator: runtime.Allocator) -> runtime.Logger {
	mode: int = 0
	when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		mode = os.S_IRUSR | os.S_IWUSR | os.S_IRGRP | os.S_IROTH
	}

	logh, logh_err := os.open("log.txt", (os.O_CREATE | os.O_TRUNC | os.O_RDWR), mode)

	if logh_err == os.ERROR_NONE {
		os.stdout = logh
		os.stderr = logh
	}

	return(
		logh_err == os.ERROR_NONE ? log.create_file_logger(logh, allocator = allocator) : log.create_console_logger(allocator = allocator) \
	)
}

@(private = "file")
tracking_allocator_result :: proc() {
	if len(track.allocation_map) > 0 {
		fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
		for _, entry in track.allocation_map {
			fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
		}
	}
	if len(track.bad_free_array) > 0 {
		fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
		for entry in track.bad_free_array {
			fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
		}
	}
	mem.tracking_allocator_destroy(&track)
}


// make game use good GPU on laptops etc

@(export)
NvOptimusEnablement: u32 = 1

@(export)
AmdPowerXpressRequestHighPerformance: i32 = 1
