package game

import rl "vendor:raylib"

Playfield :: [playfield_height][playfield_width]Cell_State


Cell_State :: struct {
	active : bool,
	color : rl.Color,
}

playfield_width : int : 10
playfield_height : int : 20


playfield_is_block_or_wall_here :: proc(playfield_state : [playfield_height][playfield_width]Cell_State, pos : [2]int) -> bool {
	block_here := true
	within_playfield := pos.x >= 0 && pos.x < playfield_width && pos.y >= 0 && pos.y < playfield_height
	if within_playfield {
		block_here = playfield_state[pos.y][pos.x].active == true
	}
	return block_here
}



playfield_get_cell_state ::proc(playfield_state : ^Playfield, x, y : int) -> Cell_State{
	cell_state := Cell_State{}
	within_playfield := x >= 0 && x < playfield_width && y >= 0 && y < playfield_height
	if within_playfield {
		cell_state = playfield_state[y][x]
	} 
	return cell_state
}


playfield_set_cell_state :: proc(playfield_state : ^Playfield, x, y : int, cell_state : Cell_State) {
	within_playfield := x >= 0 && x < playfield_width && y >= 0 && y < playfield_height
	if within_playfield {
		playfield_state[y][x].active = cell_state.active
		playfield_state[y][x].color = cell_state.color
	} 
}


playfield_place_block :: proc(
	playfield_state : ^[playfield_height][playfield_width]Cell_State, 
	x, y : int,
	color : rl.Color,
) { 
	cell_state := Cell_State{true, color}
	playfield_set_cell_state(
		&pst.playfield_state,
		x, y,
		cell_state
	)
}


playfield_remove_block :: proc(
	playfield_state : ^[playfield_height][playfield_width]Cell_State, 
	x, y : int
) {
	cell_state := Cell_State{false, rl.GRAY}
	playfield_set_cell_state(
		&pst.playfield_state,
		x, y,
		cell_state
	)	
}

