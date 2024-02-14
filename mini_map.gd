extends Node2D

class_name MiniMap

const Scale = 20

func init(st :Storey)->void:
	make_wall_by_maze(st)

func make_wall_by_maze(st :Storey)->void:
	var maze_size = st.maze_size
	for y in maze_size.y:
		for x in maze_size.x :
			if not st.maze_cells.is_open_dir_at(x,y,Maze.Dir.North):
				add_wall_at( x , y , false)
			if not st.maze_cells.is_open_dir_at(x,y,Maze.Dir.West):
				add_wall_at( x , y , true)

	for x in maze_size.x :
		if not st.maze_cells.is_open_dir_at(x,maze_size.y-1,Maze.Dir.South):
			add_wall_at( x , maze_size.y , false)

	for y in maze_size.y:
		if not st.maze_cells.is_open_dir_at(maze_size.x-1,y,Maze.Dir.East):
			add_wall_at( maze_size.x , y , true)

func add_wall_at(x:int,y :int, face_x :bool)->void:
	var ln :Line2D
	if face_x:
		ln = new_line( 2, Color.WHITE, [Vector2(x,y)*Scale,Vector2(x,y+1)*Scale])
	else :
		ln = new_line( 2, Color.WHITE, [Vector2(x,y)*Scale,Vector2(x+1,y)*Scale])
	add_child(ln)

func new_line(w :float, co:Color, pos_list :PackedVector2Array)->Line2D:
	var ln = Line2D.new()
	ln.points = pos_list
	ln.default_color = co
	ln.width = w
	return ln
