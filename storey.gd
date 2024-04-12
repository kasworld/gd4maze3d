extends Node3D

class_name Storey

var line2d_scene = preload("res://move_line2d/move_line_2d.tscn")

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
	n.rotation.y = randf_range(0,2*PI)
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
	n.rotation.y = randf_range(0,2*PI)
	add_child(n)
	return n

var tree_scene = preload("res://bar_tree/bar_tree.tscn")
func new_tree_at(p :Vector2i)->BarTree:
	var t = tree_scene.instantiate()
	add_child(t)
	t.position = mazepos2storeypos(p, storey_h*0.1)
	t.rotation.y = randf_range(0,2*PI)
	return t

func random_color()->Color:
	return Color(randf(),randf(),randf())

func make_tree(p :Vector2i)->void:
	var tr :BarTree = new_tree_at(p)
	var w = randf_range(lane_w*0.1,lane_w*0.9)
	var h = randf_range(storey_h*0.1,storey_h*0.9)
	match randi_range(0,3):
		0:
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = Texmat.tree_tex_dict.floorwood
			tr.init_with_material(mat,w,h, w/2, h*10, 1.0, 1.0/60.0)
		1:
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = Texmat.tree_tex_dict.darkwood
			mat.uv1_triplanar = true
			tr.init_with_material(mat,w,h, w/2, h*10, 1.0, 1.0/60.0)
		_:
			tr.init_with_color(random_color(), random_color(), false,w,h, w/2, h*10, 1.0, 1.0/60.0)

func mazepos2storeypos( mp :Vector2i, y :float)->Vector3:
	return Vector3(lane_w/2+ mp.x*lane_w, y, lane_w/2+ mp.y*lane_w)

func info_str()->String:
	return "num:%d, size:%s, height:%.1f, lane_w:%.1f, wall_thick:%.1f mainwall:%s subwall:%s" % [
		storey_num, maze_size,storey_h, lane_w, wall_thick*lane_w,
		main_wall_mat_name, sub_wall_tex_name ]

var main_wall_mat :StandardMaterial3D
var main_wall_mat_name :String
var sub_wall_tex :CompressedTexture2D
var sub_wall_tex_name :String
func init(stn :int, msize :Vector2i, h :float, lw :float, wt :float, stp :Vector2i, gp :Vector2i)->void:
	storey_num = stn
	maze_size = msize
	storey_h = h
	lane_w = lw
	wall_thick = wt
	start_pos = stp
	goal_pos = gp

	var tex_keys = Texmat.wall_tex_dict.keys()
	tex_keys.shuffle()
	sub_wall_tex_name = tex_keys[0]
	sub_wall_tex = Texmat.wall_tex_dict[sub_wall_tex_name]

	var mat_keys = Texmat.wall_mat_dict.keys()
	mat_keys.shuffle()
	main_wall_mat_name = mat_keys[0]
	main_wall_mat = Texmat.wall_mat_dict[main_wall_mat_name]

	var meshx = maze_size.x*lane_w +wall_thick*2
	var meshy = maze_size.y*lane_w +wall_thick*2
	$Floor.mesh.size = Vector2(meshx, meshy)
	$Floor.position = Vector3(meshx/2, storey_h * 0.0, meshy/2)
	$Floor.mesh.material.albedo_texture = Texmat.interfloor_mat
	$Floor.mesh.material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA_SCISSOR
	$Ceiling.mesh.size = Vector2(meshx, meshy)
	$Ceiling.position = Vector3(meshx/2, storey_h * 1.0, meshy/2)
	$Ceiling.mesh.material.albedo_texture = Texmat.interfloor_mat
	$Ceiling.mesh.material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA_SCISSOR

	maze_cells = Maze.new(maze_size)
	maze_cells.make_maze()
	make_wall_by_maze()
	start_node = add_text_mark_at(start_pos, Color.YELLOW, "Start")
	goal_node = add_text_mark_at(goal_pos, Color.YELLOW, "Goal")
	var colist = NamedColorList.color_list.duplicate()
	for y in maze_size.y:
		for x in maze_size.x:
			var p = Vector2i(x,y)
			if p == goal_pos || p == start_pos :
				continue
			if maze_cells.get_open_dir_at(x,y).size() == 1 && randi_range(0,1)==0:
				var co = colist.pick_random()[0]
				if randi_range(0,1)==0:
					var c = add_capsule_at(p, co)
					capsule_pos_dic[p]=c
				else:
					var c = add_donut_at(p, co)
					donut_pos_dic[p]=c
			elif randi_range(0,maze_size.x *maze_size.y /4)==0:
				make_tree(p)

func add_text_mark_at(p :Vector2i, co:Color, text :String)->MeshInstance3D:
	var n = new_text(5.0,0.01,get_color_mat(co),text)
	n.position = mazepos2storeypos(p, storey_h/2.0)
	n.rotation.y = randf_range(0,2*PI)
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
				add_wall_at( x , y , Maze.Dir.North)
			if not maze_cells.is_open_dir_at(x,y,Maze.Dir.West):
				add_wall_at( x , y , Maze.Dir.West)

	for x in maze_size.x :
		if not maze_cells.is_open_dir_at(x,maze_size.y-1,Maze.Dir.South):
			add_wall_at( x , maze_size.y , Maze.Dir.South)

	for y in maze_size.y:
		if not maze_cells.is_open_dir_at(maze_size.x-1,y,Maze.Dir.East):
			add_wall_at( maze_size.x , y , Maze.Dir.East)

func add_wall_at(x :int, y :int, dir :Maze.Dir)->void:
	# add line2d
	var pos_face_ew = Vector3( x *lane_w, storey_h/2.0, y *lane_w +lane_w/2)
	var pos_face_ns = Vector3( x *lane_w +lane_w/2, storey_h/2.0, y *lane_w)
	if randi_range(0,maze_size.x *maze_size.y /2) == 0:
		var l2dsize = Vector2(lane_w,storey_h)
		var l2dpsize = Vector2i(2000,1500)
		match dir:
			Maze.Dir.West:
				make_line2d(l2dsize, l2dpsize, pos_face_ew, PlaneMesh.Orientation.FACE_X,true)
				make_line2d(l2dsize, l2dpsize, pos_face_ew, PlaneMesh.Orientation.FACE_X,false)
			Maze.Dir.East:
				make_line2d(l2dsize, l2dpsize, pos_face_ew, PlaneMesh.Orientation.FACE_X,true)
				make_line2d(l2dsize, l2dpsize, pos_face_ew, PlaneMesh.Orientation.FACE_X,false)
			Maze.Dir.South:
				make_line2d(l2dsize, l2dpsize, pos_face_ns, PlaneMesh.Orientation.FACE_Z,true)
				make_line2d(l2dsize, l2dpsize, pos_face_ns, PlaneMesh.Orientation.FACE_Z,false)
			Maze.Dir.North:
				make_line2d(l2dsize, l2dpsize, pos_face_ns, PlaneMesh.Orientation.FACE_Z,true)
				make_line2d(l2dsize, l2dpsize, pos_face_ns, PlaneMesh.Orientation.FACE_Z,false)
		return

	var mat :StandardMaterial3D
	match randi_range(0,10):
		0:
			mat = StandardMaterial3D.new()
			mat.albedo_texture = sub_wall_tex
			mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
		_:
			mat = main_wall_mat
	var w :MeshInstance3D
	match dir:
		Maze.Dir.West, Maze.Dir.East:
			#w = new_box(Vector3(wall_thick,storey_h*0.999,lane_w*0.999), mat)
			w = new_box(Vector3(wall_thick,storey_h*0.999,lane_w), mat)
			w.position = pos_face_ew
		Maze.Dir.North, Maze.Dir.South:
			w = new_box(Vector3(lane_w,storey_h*0.999,wall_thick), mat)
			#w = new_box(Vector3(lane_w*0.999,storey_h*0.999,wall_thick), mat)
			w.position = pos_face_ns
	$WallContainer.add_child(w)

func make_line2d(sz :Vector2, psz:Vector2i, pos :Vector3, face :PlaneMesh.Orientation, flip :bool)->MeshInstance3D:
	var mesh = PlaneMesh.new()
	mesh.size = sz
	mesh.orientation = face
	mesh.flip_faces = flip
	var size_pixel = psz
	#print_debug(size_pixel)
	var l2d = line2d_scene.instantiate()
	l2d.init(300,4,size_pixel)
	var sv = SubViewport.new()
	sv.size = size_pixel
	#sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#sv.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	sv.transparent_bg = true
	sv.add_child(l2d)
	add_child(sv)
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.position = pos
	sp.material_override = StandardMaterial3D.new()
	sp.material_override.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	sp.material_override.albedo_texture = sv.get_texture()
	add_child(sp)
	return sp


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
