extends Node2D
class_name MazeMiniMap

var maze :Maze
var map_scale :float = 20
var WallThick :float = 2
var walllines_all :PackedVector2Array =[]

func _to_string() -> String:
	return "Minimap"

func set_maze(mz :Maze) -> void:
	maze = mz

func get_width() -> float:
	return maze.width * map_scale
func get_height() -> float:
	return maze.height * map_scale

func update_size(rt :Rect2) -> void:
	map_scale = min( rt.size.x / maze.width , rt.size.y / maze.height )
	WallThick = max(1, map_scale*0.1)
	make_walllines_all()
	position = rt.position

func posi_to_mappos(pos :Vector2i) -> Vector2:
	return pos * map_scale + Vector2(WallThick,WallThick)

# make wallline by maze
func make_walllines_all() -> void:
	walllines_all = []
	for y in maze.height:
		for x in maze.width:
			if not maze.is_open_flag_at(x, y, Maze.Flag.North):
				add_wall_at_to_walllines(x, y, Maze.Dir.North, walllines_all)
			if not maze.is_open_flag_at(x, y, Maze.Flag.West):
				add_wall_at_to_walllines(x, y, Maze.Dir.West, walllines_all)

	for x in maze.width:
		if not maze.is_open_flag_at(x, maze.height -1, Maze.Flag.South):
			add_wall_at_to_walllines(x, maze.height -1, Maze.Dir.South, walllines_all)

	for y in maze.height:
		if not maze.is_open_flag_at(maze.width -1, y, Maze.Flag.East):
			add_wall_at_to_walllines(maze.width -1, y, Maze.Dir.East, walllines_all)

# cell wall[y*2+1][x*2+1]
# wall wall[y*2][x*2]
func calc_wall_pos(x :int, y:int, dir :Maze.Dir) -> Vector2i:
	return Vector2i(x*2+1,y*2+1) + Maze.DirToVt2[dir]

func add_wall_at_to_walllines(x:int,y :int, dir :Maze.Dir,wl :PackedVector2Array ) -> void:
	match dir:
		Maze.Dir.North:
			wl.append_array([Vector2(x,y)*map_scale,Vector2(x+1,y)*map_scale])
		Maze.Dir.West:
			wl.append_array([Vector2(x,y)*map_scale,Vector2(x,y+1)*map_scale])
		Maze.Dir.South:
			wl.append_array([Vector2(x,y+1)*map_scale,Vector2(x+1,y+1)*map_scale])
		Maze.Dir.East:
			wl.append_array([Vector2(x+1,y)*map_scale,Vector2(x+1,y+1)*map_scale])

func _draw() -> void:
	draw_multiline(walllines_all,Color(Color.WHITE,0.5), WallThick)
