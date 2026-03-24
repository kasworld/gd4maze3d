class_name WallLines

var maze2d_helper :Maze2DHelper
func set_helper(mh :Maze2DHelper) -> void:
	maze2d_helper = mh

var walls : Array[PackedByteArray] # as bool array
var walllines :PackedVector2Array = [] # for _draw

func _to_string() -> String:
	return "WallLines %s" % maze2d_helper.maze

func init_walls() -> void:
	walls = []
	walls.resize(maze2d_helper.maze.height*2+1)
	for cl in walls:
		cl.resize(maze2d_helper.maze.width*2+1)

# cell wall[y*2+1][x*2+1]
# wall wall[y*2][x*2]
func calc_wall_pos(x :int, y:int, dir :Maze.Dir) -> Vector2i:
	return Vector2i(x*2+1,y*2+1) + Maze.DirToVt2[dir]

# make wallline by maze
func make_all_walllines() -> void:
	walllines = []
	for y in maze2d_helper.maze.height:
		for x in maze2d_helper.maze.width:
			if not maze2d_helper.maze.is_open_flag_at(x, y, Maze.Flag.North):
				add_wall_at_to_walllines(x, y, Maze.Dir.North)
			if not maze2d_helper.maze.is_open_flag_at(x, y, Maze.Flag.West):
				add_wall_at_to_walllines(x, y, Maze.Dir.West)

	for x in maze2d_helper.maze.width:
		if not maze2d_helper.maze.is_open_flag_at(x, maze2d_helper.maze.height -1, Maze.Flag.South):
			add_wall_at_to_walllines(x, maze2d_helper.maze.height -1, Maze.Dir.South)

	for y in maze2d_helper.maze.height:
		if not maze2d_helper.maze.is_open_flag_at(maze2d_helper.maze.width -1, y, Maze.Flag.East):
			add_wall_at_to_walllines(maze2d_helper.maze.width -1, y, Maze.Dir.East)

# make wallline by walls_known
func make_walllines_known() -> void:
	walllines = []
	for y in maze2d_helper.maze.height:
		for x in maze2d_helper.maze.width:
			if is_wall_at(x, y, Maze.Dir.North):
				add_wall_at_to_walllines(x, y, Maze.Dir.North)
			if is_wall_at(x, y, Maze.Dir.West):
				add_wall_at_to_walllines(x, y, Maze.Dir.West)

	for x in maze2d_helper.maze.width :
		if is_wall_at(x, maze2d_helper.maze.height-1, Maze.Dir.South):
			add_wall_at_to_walllines(x, maze2d_helper.maze.height-1, Maze.Dir.South)

	for y in maze2d_helper.maze.height:
		if is_wall_at(maze2d_helper.maze.width-1, y, Maze.Dir.East):
			add_wall_at_to_walllines(maze2d_helper.maze.width-1, y, Maze.Dir.East)


func add_wall_at_to_walllines(x :int, y :int, dir :Maze.Dir) -> void:
	match dir:
		Maze.Dir.North:
			walllines.append_array([Vector2(x,y)*maze2d_helper.map_scale,Vector2(x+1,y)*maze2d_helper.map_scale])
		Maze.Dir.West:
			walllines.append_array([Vector2(x,y)*maze2d_helper.map_scale,Vector2(x,y+1)*maze2d_helper.map_scale])
		Maze.Dir.South:
			walllines.append_array([Vector2(x,y+1)*maze2d_helper.map_scale,Vector2(x+1,y+1)*maze2d_helper.map_scale])
		Maze.Dir.East:
			walllines.append_array([Vector2(x+1,y)*maze2d_helper.map_scale,Vector2(x+1,y+1)*maze2d_helper.map_scale])

func is_wall_at(x :int, y:int, dir :Maze.Dir) -> bool:
	var wpos := calc_wall_pos(x,y,dir)
	return walls[wpos.y][wpos.x] != 0

func set_wall_at(x :int, y:int, dir :Maze.Dir):
	var wpos := calc_wall_pos(x,y,dir)
	walls[wpos.y][wpos.x] = 1

func add_wall_at(x :int, y :int, dir :Maze.Dir) -> bool:
	if is_wall_at(x,y,dir):
		return false
	set_wall_at(x,y,dir)
	add_wall_at_to_walllines(x,y,dir)
	return true # need redraw

func update_walls_by_pos(x :int, y :int) -> bool:
	var walldir := maze2d_helper.maze.get_wall_flag_at(x,y)
	var need_redraw :bool = false
	for d in walldir:
		need_redraw = need_redraw or add_wall_at(x,y,Maze.FlagToDir[d])
	return need_redraw
