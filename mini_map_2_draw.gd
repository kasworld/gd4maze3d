extends Node2D

class_name MiniMap2Draw

var map_scale :float = 20
var wall_thick :float = 2
var storey :Storey
var walllines :PackedVector2Array =[]
var walls_known : Array[PackedByteArray] # as bool array
var player :Line2D

func init(st :Storey, sc :float)->void:
	map_scale = sc
	wall_thick = map_scale*0.1
	if wall_thick < 1 :
		wall_thick = 1
	storey = st
	walls_known = []
	walllines = []
	for o in get_children():
		o.queue_free()
	add_point_at(storey.goal_pos.x,storey.goal_pos.y, Color.RED)
	add_point_at(storey.start_pos.x,storey.start_pos.y, Color.YELLOW)
	player = add_point_at(storey.start_pos.x,storey.start_pos.y, Color.GREEN)
	walls_known.resize(storey.maze_size.y*2+1)
	for cl in walls_known:
		cl.resize(storey.maze_size.x*2+1)

func make_allwall_by_maze()->void:
	var maze_size = storey.maze_size
	for y in maze_size.y:
		for x in maze_size.x :
			if not storey.maze_cells.is_open_dir_at(x,y,Maze.Dir.North):
				add_wall_at( x , y , Storey.Dir.North)
			if not storey.maze_cells.is_open_dir_at(x,y,Maze.Dir.West):
				add_wall_at( x , y , Storey.Dir.West)

	for x in maze_size.x :
		if not storey.maze_cells.is_open_dir_at(x,maze_size.y-1,Maze.Dir.South):
			add_wall_at( x , maze_size.y-1 , Storey.Dir.South)

	for y in maze_size.y:
		if not storey.maze_cells.is_open_dir_at(maze_size.x-1,y,Maze.Dir.East):
			add_wall_at( maze_size.x-1 , y , Storey.Dir.East)

func get_width()->int:
	return storey.maze_size.x * map_scale
func get_height()->int:
	return storey.maze_size.y * map_scale

# cell wall[y*2+1][x*2+1]
# wall wall[y*2][x*2]
func calc_wall_pos(x :int, y:int, dir :Storey.Dir)->Vector2i:
	return Vector2i(x*2+1,y*2+1) + Storey.Dir2Vt[dir]
func is_wall_at(x :int, y:int, dir :Storey.Dir)->bool:
	var wpos = calc_wall_pos(x,y,dir)
	return walls_known[wpos.y][wpos.x] != 0
func set_wall_at(x :int, y:int, dir :Storey.Dir):
	var wpos = calc_wall_pos(x,y,dir)
	walls_known[wpos.y][wpos.x] = 1

func move_player(x:int, y:int)->void:
	player.position = Vector2(x,y)*map_scale

func _draw() -> void:
	if walllines.size() == 0 :
		return
	draw_multiline(walllines,Color(Color.WHITE,0.5), wall_thick)

func add_wall_at(x:int,y :int, dir :Storey.Dir)->void:
	if is_wall_at(x,y,dir):
		return
	set_wall_at(x,y,dir)
	match dir:
		Storey.Dir.North:
			walllines.append_array([Vector2(x,y)*map_scale,Vector2(x+1,y)*map_scale])
		Storey.Dir.West:
			walllines.append_array([Vector2(x,y)*map_scale,Vector2(x,y+1)*map_scale])
		Storey.Dir.South:
			walllines.append_array([Vector2(x,y+1)*map_scale,Vector2(x+1,y+1)*map_scale])
		Storey.Dir.East:
			walllines.append_array([Vector2(x+1,y)*map_scale,Vector2(x+1,y+1)*map_scale])
	queue_redraw()

# between wall
func add_point_at(x:int,y :int, co:Color)->Line2D:
	var ln = new_line(map_scale-wall_thick*2 , Color(co,0.5), [Vector2(0.1,0.5)*map_scale,Vector2(0.9,0.5)*map_scale] )
	add_child(ln)
	ln.position = Vector2(x,y)*map_scale
	return ln

func new_line(w :float, co:Color, pos_list :PackedVector2Array)->Line2D:
	var ln = Line2D.new()
	ln.points = pos_list
	ln.default_color = co
	ln.width = w
	return ln
