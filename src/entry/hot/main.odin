/*
Development game exe. Loads build/hot_reload/game.dll and reloads it whenever it
changes.

Uses sokol/app to open the window. The init, frame, event and cleanup callbacks
of the app run procedures inside the current game DLL.
*/

package main

import "core:dynlib"
import "core:fmt"
import "core:log"
import "core:mem"
import os "core:os/os2"
import "core:time"

import sapp "../../game/sokol/app"

DLL_FILE :: #config(DLL_FILE, "game_hot.dylib")

track: mem.Tracking_Allocator

Game_API :: struct {
	lib:               dynlib.Library,
	app_default_desc:  proc() -> sapp.Desc,
	init:              proc(),
	frame:             proc(),
	event:             proc(e: ^sapp.Event),
	cleanup:           proc(),
	memory:            proc() -> rawptr,
	memory_size:       proc() -> int,
	hot_reloaded:      proc(mem: rawptr),
	force_restart:     proc() -> bool,
	modification_time: time.Time,
}

old_game_api: Maybe(Game_API)  // Only keep one previous API for memory preservation
game_api: Game_API

main :: proc() {
	if exe_dir, exe_dir_err := os.get_executable_directory(context.temp_allocator);
	   exe_dir_err == nil {
		os.set_working_directory(exe_dir)
	}

	context.logger = log.create_console_logger()
	mem.tracking_allocator_init(&track, context.allocator) // set the current context
	context.allocator = mem.tracking_allocator(&track)

	game_api_err: os.Error
	game_api, game_api_err = load_game_api()

	if game_api_err != nil {
		fmt.println("Failed to load Game API", game_api_err)
		return
	}

	old_game_api = nil
	app_desc := game_api.app_default_desc()
	app_desc.init_cb = proc "c" () {
		context = context
		context.allocator = mem.tracking_allocator(&track)
		fmt.println("HOT INIT")

		game_api.init()
	}

	app_desc.frame_cb = proc "c" () {
		context = context
		context.allocator = mem.tracking_allocator(&track)

		game_api.frame()
		check_reload_dll()
	}

	app_desc.cleanup_cb = proc "c" () {
		context = context
		context.allocator = mem.tracking_allocator(&track)

		game_api.cleanup()
		unload_all(true)
		tracking_allocator_result()
		mem.tracking_allocator_destroy(&track)
	}

	app_desc.event_cb = proc "c" (e: ^sapp.Event) {
		context = context
		context.allocator = mem.tracking_allocator(&track)

		game_api.event(e)
	}

	sapp.run(app_desc)
}

// Make game use good GPU on laptops.

@(export)
NvOptimusEnablement: u32 = 1

@(export)
AmdPowerXpressRequestHighPerformance: i32 = 1


@(private = "file")
check_reload_dll :: proc() {
	game_dll_mod, game_dll_mod_err := os.last_write_time_by_name(DLL_FILE)

	reload := game_dll_mod_err == os.ERROR_NONE && game_api.modification_time != game_dll_mod
	force_restart := game_api.force_restart()

	if reload || force_restart {
		new_game_api, new_game_api_ok := load_game_api()

		if new_game_api_ok == nil {
			force_restart = force_restart || game_api.memory_size() != new_game_api.memory_size()

			if !force_restart {
				// Keep previous API to preserve memory references (World, Render structs)
				// The old DLL is unloaded on next reload or on cleanup
				old_game_api = game_api

				game_memory := game_api.memory()
				game_api = new_game_api
				game_api.hot_reloaded(game_memory)
			} else {
				// This does a full reset. That's basically like opening and
				// closing the game, without having to restart the executable.
				//
				// You end up in here if the game requests a full reset OR
				// if the size of the game memory has changed. That would
				// probably lead to a crash anyways.

				game_api.cleanup()
				unload_all()
				tracking_allocator_result()
				mem.tracking_allocator_clear(&track)

				game_api = new_game_api
				game_api.init()
			}
		}
	}
}

@(private = "file")
unload_all :: proc(final := false) {
	if old_game_api != nil {
		unload_game_api(&old_game_api.(Game_API))
		old_game_api = nil
	}

	unload_game_api(&game_api)
}

@(private = "file")
get_game_dll_tmp_path :: proc(dll_path: string) -> (dll_tmp_path: string, err: os.Error) {
	tmp_file := fmt.tprintf(
		"{0}_{2}.{1}",
		os.split_filename(dll_path),
		time.to_unix_nanoseconds(time.now()),
	)

	tmp_dir := os.temp_dir(context.temp_allocator) or_return
	dll_tmp_path = os.join_path([]string{tmp_dir, tmp_file}, context.temp_allocator) or_return

	return dll_tmp_path, nil
}

@(private = "file")
load_game_api :: proc() -> (api: Game_API, err: os.Error) {
	dll_tmp_path := get_game_dll_tmp_path(DLL_FILE) or_return

	fmt.printfln("LOADING API: %s", dll_tmp_path)

	mod_time := os.last_write_time_by_name(DLL_FILE) or_return

	// We copy the DLL because using it directly would lock it, which would prevent
	// the compiler from writing to it.
	os.copy_file(dll_tmp_path, DLL_FILE) or_return


	// This proc matches the names of the fields in Game_API to symbols in the
	// game DLL. It actually looks for symbols starting with `game_`, which is
	// why the argument `"game_"` is there.
	_, ok := dynlib.initialize_symbols(&api, dll_tmp_path, "game_", "lib")
	if !ok {
		fmt.printfln("Failed initializing symbols: {0}", dynlib.last_error())
	}

	api.modification_time = mod_time


	return
}

@(private = "file")
unload_game_api :: proc(api: ^Game_API) {
	if api.lib != nil {
		if !dynlib.unload_library(api.lib) {
			fmt.printfln("Failed unloading lib: {0}", dynlib.last_error())
		}
	}
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
}
