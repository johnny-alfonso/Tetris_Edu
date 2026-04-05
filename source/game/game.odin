package game

import "vendor:portmidi"
import rl "vendor:raylib"
import fmt "core:fmt"
import "core:math"

Tetrimino_Type :: enum {
	O, J, L, S, Z, I, T,
}

Blocks_In_Tetrimino :: 4


Rotation :: enum {
	Zero, Right, Left, Two,
}


Tetrimino_Shape :: [Blocks_In_Tetrimino][2]int


Tetrimino_Description :: struct {
	rotation_shapes : [Rotation]Tetrimino_Shape,
	color : rl.Color,
}


Tetrimino :: struct {
	type : Tetrimino_Type,
	pos : [2]int,
	rotation : Rotation,
}

Persistent_State :: struct {
	playfield_state : [playfield_height][playfield_width]Cell_State,
	active_tetrimino : Tetrimino,
	show_window_as_transparent : bool,
}

pst : ^Persistent_State

tetrimino_descriptions := [Tetrimino_Type]Tetrimino_Description {
	.O = { 
		rotation_shapes = [Rotation] Tetrimino_Shape {
			.Zero = Tetrimino_Shape{
				{0,0}, {1,0},
				{0,1}, {1,1},
			},
			.Right = Tetrimino_Shape{
				{0,0}, {1,0},
				{0,1}, {1,1},
			},
			.Left = Tetrimino_Shape{
				{0,0}, {1,0},
				{0,1}, {1,1},
			},
			.Two = Tetrimino_Shape{
				{0,0}, {1,0},
				{0,1}, {1,1},
			},

		},
		color = rl.YELLOW,
	},
	.I = { 
		rotation_shapes = [Rotation] Tetrimino_Shape {
			.Zero = Tetrimino_Shape { 
				{0,1}, {1,1}, {2,1}, {3,1}
			},
			.Right = Tetrimino_Shape{
				{2,0},
				{2,1},
				{2,2},
				{2,3},
			},
			.Left = Tetrimino_Shape{
				{0,2}, {1,2}, {2,2}, {3,2}
			},
			.Two = Tetrimino_Shape{
				{1,0},
				{1,1},
				{1,2},
				{1,3},
			},
		},
		color = rl.SKYBLUE,
	},
	.Z = { 
		rotation_shapes = [Rotation] Tetrimino_Shape {
			.Zero = Tetrimino_Shape { 
				{0,0},{1,0},
			          {1,1},{2,1}
		   },
		   .Right = Tetrimino_Shape{
		   	              {2,0},
					{1,1},{2,1},
					{1,2},	   	            
		   },
		   .Left = Tetrimino_Shape{

		   		{0,1},{1,1},
		   			  {1,2},{2,2},
		   },
		   .Two = Tetrimino_Shape{
		   			  {1,0},
		   		{0,1},{1,1},
		   		{0,2},
		   },
		},
		color = rl.RED,
	},
	.S = { 
		rotation_shapes = [Rotation] Tetrimino_Shape {
			.Zero = Tetrimino_Shape {
			       {1,0},{2,0},
			 {0,1},{1,1},
			},
			.Right = Tetrimino_Shape{
				   {1,0},
				   {1,1},{2,1},
				         {2,2},
			},
			.Left = Tetrimino_Shape{

					  {1,1},{2,1},
				{0,2},{1,2}
			},
			.Two = Tetrimino_Shape{
				{0,0},
				{0,1},{1,1},
				      {1,2},
			},
		},
		color = rl.GREEN,
	},
	.J = { 
		rotation_shapes = [Rotation] Tetrimino_Shape {
			.Zero = Tetrimino_Shape {
				{0,0},
				{0,1},{1,1},{2,1},
			},
			.Right = Tetrimino_Shape{
					{1,0},{2,0},
					{1,1},
					{1,2},
			},
			.Left = Tetrimino_Shape{

				{0,1},{1,1},{2,1},
				            {2,2},
			},
			.Two = Tetrimino_Shape{
					  {1,0},
					  {1,1},
				{0,2},{1,2},	
			},
		},

		color = rl.BLUE,
	},
	.L = { 
		rotation_shapes = [Rotation] Tetrimino_Shape {
			.Zero = Tetrimino_Shape {
	            	        {2,0},
				{0,1},{1,1},{2,1}
			},
			.Right = Tetrimino_Shape{
				     {1,0},
				     {1,1},
				     {1,2},{2,2},
			},
			.Left = Tetrimino_Shape{

				{0,1},{1,1},{2,1},
				{0,2},
			},
			.Two = Tetrimino_Shape{
				{0,0},{1,0},
				      {1,1},
				      {1,2},
			},
		},

		color = rl.ORANGE,
	},
	.T = { 
		rotation_shapes = [Rotation] Tetrimino_Shape {
			.Zero = Tetrimino_Shape {
	        	   	  {1,0},
				{0,1},{1,1},{2,1},
			},
			.Right = Tetrimino_Shape{
				     {1,0},
				     {1,1},{2,1},
				     {1,2},
			},
			.Left = Tetrimino_Shape{
					{0,1},{1,1},{2,1},
					      {1,2},
			},
			.Two = Tetrimino_Shape{
					  {1,0},
				{0,1},{1,1},
				      {1,2}
			},
		},
		color = rl.PURPLE,
	},
}


Cell_State :: struct {
	active : bool,
	color : rl.Color,
}

playfield_width : int : 10
playfield_height : int : 20



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

is_block_here_or_is_wall :: proc(playfield_state : [playfield_height][playfield_width]Cell_State, pos : [2]int) -> bool {
	block_here := true
	within_playfield := pos.x >= 0 && pos.x < playfield_width && pos.y >= 0 && pos.y < playfield_height
	if within_playfield {
		block_here = playfield_state[pos.y][pos.x].active == true
	}
	return block_here
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


set_playfield_cell_state :: proc(
	playfield_state : ^[playfield_height][playfield_width]Cell_State, 
	x, y : int,
	active : bool, color : rl.Color,
) {
	within_playfield := x >= 0 && x < playfield_width && y >= 0 && y < playfield_height
	if within_playfield {
		playfield_state[y][x].active = active
		playfield_state[y][x].color = color
	} 
}


playfield_place_block :: proc(
	playfield_state : ^[playfield_height][playfield_width]Cell_State, 
	x, y : int,
	color : rl.Color,
) { 
	set_playfield_cell_state(
		&pst.playfield_state,
		x, y,
		true, color
	)
}

playfield_remove_block :: proc(
	playfield_state : ^[playfield_height][playfield_width]Cell_State, 
	x, y : int
) {
	set_playfield_cell_state(
		&pst.playfield_state,
		x, y,
		false, rl.GRAY
	)	
}

// place_tetrimino_in_playfield_and_reset_active_tetrimino(
// 				&pst.playfield_state,
// 				&pst.active_tetrimino,	
// 			)

get_tetrimino_color ::proc (tetrimino : Tetrimino) -> rl.Color {
	tcolor := tetrimino_descriptions[tetrimino.type].color
	return tcolor
}

place_tetrimino_in_playfield_and_reset_active_tetrimino :: proc(
	playfield_state : ^[playfield_height][playfield_width]Cell_State, 
	active_tetrimino : ^Tetrimino,
) {
	tshape_pspace := tetrimino_shape_in_playfield_space(active_tetrimino^)
	for block_pspace in tshape_pspace {
		tcolor := get_tetrimino_color(active_tetrimino^)
		playfield_place_block(
			playfield_state,
			block_pspace.x, block_pspace.y,
			tcolor
		)
	}
	
	{ // TODO: reset logic with the randomized NEXT tetrimino queue
		active_tetrimino.pos = {}
	}	
}


get_tetrimino_shape :: proc(tetrimino : Tetrimino) -> Tetrimino_Shape {
	tshape_tspace := tetrimino_descriptions[tetrimino.type].rotation_shapes[tetrimino.rotation]
	return tshape_tspace
}

tetrimino_shape_in_playfield_space :: proc(tetrimino : Tetrimino) -> Tetrimino_Shape {
	tshape_pspace : Tetrimino_Shape
	tshape_tspace := get_tetrimino_shape(tetrimino)
	for block_tspace, i in tshape_tspace {
		tshape_pspace[i] = tetrimino.pos + block_tspace
	}
	return tshape_pspace
}


intersecting_with_block_or_wall :: proc(tetrimino : Tetrimino) -> bool {
	tshape_pspace := tetrimino_shape_in_playfield_space(tetrimino)
	intersected := false
	for block_pspace in tshape_pspace {
		intersected |= is_block_here_or_is_wall(pst.playfield_state, block_pspace)
	}
	return intersected
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

	if rl.IsKeyPressed(.Q) {
		new_rotation_i := int(pst.active_tetrimino.rotation)
		new_rotation_i -= 1
		new_rotation_i %%= len(Rotation)
		pst.active_tetrimino.rotation = Rotation(new_rotation_i)
	} else if rl.IsKeyPressed(.W) {
		new_rotation_i := int(pst.active_tetrimino.rotation)
		new_rotation_i += 1
		new_rotation_i %%= len(Rotation)
		pst.active_tetrimino.rotation = Rotation(new_rotation_i)
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
		closest_intersecting_block_y : int = 0
		for tetrimino_block in tetrimino_descriptions[pst.active_tetrimino.type].rotation_shapes[pst.active_tetrimino.rotation] {
			playfield_block := tetrimino_block_in_playfield_space(pst.active_tetrimino.pos, tetrimino_block)

			for y_test := playfield_block.y; y_test <= 20; y_test += 1 {
				block_test := [2]int{ playfield_block.x, y_test}
				intersects := is_block_here_or_is_wall(pst.playfield_state, block_test)
				if intersects {
					is_closer := y_test - 1 <= closest_free_row
					if is_closer {
						closest_free_row = y_test - 1
						is_intersecting_block_closer := tetrimino_block.y > closest_intersecting_block_y
						if is_intersecting_block_closer {
							closest_intersecting_block_y = tetrimino_block.y
						}
					}
					break
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

}

@(export)
should_run :: proc() -> bool {
	run := !rl.WindowShouldClose()
	return run
}


