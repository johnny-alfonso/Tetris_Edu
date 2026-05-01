package game

import "vendor:portmidi"
import rl "vendor:raylib"
import fmt "core:fmt"
import "core:math"
import "core:math/rand"


Tetrimino_Queue :: struct {
	data : [2*len(Tetrimino_Type)]Tetrimino_Type,
	head : int,
}


Persistent_State :: struct {
	playfield_state : Playfield,
	active_tetrimino : Tetrimino,
	tetrimino_queue : Tetrimino_Queue,
	show_window_as_transparent : bool,
}

pst : ^Persistent_State



screen_height : i32 = 720
screen_width : i32 = 1280


tetrimino_to_playfield_space :: proc(playfield_position : [2]int, tshape : Tetrimino_Shape) -> Tetrimino_Shape {
	playfield_tetrimion_shape := Tetrimino_Shape{}
	for block, i in tshape {
		playfield_tetrimion_shape[i] = block + playfield_position
	}
	return playfield_tetrimion_shape 
}


tetrimino_block_in_playfield_space :: proc(playfield_position : [2]int, tblock : [2]int ) -> [2]int {
	block_in_playfield_space := playfield_position + tblock
	return block_in_playfield_space
}


playfield_block_to_screen_space_rectangle :: proc(playfield_pos : [2]f32, block_pos : [2]int, cell_size : f32) -> rl.Rectangle {
	block_rect := rl.Rectangle {
		playfield_pos.x + ( f32(block_pos.x)*cell_size ),
		playfield_pos.y + ( f32(block_pos.y)*cell_size ),
		cell_size - 1,
		cell_size - 1,
	}
	return block_rect
}

playfield_position_to_screen_position :: proc(playfield_origin : [2]f32, position : [2]int, cell_size : f32) -> [2]f32 {
	pos := [2]f32 {
		playfield_origin.x + f32(position.x)*cell_size,
		playfield_origin.y + f32(position.y)*cell_size,
	}
	return pos
}



draw_block :: proc(playfield_position :[2]f32, block_pos:[2]int, cell_size : f32, color : rl.Color) {
	block := rl.Rectangle {
		playfield_position.x + f32(block_pos.x)*cell_size,
		playfield_position.y + f32(block_pos.y)*cell_size,
		cell_size-1,
		cell_size-1,
	}

	rl.DrawRectangleRec(block, color)
}


place_tetrimino_in_playfield_and_reset_active_tetrimino :: proc(
	playfield_state : ^[playfield_height][playfield_width]Cell_State, 
	active_tetrimino : ^Tetrimino,
) {
	tshape_pspace := tetrimino_shape_in_playfield_space(active_tetrimino^)
	for block_pspace in tshape_pspace {
		tcolor := tetrimino_get_color(active_tetrimino^)
		playfield_place_block(
			playfield_state,
			block_pspace.x, block_pspace.y,
			tcolor
		)
	}
	
	{ // TODO: reset logic with the randomized NEXT tetrimino queue
		active_tetrimino.pos = {}
		active_tetrimino.type = pst.tetrimino_queue.data[pst.tetrimino_queue.head]

		pst.tetrimino_queue.head += 1
		pst.tetrimino_queue.head %= len(pst.tetrimino_queue.data)

		reached_first_half := pst.tetrimino_queue.head == 0
		reached_second_half := pst.tetrimino_queue.head == len(Tetrimino_Type)
		if reached_first_half {
			rand.shuffle(pst.tetrimino_queue.data[len(Tetrimino_Type):])
		}
		else if reached_second_half {
			rand.shuffle(pst.tetrimino_queue.data[0:len(Tetrimino_Type)])
		}
	}	
}


intersecting_with_block_or_wall :: proc(tetrimino : Tetrimino) -> bool {
	tshape_pspace := tetrimino_shape_in_playfield_space(tetrimino)
	intersected := false
	for block_pspace in tshape_pspace {
		intersected |= playfield_is_block_or_wall_here(pst.playfield_state, block_pspace)
	}
	return intersected
}

NUM_WALL_KICK_TEST_OFFSETS :: 5

Wall_Kick_Data :: struct {
	old, new : Rotation,
	test_offsets : [NUM_WALL_KICK_TEST_OFFSETS][2]int,
}

super_rotation_system :: proc(
	playfield_state : ^[playfield_height][playfield_width]Cell_State,
	active_tetrimino : ^Tetrimino,
	new_rotation : Rotation 
) {
	old_rotation := active_tetrimino.rotation

	NUM_ROTATION_TRANSITIONS :: 8

	wall_kick_dataset := [NUM_ROTATION_TRANSITIONS]Wall_Kick_Data{}

	switch active_tetrimino.type {
		case .J, .L, .S, .T, .Z: {
			wall_kick_dataset = [NUM_ROTATION_TRANSITIONS]Wall_Kick_Data {
				{old = .Zero, new = .Right, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2},}
				},
				{old = .Right, new = .Zero, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{0, 0}, {1, 0}, {1,1}, { 0,-2}, {1,-2},}
				},
				{old = .Right, new = .Two, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {+1, 0}, {+1,1}, { 0,-2}, {+1,-2},}
				},
				{old = .Two, new = .Right, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {-1, 0}, {-1,-1}, { 0,2}, {-1,2},}
				},
				{old = .Two, new = .Left, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {+1, 0}, {+1,-1}, { 0,2}, {+1,2},}
				},
				{old = .Left, new = .Two, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {-1, 0}, {-1,1}, { 0,-2}, {-1,-2},}
				},
				{old = .Left, new = .Zero, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {-1, 0}, {-1, 1}, { 0,-2}, {-1,-2},}
				},
				{old = .Zero, new = .Left, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {+1, 0}, {+1,-1}, { 0,2}, {+1,2},}
				},
			}
		}
		case .I: {
			wall_kick_dataset = [NUM_ROTATION_TRANSITIONS]Wall_Kick_Data {
				{old = .Zero, new = .Right, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{0, 0}, {-2, 0}, {1, 0}, {-2, 1}, {1, -2},}
				},
				{old = .Right, new = .Zero, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {+2, 0}, {-1, 0}, {+2,-1}, {-1,2},}
				},
				{old = .Right, new = .Two, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {-1, 0}, {+2, 0}, {-1,-2}, {+2,1},}
				},
				{old = .Two, new = .Right, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{
					{ 0, 0}, {+1, 0}, {-2, 0}, {+1,2}, {-2,-1},}
				},
				{old = .Two, new = .Left, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {+2, 0}, {-1, 0}, {+2,-1}, {-1,2},}
				},
				{old = .Left, new = .Two, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {-2, 0}, {+1, 0}, {-2,1}, {+1,-2},}
				},
				{old = .Left, new = .Zero, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					 { 0, 0}, {+1, 0}, {-2, 0}, {+1,2}, {-2,-1},}
				},
				{old = .Zero, new = .Left, test_offsets = [NUM_WALL_KICK_TEST_OFFSETS][2]int{ 
					{ 0, 0}, {-1, 0}, {+2, 0}, {-1,-2}, {+2,1},}
				},
			}
		}
		case .O: {}
	}

	wall_kick_data := Wall_Kick_Data{}

	for wkd in wall_kick_dataset {
		is_matching_rotation_transition := old_rotation == wkd.old &&
			new_rotation == wkd.new
		if is_matching_rotation_transition {
			wall_kick_data = wkd
		} 
	}

	
	for offset in wall_kick_data.test_offsets {
		test_tetrimino := active_tetrimino^
		test_tetrimino.pos += offset
		test_tetrimino.rotation = new_rotation
		tshape_pspace := tetrimino_shape_in_playfield_space(test_tetrimino)
		is_valid_position := !intersecting_with_block_or_wall(test_tetrimino)
		if is_valid_position {
			active_tetrimino.pos = test_tetrimino.pos
			active_tetrimino.rotation = test_tetrimino.rotation
			break
		}
		
	}
}



@(export)
update_and_render :: proc() {
	if rl.IsKeyPressed(.F1) {
		if pst.show_window_as_transparent {
			pst.show_window_as_transparent = false
			rl.SetWindowOpacity(1.0)
			rl.ClearWindowState({.WINDOW_TOPMOST})
		} else {
			pst.show_window_as_transparent = true
			rl.SetWindowOpacity(0.5)
			rl.SetWindowState({.WINDOW_TOPMOST})
		}
	}

	rl.ClearBackground(rl.BLACK)
	rl.BeginDrawing()

	if rl.IsKeyPressed(.O) do pst.active_tetrimino.type = .O
	if rl.IsKeyPressed(.I) do pst.active_tetrimino.type = .I
	if rl.IsKeyPressed(.S) do pst.active_tetrimino.type = .S
	if rl.IsKeyPressed(.Z) do pst.active_tetrimino.type = .Z
	if rl.IsKeyPressed(.L) do pst.active_tetrimino.type = .L
	if rl.IsKeyPressed(.J) do pst.active_tetrimino.type = .J
	if rl.IsKeyPressed(.T) do pst.active_tetrimino.type = .T

	old_active_tetrimino_rotation := pst.active_tetrimino.rotation
	new_active_tetrimino_rotation := old_active_tetrimino_rotation

	if rl.IsKeyPressed(.Q) {
		new_rotation_i := int(pst.active_tetrimino.rotation)
		new_rotation_i -= 1
		new_rotation_i %%= len(Rotation)
		new_active_tetrimino_rotation = Rotation(new_rotation_i)
	} else if rl.IsKeyPressed(.W) {
		new_rotation_i := int(pst.active_tetrimino.rotation)
		new_rotation_i += 1
		new_rotation_i %%= len(Rotation)
		new_active_tetrimino_rotation = Rotation(new_rotation_i)
	}

	did_want_to_rotate := old_active_tetrimino_rotation != new_active_tetrimino_rotation
	if did_want_to_rotate {
		super_rotation_system(
			&pst.playfield_state, 
			&pst.active_tetrimino,
			new_active_tetrimino_rotation,
		)	
	}


	cell_size : f32 = 24
	

	playfield_width_in_pixels := f32(playfield_width)*cell_size
	playfield_height_in_pixels := f32(playfield_height)*cell_size

	playfield_position := [2]f32{
		f32(screen_width)/2 - playfield_width_in_pixels/2,
		f32(screen_height)/2 - playfield_height_in_pixels/2,
	}
	
	playfield_right_side_x : f32 = playfield_position.x + cell_size*f32(playfield_width)

	playfield_bottom_y : f32 = playfield_position.y + cell_size*f32(playfield_height)

	for row in 0..=playfield_height {

		rl.DrawLineV(
			[2]f32{
				playfield_position.x, 
				playfield_position.y + cell_size*f32(row)
			}, 
			[2]f32{
				playfield_right_side_x,
				playfield_position.y + cell_size*f32(row)
			},
			rl.WHITE
		)
		
		
	}

	for col in 0..=playfield_width {
		rl.DrawLineV(
			[2]f32{
				playfield_position.x + f32(col)*cell_size,
				playfield_position.y
			}, 
			[2]f32{
				playfield_position.x + f32(col)*cell_size, 
				playfield_bottom_y
			},
			rl.WHITE
		)
	}

	{ // debug set block states
		mouse_pos := rl.GetMousePosition()
		mouse_pos_rel_playfield := mouse_pos - playfield_position
		mouse_playfield_pos := [2]int {
			int(mouse_pos_rel_playfield.x) / int(cell_size), // col
			int(mouse_pos_rel_playfield.y) / int(cell_size), // row
		} // 2d index into 2d array

		if rl.IsMouseButtonDown(.LEFT) {
			playfield_place_block(
				&pst.playfield_state, 
				mouse_playfield_pos.x, mouse_playfield_pos.y, rl.GRAY
			)
		}

		if rl.IsMouseButtonDown(.RIGHT) {
			playfield_remove_block(
				&pst.playfield_state, 
				mouse_playfield_pos.x, mouse_playfield_pos.y
			)
		}

		mouse_playfield_pos_x_text := fmt.ctprintf("x = %d", mouse_playfield_pos.x)
		mouse_playfield_pos_y_text := fmt.ctprintf("y = %d", mouse_playfield_pos.y)

		rl.DrawText(mouse_playfield_pos_x_text, 500, 10, 24, rl.WHITE)
		rl.DrawText(mouse_playfield_pos_y_text, 500, 10+30, 24, rl.WHITE)

	}

	should_force_shuffle := rl.IsKeyPressed(.R)
	if should_force_shuffle {
		rand.shuffle(pst.tetrimino_queue.data[0:len(Tetrimino_Type)])
		rand.shuffle(pst.tetrimino_queue.data[len(Tetrimino_Type):])
	}

	{ // tetrimino queue
		queue_start_pos := [2]f32 { playfield_position.x + f32(playfield_width)*cell_size + 20, playfield_position.y }
		block_size : f32 = 16
		queue_entry_height := block_size*4
		cursor := queue_start_pos
		visible_tetriminos_in_queue := 5
		
		for visible_tetrimino_index in 0..< visible_tetriminos_in_queue {
			queue_index := (pst.tetrimino_queue.head + visible_tetrimino_index) % len(pst.tetrimino_queue.data)
			ttype := pst.tetrimino_queue.data[queue_index]
			tetrimino_draw_in_world(cursor, ttype, .Zero, block_size)
			cursor.y += queue_entry_height
		}

		debug_cursor := [2]f32{0, 680}
		debug_block_size : f32 = 10
		for queue_index in 0..<len(pst.tetrimino_queue.data) {
			ttype := pst.tetrimino_queue.data[queue_index]
			tetrimino_draw_in_world(debug_cursor, ttype, .Zero, block_size)
			if queue_index == pst.tetrimino_queue.head {
				rl.DrawRectangleRec({debug_cursor.x, debug_cursor.y, 6, 6}, rl.WHITE)
			}
			debug_cursor.x += 10*9
		}
	}

	

	{ // draw blocks in playfield
		for row in 0..<playfield_height {
			for col in 0..<playfield_width {
				cell := pst.playfield_state[row][col] 
				if cell.active == true {
					block_pos := [2]int{col, row}
					draw_block(playfield_position, block_pos, cell_size, cell.color)
				}
			}
		}
	}

	{ // draw falling block / block to place

		next_active_tetrimino_pos := pst.active_tetrimino.pos

		if rl.IsKeyPressed(.UP) {
			next_active_tetrimino_pos.y -= 1
		}
		if rl.IsKeyPressed(.DOWN) {
			next_active_tetrimino_pos.y += 1
		}
		if rl.IsKeyPressed(.LEFT) {
			next_active_tetrimino_pos.x -= 1
		}
		if rl.IsKeyPressed(.RIGHT) {
			next_active_tetrimino_pos.x += 1
		}

		moved_left_or_right := pst.active_tetrimino.pos.x != next_active_tetrimino_pos.x
		if moved_left_or_right {
			next_tetrimino := pst.active_tetrimino
			next_tetrimino.pos = next_active_tetrimino_pos
			did_collide := intersecting_with_block_or_wall(next_tetrimino)
			if did_collide {
				next_active_tetrimino_pos = pst.active_tetrimino.pos
			}
		}

		pst.active_tetrimino.pos = next_active_tetrimino_pos

		place_tetrimino_in_playfield_and_spawn_new_active_tetrimino := rl.IsKeyPressed(.ENTER)
		if place_tetrimino_in_playfield_and_spawn_new_active_tetrimino {
			place_tetrimino_in_playfield_and_reset_active_tetrimino(
				&pst.playfield_state,
				&pst.active_tetrimino,	
			)
		}

		{ 
			// TODO: this is temporary - remove this
			// make sure tetrimino stays inside playfield
			for block_pos_in_tetrimino_space in tetrimino_descriptions[pst.active_tetrimino.type].rotation_shapes[pst.active_tetrimino.rotation] {
				block_pos_in_playfield_space := pst.active_tetrimino.pos + block_pos_in_tetrimino_space

				if block_pos_in_playfield_space.y < 0 {
					pst.active_tetrimino.pos.y += 1
				}

				if block_pos_in_playfield_space.y > playfield_height - 1 {
					pst.active_tetrimino.pos.y -= 1
				}
			}	
		}
			

		tshape_pspace := tetrimino_to_playfield_space(
			pst.active_tetrimino.pos, 
			tetrimino_descriptions[pst.active_tetrimino.type].rotation_shapes[pst.active_tetrimino.rotation]
		)

		for block_pos_in_playfield_space in tshape_pspace {
			block := playfield_block_to_screen_space_rectangle(playfield_position, block_pos_in_playfield_space, cell_size)
			rl.DrawRectangleRec(block, tetrimino_descriptions[pst.active_tetrimino.type].color)
		}
	}

	{ // ghost

		closest_free_row : int = 20
		closest_distance : int = 20
		closest_intersecting_block_y : int = 0
		for tetrimino_block in tetrimino_descriptions[pst.active_tetrimino.type].rotation_shapes[pst.active_tetrimino.rotation] {
			playfield_block := tetrimino_block_in_playfield_space(pst.active_tetrimino.pos, tetrimino_block)

			for y_test := playfield_block.y; y_test <= 20; y_test += 1 {
				block_test := [2]int{ playfield_block.x, y_test}
				intersects := playfield_is_block_or_wall_here(pst.playfield_state, block_test)
				if intersects {
					last_free_row := y_test - 1
					distance := last_free_row - playfield_block.y
					is_closer := distance <= closest_distance
					if is_closer {
						closest_free_row = last_free_row
						closest_distance = distance
						closest_intersecting_block_y = tetrimino_block.y
					}
				}
			}

		}
		
		{
			ghost_tetrimino_pos := [2]int {
				pst.active_tetrimino.pos.x,
				closest_free_row - closest_intersecting_block_y,
			}

			ghost_tetrimino_pos_in_screen_space := playfield_position_to_screen_position(
				playfield_position,
				ghost_tetrimino_pos,
				cell_size,
			)

			rl.DrawCircleV(ghost_tetrimino_pos_in_screen_space, 4, rl.WHITE)
			ghost_in_playfield_space := tetrimino_to_playfield_space(
				ghost_tetrimino_pos,
				tetrimino_descriptions[pst.active_tetrimino.type].rotation_shapes[pst.active_tetrimino.rotation],
			) 

			for block_pos_in_playfield_space in ghost_in_playfield_space {
				block := playfield_block_to_screen_space_rectangle(playfield_position, block_pos_in_playfield_space, cell_size)
				rl.DrawRectangleLinesEx(
					block,
					4,
					tetrimino_descriptions[pst.active_tetrimino.type].color,
				)
			}

			hard_drop := rl.IsKeyPressed(.SPACE)
			if hard_drop {
				pst.active_tetrimino.pos = ghost_tetrimino_pos 
				place_tetrimino_in_playfield_and_reset_active_tetrimino(
					&pst.playfield_state,
					&pst.active_tetrimino,
				)
				
			}
		}
	}

	{ // row clearing
		rows_cleared : [dynamic; 4]int

		for y in 0..<playfield_height {
			num_minos_in_row := 0
			for x in 0..<playfield_width {
				if playfield_is_block_or_wall_here(pst.playfield_state, [2]int{x, y}) {
					num_minos_in_row += 1
				}
			}

			is_row_filled := num_minos_in_row == playfield_width
			if is_row_filled {
				append(&rows_cleared, y)
			} 
		}

		// clearing
		for y in rows_cleared {
			for x in 0..<playfield_width {
				playfield_remove_block(&pst.playfield_state, x, y)
			}
		}

		// moving minos downward
		for row_cleared in rows_cleared {
			for y := row_cleared; y >= 0; y -= 1 {
				for x in 0..<playfield_width {
					curr_pos := [2]int{x, y}
					above_pos := [2]int{x, y - 1}
					above_cell := playfield_get_cell_state(&pst.playfield_state, above_pos.x, above_pos.y)
					playfield_set_cell_state(&pst.playfield_state, curr_pos.x, curr_pos.y, above_cell)
				}
			} 
		}


	}

	{
		rl.DrawCircleV(playfield_position, 5, rl.RED)
		rotation_text := fmt.ctprintf("%v", pst.active_tetrimino.rotation)
		rl.DrawText(rotation_text, 10,10, 24,rl.WHITE)
	}

	rl.EndDrawing()

	free_all(context.temp_allocator)
}

@(export)
get_persistent_state :: proc() -> rawptr {
	ptr := (rawptr)(pst)
	return ptr
}

@(export)
game_hot_reload :: proc(new_persistent_state : rawptr) {
	pst = (^Persistent_State)(new_persistent_state)
}


@(export)
init :: proc() {
	pst = new(Persistent_State)

	pst.playfield_state = [playfield_height][playfield_width]Cell_State {}
	pst.active_tetrimino.type = Tetrimino_Type.S
	pst.active_tetrimino.pos = [2]int{0,0}
	pst.active_tetrimino.rotation = Rotation.Zero
	pst.show_window_as_transparent = false

	rl.InitWindow(screen_width, screen_height, "Tetris Edu")

	for queue_index in 0..<len(pst.tetrimino_queue.data) {
		type := Tetrimino_Type(queue_index%len(Tetrimino_Type))
		pst.tetrimino_queue.data[queue_index] = type
	}
	rand.shuffle(pst.tetrimino_queue.data[0:len(Tetrimino_Type)])
	rand.shuffle(pst.tetrimino_queue.data[len(Tetrimino_Type):])


}

@(export)
should_run :: proc() -> bool {
	run := !rl.WindowShouldClose()
	return run
}


