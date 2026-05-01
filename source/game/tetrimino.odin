package game

import rl "vendor:raylib"

Tetrimino_Type :: enum {
	O, J, L, S, Z, I, T,
}

all_tetriminos := [?]Tetrimino_Type{.I, .L, .J, .O, .S, .Z, .T}


Blocks_In_Tetrimino :: 4


Rotation :: enum {
	Zero, Right, Two, Left
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
			.Two = Tetrimino_Shape{
				{0,0}, {1,0},
				{0,1}, {1,1},
			},
			.Left = Tetrimino_Shape{
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
			.Two = Tetrimino_Shape{
				{0,2}, {1,2}, {2,2}, {3,2}
			},
			.Left = Tetrimino_Shape{
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
		   .Two = Tetrimino_Shape{

		   		{0,1},{1,1},
		   			  {1,2},{2,2},
		   },
		   .Left = Tetrimino_Shape{
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
			.Two = Tetrimino_Shape{

					  {1,1},{2,1},
				{0,2},{1,2}
			},
			.Left = Tetrimino_Shape{
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
			.Two = Tetrimino_Shape{

				{0,1},{1,1},{2,1},
				            {2,2},
			},
			.Left = Tetrimino_Shape{
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
			.Two = Tetrimino_Shape{

				{0,1},{1,1},{2,1},
				{0,2},
			},
			.Left = Tetrimino_Shape{
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
			.Two = Tetrimino_Shape{
					{0,1},{1,1},{2,1},
					      {1,2},
			},
			.Left = Tetrimino_Shape{
					  {1,0},
				{0,1},{1,1},
				      {1,2}
			},
		},
		color = rl.PURPLE,
	},
}


tetrimino_get_color ::proc (tetrimino : Tetrimino) -> rl.Color {
	tcolor := tetrimino_descriptions[tetrimino.type].color
	return tcolor
}


tetrimino_get_shape :: proc(tetrimino : Tetrimino) -> Tetrimino_Shape {
	tshape_tspace := tetrimino_descriptions[tetrimino.type].rotation_shapes[tetrimino.rotation]
	return tshape_tspace
}


tetrimino_shape_in_playfield_space :: proc(tetrimino : Tetrimino) -> Tetrimino_Shape {
	tshape_pspace : Tetrimino_Shape
	tshape_tspace := tetrimino_get_shape(tetrimino)
	for block_tspace, i in tshape_tspace {
		tshape_pspace[i] = tetrimino.pos + block_tspace
	}
	return tshape_pspace
}


tetrimino_draw_in_world :: proc(pos : [2]f32, ttype : Tetrimino_Type, rotation : Rotation, block_size : f32) {

	tshape := tetrimino_descriptions[ttype].rotation_shapes[rotation]

	for block_pos in tshape {
		block_rect := rl.Rectangle {
			pos.x + ( f32(block_pos.x)*block_size ),
			pos.y + ( f32(block_pos.y)*block_size ),
			block_size - 1,
			block_size - 1,
		}
		rl.DrawRectangleRec(block_rect, tetrimino_descriptions[ttype].color)
	}
}
