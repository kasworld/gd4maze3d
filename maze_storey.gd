extends Node3D

var maze_size = Vector2i(16,16)
var maze_cells :Maze

var wall_z_mesh = preload("res://wall_z.tres")

func init(msize :Vector2i)->void:
	maze_size = msize
	$Floor.mesh.size = Vector2(maze_size.x, maze_size.y)
	$Floor.position = Vector3(maze_size.x/2,0,maze_size.y/2)
	$Ceiling.mesh.size = Vector2(maze_size.x, maze_size.y)
	$Ceiling.position = Vector3(maze_size.x/2,2,maze_size.y/2)
	$TopViewCamera3D.position = Vector3( maze_size.x/2 ,maze_size.x/1.4,maze_size.y/2)
	maze_cells = Maze.new(maze_size)
	maze_cells.make_maze()
	make_wall_by_maze()

func make_wall_by_maze()->void:
	for y in maze_size.y:
		for x in maze_size.x :
			if not maze_cells.is_open_dir_at(x,y,Maze.N):
				add_wall_at( x , y , false)
			if not maze_cells.is_open_dir_at(x,y,Maze.E):
				add_wall_at( x , y , true)

	for x in maze_size.x :
		if not maze_cells.is_open_dir_at(x,maze_size.y-1,Maze.S):
			add_wall_at( x , maze_size.y , false)

	for y in maze_size.y:
		if not maze_cells.is_open_dir_at(maze_size.x-1,y,Maze.W):
			add_wall_at( maze_size.x , y , true)

func add_wall_at(x:int,y :int, face_x :bool)->void:
	#var w = new_box(Vector3(1,2,0.01),wall_mat)
	var w = MeshInstance3D.new()
	w.mesh = wall_z_mesh
	if face_x:
		w.rotate_y(-PI/2)
		w.position = Vector3( x  , 1.0 , y as float +0.5)
	else :
		w.position = Vector3( x as float +0.5 , 1.0 , y)
	$WallContainer.add_child(w)

func set_top_view(b :bool)->void:
	$Ceiling.visible = not b
	$TopViewCamera3D.current = b