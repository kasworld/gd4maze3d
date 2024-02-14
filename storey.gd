extends Node3D

class_name Storey

var tex_dict = {
	brownbrick = preload("res://image/brownbrick.png"),
	bluestone = preload("res://image/bluestone.png"),
	drymud = preload("res://image/drymud.png"),
	graystone = preload("res://image/graystone.png"),
	pinkstone = preload("res://image/pinkstone.png"),
	greenstone = preload("res://image/greenstone.png"),
}


# x90 == degree
enum Dir {
	North = 0,
	West = 1,
	South = 2,
	East = 3,
}
const Dir2Vt = {
	Dir.North : Vector2i(0,-1),
	Dir.West : Vector2i(-1,0),
	Dir.South : Vector2i(0, 1),
	Dir.East : Vector2i(1,0),
}
static func to_maze_dir(d :Dir)->Maze.Dir:
	return Maze.DirList[d%4]
static func dir2str(d :Dir)->String:
	return Dir.keys()[d]
static func dir_left(d:Dir)->Dir:
	return (d+1)%4 as Dir
static func dir_right(d:Dir)->Dir:
	return (d-1+4)%4 as Dir
static func dir_opposite(d:Dir)->Dir:
	return (d+2)%4 as Dir
static func dir2rad(d:Dir)->float:
	return deg_to_rad(d*90.0)

var maze_size : Vector2i
var maze_cells :Maze
var start_pos :Vector2i
var goal_pos :Vector2i
func is_goal_pos(p :Vector2i)->bool:
	return goal_pos == p
var start_node : MeshInstance3D
var goal_node : MeshInstance3D
var capsule_pos_dic :Dictionary
func is_capsule_pos(p :Vector2i)->bool:
	return capsule_pos_dic.get(p)!=null
func remove_capsule_at(p :Vector2i)->bool:
	var c = capsule_pos_dic.get(p)
	capsule_pos_dic.erase(p)
	if c != null :
		c.queue_free()
		return true
	return false
var storey_h = 1.0


var main_wall_tex :CompressedTexture2D
var sub_wall_tex :CompressedTexture2D
func init(msize :Vector2i)->void:
	maze_size = msize
	$Floor.mesh.size = Vector2(maze_size.x, maze_size.y)
	$Floor.position = Vector3(maze_size.x/2.0, 0, maze_size.y/2.0)
	$Floor.mesh.material.albedo_texture = tex_dict[tex_dict.keys().pick_random()]

	$Ceiling.mesh.size = Vector2(maze_size.x, maze_size.y)
	$Ceiling.position = Vector3(maze_size.x/2.0, storey_h, maze_size.y/2.0)
	$Ceiling.mesh.material.albedo_texture = tex_dict[tex_dict.keys().pick_random()]

	main_wall_tex = tex_dict[tex_dict.keys().pick_random()]
	sub_wall_tex = tex_dict[tex_dict.keys().pick_random()]

	$TopViewCamera3D.position = Vector3( maze_size.x/2.0 ,maze_size.y/1.4,maze_size.y/2.0)
	$DirectionalLight3D.position = Vector3( maze_size.x/2.0 ,maze_size.x,maze_size.y/2.0)
	#$DirectionalLight3D.look_at(Vector3( maze_size.x/2.0 ,0,maze_size.y/2.0))
	maze_cells = Maze.new(maze_size)
	maze_cells.make_maze()
	make_wall_by_maze()
	start_pos = rand_pos()
	start_node = add_text_mark_at(start_pos, Color.YELLOW, "Start")
	goal_pos = rand_pos()
	goal_node = add_text_mark_at(goal_pos, Color.YELLOW, "Goal")
	for y in maze_size.y:
		for x in maze_size.x:
			if maze_cells.get_open_dir_at(x,y).size() == 1 && randi_range(0,1)==0:
				var p = Vector2i(x,y)
				var co = NamedColorList.color_list.pick_random()[0]
				var c = add_capsule_at(p, co)
				capsule_pos_dic[p]=c


func add_text_mark_at(p :Vector2i, co:Color, text :String)->MeshInstance3D:
	var n = new_text(5.0,0.01,get_color_mat(co),text)
	n.position=Vector3(0.5+ p.x, storey_h/2.0, 0.5+  p.y)
	add_child(n)
	return n

func add_capsule_at(p :Vector2i, co:Color)->MeshInstance3D:
	var n = new_capsule(0.3,0.05,get_color_mat(co))
	n.position=Vector3(0.5+ p.x, storey_h/4.0, 0.5+  p.y)
	add_child(n)
	return n

func rand_pos()->Vector2i:
	return Vector2i(randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1) )

func _process(delta: float) -> void:
	start_node.rotate_y(delta)
	goal_node.rotate_y(delta)
	for p in capsule_pos_dic:
		capsule_pos_dic[p].rotate_y(delta)


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
	var mat = StandardMaterial3D.new()
	match randi_range(0,10):
		0:
			mat.albedo_texture = sub_wall_tex
		_:
			mat.albedo_texture = main_wall_tex
	var w = new_box(Vector3(1,1,0.01), mat)
	if face_x:
		w.rotate_y(PI/2)
		w.position = Vector3( x  , storey_h/2.0 , y as float +0.5)
	else :
		w.position = Vector3( x as float +0.5 , storey_h/2.0 , y)
	$WallContainer.add_child(w)

func set_top_view(b :bool)->void:
	$Ceiling.visible = not b
	$TopViewCamera3D.current = b
	$DirectionalLight3D.visible = b
	if b :
		$WallContainer.position.y = -storey_h/2.0
	else :
		$WallContainer.position.y = 0.0

func can_move(x :int , y :int, dir :Dir)->bool:
	return maze_cells.is_open_dir_at(x,y, Storey.to_maze_dir(dir) )

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

func new_capsule(h :float,r:float, mat :Material)->MeshInstance3D:
	var mesh = CapsuleMesh.new()
	mesh.height = h
	mesh.radius = r
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.rotate_x(PI/2)
	return sp

func new_box(bsize :Vector3, mat :Material)->MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = bsize
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
