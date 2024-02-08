extends Node3D

var maze_size : Vector2i
var maze_cells :Maze
var start_pos :Vector2i
var goal_pos :Vector2i
var start_node : MeshInstance3D
var goal_node : MeshInstance3D

var wall_z_mesh = preload("res://wall_z.tres")

func init(msize :Vector2i)->void:
	maze_size = msize
	$Floor.mesh.size = Vector2(maze_size.x, maze_size.y)
	$Floor.position = Vector3(maze_size.x/2.0,0,maze_size.y/2.0)
	$Ceiling.mesh.size = Vector2(maze_size.x, maze_size.y)
	$Ceiling.position = Vector3(maze_size.x/2.0,2.0,maze_size.y/2.0)
	$TopViewCamera3D.position = Vector3( maze_size.x/2.0 ,maze_size.x/1.2,maze_size.y/2.0)
	$DirectionalLight3D.position = Vector3( maze_size.x/2.0 ,maze_size.x,maze_size.y/2.0)
	#$DirectionalLight3D.look_at(Vector3( maze_size.x/2.0 ,0,maze_size.y/2.0))
	maze_cells = Maze.new(maze_size)
	maze_cells.make_maze()
	make_wall_by_maze()
	start_pos = Vector2i(randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1) )
	start_node = new_text(5.0,0.01,get_color_mat(Color.YELLOW),"Start")
	start_node.position=Vector3(0.5+ start_pos.x, 1,0.5+  start_pos.y)
	add_child(start_node)
	goal_pos = Vector2i(randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1) )
	goal_node = new_text(5.0,0.01,get_color_mat(Color.YELLOW),"Goal")
	goal_node.position=Vector3(0.5+ goal_pos.x, 1, 0.5+  goal_pos.y)
	add_child(goal_node)

func _process(delta: float) -> void:
	start_node.rotate_y(delta)
	goal_node.rotate_y(delta)

func make_wall_by_maze()->void:
	for y in maze_size.y:
		for x in maze_size.x :
			if not maze_cells.is_open_dir_at(x,y,Maze.Dir.North):
				add_wall_at( x , y , false)
			if not maze_cells.is_open_dir_at(x,y,Maze.Dir.West):
				add_wall_at( x , y , true)

	for x in maze_size.x :
		if not maze_cells.is_open_dir_at(x,maze_size.y-1,Maze.Dir.South):
			add_wall_at( x , maze_size.y , false)

	for y in maze_size.y:
		if not maze_cells.is_open_dir_at(maze_size.x-1,y,Maze.Dir.East):
			add_wall_at( maze_size.x , y , true)

func add_wall_at(x:int,y :int, face_x :bool)->void:
	var w = MeshInstance3D.new()
	w.mesh = wall_z_mesh
	if face_x:
		w.rotate_y(PI/2)
		w.position = Vector3( x  , 1.0 , y as float +0.5)
	else :
		w.position = Vector3( x as float +0.5 , 1.0 , y)
	$WallContainer.add_child(w)

func set_top_view(b :bool)->void:
	$Ceiling.visible = not b
	$TopViewCamera3D.current = b
	$DirectionalLight3D.visible = b
	if b :
		$WallContainer.position.y = -1.5
	else :
		$WallContainer.position.y = 0.0

func can_move(x :int , y :int, dir :Maze.Dir)->bool:
	return maze_cells.is_open_dir_at(x,y,dir)

func open_dir_str(x :int , y :int)->String:
	var rtn = ""
	for d in maze_cells.get_open_dir_at(x,y):
		rtn += "%s " %[Maze.Dir2Str[d]]
	return rtn

func new_text(fsize :float, d :float, mat :Material, text :String)->MeshInstance3D:
	var mesh = TextMesh.new()
	mesh.depth = d
	mesh.pixel_size = fsize / 64
	mesh.font_size = fsize
	mesh.text = text
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	return sp

func new_torus(r :float, mat :Material)->MeshInstance3D:
	var mesh = TorusMesh.new()
	mesh.inner_radius = r/2
	mesh.outer_radius = r
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	return sp

func new_capsule(r :float, mat :Material)->MeshInstance3D:
	var mesh = CapsuleMesh.new()
	mesh.height = r*3
	mesh.radius = r*0.75
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	return sp

func get_color_mat(co: Color)->Material:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = co
	#mat.metallic = 1
	#mat.clearcoat = true
	return mat
