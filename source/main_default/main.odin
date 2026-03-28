package main_default

import game "../game"

main :: proc() {
	
	game.init()
	for game.should_run() {
		game.update_and_render()
	}
}
