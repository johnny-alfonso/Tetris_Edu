package game

import rl "vendor:raylib"
import fmt "core:fmt"
import "core:math"

Tetrimino :: enum {
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


Persistent_State :: struct {
	playfield_state : [playfield_height][playfield_width]Cell_State,
	active_tetrimino : Tetrimino,
	active_tetrimino_position : [2]int,
	active_tetrimino_rotation : Rotation,
	show_window_as_transparent : bool,
}

pst : ^Persistent_State

tetrimino_descriptions := [Tetrimino]Tetrimino_Description {
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
				{1,2}, {2,2}, {3,2}, {4,2}
			},
			.Right = Tetrimino_Shape{
				{2,1},
				{2,2},
				{2,3},
				{2,4},
			},
			.Left = Tetrimino_Shape{
				{0,2}, {1,2}, {2,2}, {3,2}
			},
			.Two = Tetrimino_Shape{
				{2,0},
				{2,1},
				{2,2},
				{2,3},
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
		color = rl.WHITE,
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

	if rl.IsKeyPressed(.O) do pst.active_tetrimino = .O
	if rl.IsKeyPressed(.I) do pst.active_tetrimino = .I
	if rl.IsKeyPressed(.S) do pst.active_tetrimino = .S
	if rl.IsKeyPressed(.Z) do pst.active_tetrimino = .Z
	if rl.IsKeyPressed(.L) do pst.active_tetrimino = .L
	if rl.IsKeyPressed(.J) do pst.active_tetrimino = .J
	if rl.IsKeyPressed(.T) do pst.active_tetrimino = .T

	if rl.IsKeyPressed(.Q) {
		new_rotation_i := int(pst.active_tetrimino_rotation)
		new_rotation_i -= 1
		new_rotation_i %%= len(Rotation)
		pst.active_tetrimino_rotation = Rotation(new_rotation_i)
	} else if rl.IsKeyPressed(.W) {
		new_rotation_i := int(pst.active_tetrimino_rotation)
		new_rotation_i += 1
		new_rotation_i %%= len(Rotation)
		pst.active_tetrimino_rotation = Rotation(new_rotation_i)
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

		for row in 0..<playfield_height {
			for col in 0..<playfield_width {
				if rl.IsMouseButtonDown(.LEFT) {
					if row == mouse_playfield_pos.y && col == mouse_playfield_pos.x {
						pst.playfield_state[row][col].active = true
						pst.playfield_state[row][col].color = rl.GRAY
					}
				}

				if rl.IsMouseButtonDown(.RIGHT) {
					if row == mouse_playfield_pos.y && col == mouse_playfield_pos.x {
						pst.playfield_state[row][col].active = false 
					}
				}
			}
		}

		mouse_playfield_pos_x_text := fmt.ctprintf("x = %d", mouse_playfield_pos.x)
		mouse_playfield_pos_y_text := fmt.ctprintf("y = %d", mouse_playfield_pos.y)

		rl.DrawText(mouse_playfield_pos_x_text, 500, 10, 24, rl.WHITE)
		rl.DrawText(mouse_playfield_pos_y_text, 500, 10+30, 24, rl.WHITE)

	}

	

	{ // draw blocks
		for row in 0..<playfield_height {
			for col in 0..<playfield_width {
				cell := pst.playfield_state[row][col] 
				if cell.active == true {
					block := rl.Rectangle {
						playfield_position.x + f32(col)*cell_size,
						playfield_position.y + f32(row)*cell_size,
						cell_size-1,
						cell_size-1,
					}

					rl.DrawRectangleRec(block, cell.color)

				}
			}
		}
	}

	{ // draw falling block / block to place

		if rl.IsKeyPressed(.UP) {
			pst.active_tetrimino_position.y -= 1
		}
		if rl.IsKeyPressed(.DOWN) {
			pst.active_tetrimino_position.y += 1
		}
		if rl.IsKeyPressed(.LEFT) {
			pst.active_tetrimino_position.x -= 1
		}
		if rl.IsKeyPressed(.RIGHT) {
			pst.active_tetrimino_position.x += 1
		}

		if rl.IsKeyPressed(.ENTER) {
			for block_pos_in_tetrimino_space in tetrimino_descriptions[pst.active_tetrimino].rotation_shapes[pst.active_tetrimino_rotation] {
				block_pos_in_playfield_space := pst.active_tetrimino_position + block_pos_in_tetrimino_space
				pst.playfield_state[block_pos_in_playfield_space.y][block_pos_in_playfield_space.x].active = true
				pst.playfield_state[block_pos_in_playfield_space.y][block_pos_in_playfield_space.x].color = tetrimino_descriptions[pst.active_tetrimino].color 
			}
			
			pst.active_tetrimino_position = {}
		}

		for block_pos_in_tetrimino_space in tetrimino_descriptions[pst.active_tetrimino].rotation_shapes[pst.active_tetrimino_rotation] {
			block_pos_in_playfield_space := pst.active_tetrimino_position + block_pos_in_tetrimino_space

			if block_pos_in_playfield_space.x < 0 {
				pst.active_tetrimino_position.x += 1
			}

			if block_pos_in_playfield_space.x > playfield_width - 1 {
				pst.active_tetrimino_position.x -= 1
			}

			if block_pos_in_playfield_space.y < 0 {
				pst.active_tetrimino_position.y += 1
			}

			if block_pos_in_playfield_space.y > playfield_height - 1 {
				pst.active_tetrimino_position.y -= 1
			}
		}


		for block_pos_in_tetrimino_space in tetrimino_descriptions[pst.active_tetrimino].rotation_shapes[pst.active_tetrimino_rotation] {
			
			block_pos_in_playfield_space := pst.active_tetrimino_position + block_pos_in_tetrimino_space

			block_to_draw := rl.Rectangle {
				playfield_position.x + f32(block_pos_in_playfield_space.x)*cell_size,
				playfield_position.y + f32(block_pos_in_playfield_space.y)*cell_size,
				cell_size-1,
				cell_size-1,				
			}
			rl.DrawRectangleRec(block_to_draw, tetrimino_descriptions[pst.active_tetrimino].color)
		}

	}

	{
		rl.DrawCircleV(playfield_position, 5, rl.RED)
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
	pst.active_tetrimino = Tetrimino.S
	pst.active_tetrimino_position = [2]int{0,0}
	pst.active_tetrimino_rotation = Rotation.Zero
	pst.show_window_as_transparent = false

	rl.InitWindow(screen_width, screen_height, "Tetris Edu")

}

@(export)
should_run :: proc() -> bool {
	run := !rl.WindowShouldClose()
	return run
}


