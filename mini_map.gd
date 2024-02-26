extends Node2D

class_name MiniMap

const Scale = 20

var storey :Storey

var player :Line2D

func get_width()->int:
	return storey.maze_size.x * Scale
func get_height()->int:
	return storey.maze_size.y * Scale

var walllines :PackedVector2Array

func init(st :Storey)->void:
	storey = st
	make_wall_by_maze()
	add_point_at(storey.goal_pos.x,storey.goal_pos.y, Color.RED)
	add_point_at(storey.start_pos.x,storey.start_pos.y, Color.YELLOW)
	player = add_point_at(storey.start_pos.x,storey.start_pos.y, Color.GREEN)

func move_player(x:int, y:int)->void:
	player.position = Vector2(x,y)*Scale

func make_wall_by_maze()->void:
	var maze_size = storey.maze_size
	for y in maze_size.y:
		for x in maze_size.x :
			if not storey.maze_cells.is_open_dir_at(x,y,Maze.Dir.North):
				add_wall_at( x , y , false)
			if not storey.maze_cells.is_open_dir_at(x,y,Maze.Dir.West):
				add_wall_at( x , y , true)

	for x in maze_size.x :
		if not storey.maze_cells.is_open_dir_at(x,maze_size.y-1,Maze.Dir.South):
			add_wall_at( x , maze_size.y , false)

	for y in maze_size.y:
		if not storey.maze_cells.is_open_dir_at(maze_size.x-1,y,Maze.Dir.East):
			add_wall_at( maze_size.x , y , true)

func _draw() -> void:
	draw_multiline(walllines,Color(Color.WHITE,0.5), 1.0)

func add_wall_at(x:int,y :int, face_x :bool)->void:
	if face_x:
		walllines.append_array([Vector2(x,y)*Scale,Vector2(x,y+1)*Scale])
	else :
		walllines.append_array([Vector2(x,y)*Scale,Vector2(x+1,y)*Scale])

# between wall
func add_point_at(x:int,y :int, co:Color)->Line2D:
	var ln = new_line(Scale*0.8 , co, [Vector2(0.1,0.5)*Scale,Vector2(0.9,0.5)*Scale] )
	add_child(ln)
	ln.position = Vector2(x,y)*Scale
	return ln

func new_line(w :float, co:Color, pos_list :PackedVector2Array)->Line2D:
	var ln = Line2D.new()
	ln.points = pos_list
	ln.default_color = co
	ln.width = w
	return ln
