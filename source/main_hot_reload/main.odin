package main_hot_reload

import "core:dynlib"
import "core:os"
import "core:fmt"
import "core:time"

Game_Api :: struct {
	__handle : rawptr,
	version : int,
	modification_time : time.Time,
	init : proc(),
	should_run : proc() -> bool,
	update_and_render : proc(),
	get_persistent_state : proc() -> rawptr,
	game_hot_reload : proc(new_persistent_state : rawptr),
}

DLL_DIR :: "build/hot_reload/"
DLL_NAME :: "game"
DLL_EXT :: ".dll"

src_dll_filename := DLL_DIR + DLL_NAME + DLL_EXT

reload_library :: proc(game_api : ^Game_Api) -> (ok : bool) {
	new_api_version := game_api.version + 1


	last_modification_time, modification_time_error := os.last_write_time_by_name(src_dll_filename)

	ok = false

	if modification_time_error == os.ERROR_NONE {
		dst_dll_filename := fmt.tprintf(DLL_DIR + DLL_NAME + "_{0}.dll", new_api_version)

		copy_err := os.copy_file(dst_dll_filename, src_dll_filename)
		
		if copy_err == nil {
			nsymbols, load_ok := dynlib.initialize_symbols(game_api, dst_dll_filename)
			if load_ok {
				game_api.version = new_api_version
				game_api.modification_time = last_modification_time
				ok = true
			}
			else {
				dynlib_error := dynlib.last_error()
				fmt.printfln("Failed to load %v. Err: %v", dst_dll_filename, dynlib_error)					
			}
		} 
		else {
			fmt.printfln("Failed to copy into %v. Error: %v", dst_dll_filename, copy_err)
		}
	} 
	else {
		fmt.printfln("Failed to get last write time of %v", src_dll_filename)
	}

	return 

}

main :: proc() {


	raylib_dll_name :: "build/hot_reload/raylib.dll"
	_, raylib_did_load := dynlib.load_library(raylib_dll_name)
	if !raylib_did_load {
		dynlib_error := dynlib.last_error()
		fmt.printfln("Failed to load %v. Err: %v", raylib_dll_name, dynlib_error)
	}

	game_api : Game_Api


	reload_library(&game_api)

	game_api.init()
	
	for game_api.should_run() {
		game_api.update_and_render()

		modification_time, modification_time_error := os.last_write_time_by_name(src_dll_filename)
		dll_file_changed := modification_time != game_api.modification_time
		should_reload := dll_file_changed 
		if should_reload {
			captured_persistent_state := game_api.get_persistent_state()
			load_ok := reload_library(&game_api)
			if load_ok {
				game_api.game_hot_reload(captured_persistent_state)
			}
		}
	}
}
