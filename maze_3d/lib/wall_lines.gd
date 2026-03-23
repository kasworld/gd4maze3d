class_name WallLines

var maze :Maze
var map_scale :float = 20
var WallThick :float = 2
var walls : Array[PackedByteArray] # as bool array
var walllines :PackedVector2Array = [] # for _draw

func _to_string() -> String:
	return "WallLines %s" % maze

func init_walls() -> void:
	walls = []
	walls.resize(maze.height*2+1)
	for cl in walls:
		cl.resize(maze.width*2+1)

func set_maze(mz :Maze) -> void:
	maze = mz

func get_width() -> float:
	return maze.width * map_scale
func get_height() -> float:
	return maze.height * map_scale

func update_size(rt :Rect2) -> void:
	map_scale = min( rt.size.x / maze.width , rt.size.y / maze.height )
	WallThick = max(1, map_scale*0.1)

func posi_to_mappos(pos :Vector2i) -> Vector2:
	return pos * map_scale + Vector2(WallThick,WallThick)

# cell wall[y*2+1][x*2+1]
# wall wall[y*2][x*2]
func calc_wall_pos(x :int, y:int, dir :Maze.Dir) -> Vector2i:
	return Vector2i(x*2+1,y*2+1) + Maze.DirToVt2[dir]

# make wallline by maze
func make_all_walllines() -> void:
	walllines = []
	for y in maze.height:
		for x in maze.width:
			if not maze.is_open_flag_at(x, y, Maze.Flag.North):
				add_wall_at_to_walllines(x, y, Maze.Dir.North)
			if not maze.is_open_flag_at(x, y, Maze.Flag.West):
				add_wall_at_to_walllines(x, y, Maze.Dir.West)

	for x in maze.width:
		if not maze.is_open_flag_at(x, maze.height -1, Maze.Flag.South):
			add_wall_at_to_walllines(x, maze.height -1, Maze.Dir.South)

	for y in maze.height:
		if not maze.is_open_flag_at(maze.width -1, y, Maze.Flag.East):
			add_wall_at_to_walllines(maze.width -1, y, Maze.Dir.East)

# make wallline by walls_known
func make_walllines_known() -> void:
	walllines = []
	for y in maze.height:
		for x in maze.width:
			if is_wall_at(x, y, Maze.Dir.North):
				add_wall_at_to_walllines(x, y, Maze.Dir.North)
			if is_wall_at(x, y, Maze.Dir.West):
				add_wall_at_to_walllines(x, y, Maze.Dir.West)

	for x in maze.width :
		if is_wall_at(x, maze.height-1, Maze.Dir.South):
			add_wall_at_to_walllines(x, maze.height-1, Maze.Dir.South)

	for y in maze.height:
		if is_wall_at(maze.width-1, y, Maze.Dir.East):
			add_wall_at_to_walllines(maze.width-1, y, Maze.Dir.East)


func add_wall_at_to_walllines(x :int, y :int, dir :Maze.Dir) -> void:
	match dir:
		Maze.Dir.North:
			walllines.append_array([Vector2(x,y)*map_scale,Vector2(x+1,y)*map_scale])
		Maze.Dir.West:
			walllines.append_array([Vector2(x,y)*map_scale,Vector2(x,y+1)*map_scale])
		Maze.Dir.South:
			walllines.append_array([Vector2(x,y+1)*map_scale,Vector2(x+1,y+1)*map_scale])
		Maze.Dir.East:
			walllines.append_array([Vector2(x+1,y)*map_scale,Vector2(x+1,y+1)*map_scale])

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

func update_walls_by_pos(x :int, y :int) -> void:
	var walldir := maze.get_wall_flag_at(x,y)
	for d in walldir:
		add_wall_at(x,y,Maze.FlagToDir[d])
