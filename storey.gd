extends Node3D

class_name Storey

var tex_dict = {
	brownbrick = preload("res://image/brownbrick50.png"),
	bluestone = preload("res://image/bluestone50.png"),
	drymud = preload("res://image/drymud50.png"),
	graystone = preload("res://image/graystone50.png"),
	pinkstone = preload("res://image/pinkstone50.png"),
	greenstone = preload("res://image/greenstone50.png"),
	ice50 = preload("res://image/ice50.png")
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
const MazeDir2Dir = {
	Maze.Dir.North : Dir.North,
	Maze.Dir.West : Dir.West,
	Maze.Dir.South : Dir.South,
	Maze.Dir.East : Dir.East,
}
const Dir2MazeDir = {
	Dir.North : Maze.Dir.North,
	Dir.West : Maze.Dir.West,
	Dir.South : Maze.Dir.South,
	Dir.East : Maze.Dir.East,
}

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

var storey_num :int
var maze_size : Vector2i
var storey_h :float
var lane_w :float
var wall_thick :float
var start_pos :Vector2i
var goal_pos :Vector2i

var maze_cells :Maze
func is_goal_pos(p :Vector2i)->bool:
	return goal_pos == p
var start_node : MeshInstance3D
var goal_node : MeshInstance3D
func rand_pos()->Vector2i:
	return Vector2i(randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1) )

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
func add_capsule_at(p :Vector2i, co:Color)->MeshInstance3D:
	var n = new_capsule(lane_w*0.3,lane_w*0.05,get_color_mat(co))
	n.position = mazepos2storeypos(p, storey_h/4.0)
	add_child(n)
	return n

var donut_pos_dic :Dictionary
func is_donut_pos(p :Vector2i)->bool:
	return donut_pos_dic.get(p)!=null
func remove_donut_at(p :Vector2i)->bool:
	var c = donut_pos_dic.get(p)
	donut_pos_dic.erase(p)
	if c != null :
		c.queue_free()
		return true
	return false
func add_donut_at(p :Vector2i, co:Color)->MeshInstance3D:
	var n = new_torus(lane_w*0.1,lane_w* 0.2, get_color_mat(co))
	n.position = mazepos2storeypos(p, storey_h/4.0)
	add_child(n)
	return n

func mazepos2storeypos( mp :Vector2i, y :float)->Vector3:
	return Vector3(lane_w/2+ mp.x*lane_w, y, lane_w/2+ mp.y*lane_w)

func info_str()->String:
	return "num:%d, size:%s, height:%.1f, lane_w:%.1f, wall_thick:%.1f" % [
		storey_num, maze_size,storey_h, lane_w, wall_thick*lane_w ]

var main_wall_tex :CompressedTexture2D
var sub_wall_tex :CompressedTexture2D
func init(stn :int, msize :Vector2i, h :float, lw :float, wt :float, stp :Vector2i, gp :Vector2i)->void:
	storey_num = stn
	maze_size = msize
	storey_h = h
	lane_w = lw
	wall_thick = wt
	start_pos = stp
	goal_pos = gp

	var tex_keys = tex_dict.keys()
	tex_keys.shuffle()
	main_wall_tex = tex_dict[tex_keys[2]]
	sub_wall_tex = tex_dict[tex_keys[3]]

	var meshx = maze_size.x*lane_w +wall_thick*2
	var meshy = maze_size.y*lane_w +wall_thick*2
	$Floor.mesh.size = Vector2(meshx, meshy)
	$Floor.position = Vector3(meshx/2, 0, meshy/2)
	$Floor.mesh.material.albedo_texture = tex_dict[tex_keys[0]]
	$Floor.mesh.material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA

	$Ceiling.mesh.size = Vector2(meshx, meshy)
	$Ceiling.position = Vector3(meshx/2, storey_h, meshy/2)
	$Ceiling.mesh.material.albedo_texture = tex_dict[tex_keys[1]]
	$Ceiling.mesh.material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA

	maze_cells = Maze.new(maze_size)
	maze_cells.make_maze()
	make_wall_by_maze()
	start_node = add_text_mark_at(start_pos, Color.YELLOW, "Start")
	goal_node = add_text_mark_at(goal_pos, Color.YELLOW, "Goal")
	for y in maze_size.y:
		for x in maze_size.x:
			var p = Vector2i(x,y)
			if p == goal_pos || p == start_pos :
				continue
			if maze_cells.get_open_dir_at(x,y).size() == 1 && randi_range(0,1)==0:
				var co = NamedColorList.color_list.pick_random()[0]
				if randi_range(0,1)==0:
					var c = add_capsule_at(p, co)
					capsule_pos_dic[p]=c
				else:
					var c = add_donut_at(p, co)
					donut_pos_dic[p]=c

func add_text_mark_at(p :Vector2i, co:Color, text :String)->MeshInstance3D:
	var n = new_text(5.0,0.01,get_color_mat(co),text)
	n.position = mazepos2storeypos(p, storey_h/2.0)
	add_child(n)
	return n

func set_start_pos(p :Vector2i)->void:
	start_pos = p
	start_node.position = mazepos2storeypos(p, storey_h/2.0)

func _process(delta: float) -> void:
	start_node.rotate_y(delta)
	goal_node.rotate_y(delta)
	for p in capsule_pos_dic:
		capsule_pos_dic[p].rotate_y(delta)
	for p in donut_pos_dic:
		donut_pos_dic[p].rotate_y(delta)

func view_floor_ceiling(f :bool,c :bool)->void:
	$Floor.visible = f
	$Ceiling.visible = c

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


func add_wall_at(x :int, y :int, face_x :bool)->void:
	var mat = StandardMaterial3D.new()
	match randi_range(0,10):
		0:
			mat.albedo_texture = sub_wall_tex
			mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
		_:
			mat.albedo_texture = main_wall_tex
	var w :MeshInstance3D
	if face_x:
		w = new_box(Vector3(wall_thick,storey_h*0.999,lane_w*0.999), mat)
		w.position = Vector3( x *lane_w, storey_h/2.0, y *lane_w +lane_w/2)
	else :
		w = new_box(Vector3(lane_w*0.999,storey_h*0.999,wall_thick), mat)
		w.position = Vector3( x *lane_w +lane_w/2, storey_h/2.0, y *lane_w)
	$WallContainer.add_child(w)

func can_move(x :int , y :int, dir :Dir)->bool:
	return maze_cells.is_open_dir_at(x,y, Storey.Dir2MazeDir[dir] )

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

func new_torus(r1 :float, r2 :float, mat :Material)->MeshInstance3D:
	var mesh = TorusMesh.new()
	mesh.inner_radius = r1
	mesh.outer_radius = r2
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.call_deferred("rotate_x",PI/2)
	return sp

func new_capsule(h :float,r:float, mat :Material)->MeshInstance3D:
	var mesh = CapsuleMesh.new()
	mesh.height = h
	mesh.radius = r
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.call_deferred("rotate_x",PI/2)
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
