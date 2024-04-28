extends Node3D

class_name Storey

var line2d_scene = preload("res://move_line2d/move_line_2d.tscn")
var tree_scene = preload("res://bar_tree_2/bar_tree_2.tscn")
var clock_scene = preload("res://analogclock3d/analog_clock_3d.tscn")
var calendar_scene = preload("res://calendar3d/calendar_3d.tscn")
var ball_trail_scene = preload("res://ball_trail_2/ball_trail_2.tscn")

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
var start_node : MeshInstance3D
var goal_node : MeshInstance3D
var wall_info_all :Array
var capsule_pos_dict = Dictionary()
var donut_pos_dict = Dictionary()
var main_wall_mat :StandardMaterial3D
var main_wall_mat_name :String
var sub_wall_mat :StandardMaterial3D
var sub_wall_tex_name :String
var line2d_subviewport :SubViewport
var clockcalendar_sel :int

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
	sub_wall_mat = StandardMaterial3D.new()
	sub_wall_mat.albedo_texture = Texmat.wall_tex_dict[sub_wall_tex_name]
	sub_wall_mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	sub_wall_mat.uv1_scale = Vector3(3, 2, 1)

	var mat_keys = Texmat.wall_mat_dict.keys()
	mat_keys.shuffle()
	main_wall_mat_name = mat_keys[0]
	main_wall_mat = Texmat.wall_mat_dict[main_wall_mat_name]
	main_wall_mat.uv1_scale = Vector3(3, 2, 1)

	var meshx = maze_size.x*lane_w +wall_thick
	var meshy = maze_size.y*lane_w +wall_thick
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
	start_node = new_text_mark_at(start_pos, Color.YELLOW, "Start")
	goal_node = new_text_mark_at(goal_pos, Color.YELLOW, "Goal")
	var colist = NamedColorList.color_list.duplicate()
	wall_info_all = []
	for y in maze_size.y:
		wall_info_all.append([])
		for x in maze_size.x:
			wall_info_all[y].append( make_cell_wallinfo(x,y) )
			var p = Vector2i(x,y)
			if p == goal_pos || p == start_pos :
				continue
			if maze_cells.get_open_dir_at(x,y).size() == 1 && randi()%2==0:
				var co = colist.pick_random()[0]
				if randi() % 2 ==0:
					var c = new_capsule_at(p, co)
					capsule_pos_dict[p] = c
				else:
					var c = new_donut_at(p, co)
					donut_pos_dict[p] = c
			elif randi()%20==0:
				new_tree_at(p)

	var ba = AABB( Vector3(wall_thick/2,0,wall_thick/2),
		Vector3(maze_size.x*lane_w -wall_thick, storey_h, maze_size.y*lane_w -wall_thick) )
	for i in 14:
		var pos = Vector3(
			randf_range(ba.position.x, ba.end.x),
			randf_range(ba.position.y, ba.end.y),
			randf_range(ba.position.z, ba.end.z),
		)
		var bt = ball_trail_scene.instantiate()
		bt.init(bounce_cell ,storey_h/30, 20, i , pos)
		add_child(bt)

func _process(delta: float) -> void:
	start_node.rotate_y(delta)
	goal_node.rotate_y(delta)
	for n in capsule_pos_dict.values():
		n.rotate_y(delta)
	for n in donut_pos_dict.values():
		n.rotate_y(delta)

func make_cell_wallinfo(x:int, y:int)->Array:
	var axis_wall = [
		[maze_cells.is_wall_dir_at(x,y, Maze.Dir.West), maze_cells.is_wall_dir_at(x,y, Maze.Dir.East)],
		[true,true],
		[maze_cells.is_wall_dir_at(x,y, Maze.Dir.North), maze_cells.is_wall_dir_at(x,y, Maze.Dir.South)],
	]
	var aabb = AABB( Vector3(lane_w*x + wall_thick/2,0,lane_w*y +wall_thick/2),
		Vector3(lane_w -wall_thick, storey_h, lane_w -wall_thick) )
	return [aabb, axis_wall]

# wallinfo [aabb , axis_wall [3][2]bool ]
func bounce_cell(oldpos:Vector3, pos :Vector3, radius :float)->Dictionary:
	var x = clampi(int(oldpos.x/lane_w),0, maze_size.x-1)
	var y = clampi(int(oldpos.z/lane_w),0, maze_size.y-1)
	var wallinfo = wall_info_all[y][x]
	var aabb = wallinfo[0]
	var axis_wall = wallinfo[1]
	var bounced = Vector3i.ZERO
	for i in 3:
		if axis_wall[i][0] && pos[i] < aabb.position[i] + radius :
			pos[i] = aabb.position[i] + radius
			bounced[i] = -1
		elif axis_wall[i][1] && pos[i] > aabb.end[i] - radius:
			pos[i] = aabb.end[i] - radius
			bounced[i] = 1
	return {
		bounced = bounced,
		pos = pos,
	}

func new_capsule_at(p :Vector2i, co:Color)->MeshInstance3D:
	var n = Global3d.new_capsule(lane_w*0.3, lane_w*0.05, Global3d.get_color_mat(co))
	n.rotate_x(PI/2)
	n.position = mazepos2storeypos(p, storey_h/4.0)
	n.rotation.x = randf_range(0, PI)
	n.rotation.y = randf_range(0, 2*PI)
	add_child(n)
	return n

func new_donut_at(p :Vector2i, co:Color)->MeshInstance3D:
	var n = Global3d.new_torus(lane_w*0.07, lane_w*0.15, Global3d.get_color_mat(co))
	n.rotate_x(PI/2)
	n.position = mazepos2storeypos(p, storey_h/4.0)
	n.rotation.x = randf_range(0, PI)
	n.rotation.y = randf_range(0, 2*PI)
	add_child(n)
	return n

func new_tree_at(p :Vector2i)->BarTree2:
	var t = tree_scene.instantiate()
	var w = randf_range(lane_w*0.5, lane_w*0.9)
	var h = randf_range(storey_h*0.5, storey_h*0.9)
	var bar_count = randi_range(10,100)
	var rot_vel = randfn(0.0,0.3)
	t.init_with_color(Global3d.random_color(), Global3d.random_color(), w,h, w/10, bar_count, rot_vel, true)
	t.position = mazepos2storeypos(p, storey_h*0.1)
	t.rotation.y = randf_range(0, 2*PI)
	add_child(t)
	return t

func new_text_mark_at(p :Vector2i, co:Color, text :String)->MeshInstance3D:
	var n = Global3d.new_text(5.0,0.01,Global3d.get_color_mat(co),text)
	n.position = mazepos2storeypos(p, storey_h/2.0)
	n.rotation.y = randf_range(0,2*PI)
	add_child(n)
	return n

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
	var pos_face_ew = Vector3( x *lane_w, storey_h/2.0, y *lane_w +lane_w/2)
	var pos_face_ns = Vector3( x *lane_w +lane_w/2, storey_h/2.0, y *lane_w)
	var size_face_ew = Vector3(wall_thick,storey_h*0.999,lane_w)
	var size_face_ns = Vector3(lane_w,storey_h*0.999,wall_thick)

	if randi()%20 == 0:
		if line2d_subviewport == null:
			line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
		match dir:
			Maze.Dir.West, Maze.Dir.East:
				var b = make_box_from_subviewport(line2d_subviewport, size_face_ew)
				b.position = pos_face_ew
			Maze.Dir.North, Maze.Dir.South:
				var b = make_box_from_subviewport(line2d_subviewport, size_face_ns)
				b.position = pos_face_ns
		return

	var mat :StandardMaterial3D
	if randi()%10 == 0:
		mat = sub_wall_mat
	else:
		mat = main_wall_mat
	var w :MeshInstance3D
	match dir:
		Maze.Dir.West, Maze.Dir.East:
			w = Global3d.new_box(size_face_ew, mat)
			w.position = pos_face_ew
		Maze.Dir.North, Maze.Dir.South:
			w = Global3d.new_box(size_face_ns, mat)
			w.position = pos_face_ns
	$WallContainer.add_child(w)

	# add clock or calendar
	if randi()%20 == 0:
		var n :Node3D
		var depth = 0.1
		clockcalendar_sel +=1
		if clockcalendar_sel % 2 == 0:
			n = calendar_scene.instantiate()
			n.init(lane_w, storey_h,depth, 5, false)
		else :
			n = clock_scene.instantiate()
			n.init(min(lane_w,storey_h)/2,depth, 4, 9.0, false)
		n.rotate_z(PI/2)
		n.rotate_y(Storey.dir2rad(1+MazeDir2Dir[dir]))
		add_child(n)
		match dir:
			Maze.Dir.West:
				n.position = pos_face_ew + Vector3(wall_thick,0,0)
			Maze.Dir.East:
				n.position = pos_face_ew - Vector3(wall_thick,0,0)
			Maze.Dir.North:
				n.position = pos_face_ns + Vector3(0,0,wall_thick)
			Maze.Dir.South:
				n.position = pos_face_ns - Vector3(0,0,wall_thick)

func make_line2d_subvuewport(size_pixel:Vector2i)->SubViewport:
	#print_debug(size_pixel)
	var l2d = line2d_scene.instantiate()
	l2d.init(300,4,1.5,size_pixel)
	var sv = SubViewport.new()
	sv.size = size_pixel
	#sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#sv.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	sv.transparent_bg = true
	sv.add_child(l2d)
	add_child(sv)
	return sv

func make_box_from_subviewport(sv :SubViewport, sz :Vector3)->MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = sz
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.material_override = StandardMaterial3D.new()
	sp.material_override.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	sp.material_override.albedo_texture = sv.get_texture()
	sp.material_override.uv1_scale = Vector3(3, 2, 1) # same tex to all 6 plane
	add_child(sp)
	return sp

func can_move(x :int , y :int, dir :Dir)->bool:
	return maze_cells.is_open_dir_at(x,y, Dir2MazeDir[dir] )

func mazepos2storeypos( mp :Vector2i, y :float)->Vector3:
	return Vector3(lane_w/2+ mp.x*lane_w, y, lane_w/2+ mp.y*lane_w)

func view_floor_ceiling(f :bool,c :bool)->void:
	$Floor.visible = f
	$Ceiling.visible = c

func info_str()->String:
	return "num:%d, size:%s, height:%.1f, lane_w:%.1f, wall_thick:%.1f mainwall:%s subwall:%s" % [
		storey_num, maze_size,storey_h, lane_w, wall_thick,
		main_wall_mat_name, sub_wall_tex_name ]

func is_goal_pos(p :Vector2i)->bool:
	return goal_pos == p

func rand_pos_2i()->Vector2i:
	return Vector2i(randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1) )

func pos_dict_remove_at(pos_dict :Dictionary, p :Vector2i)->bool:
	var c = pos_dict.get(p)
	pos_dict.erase(p)
	if c != null :
		c.queue_free()
		return true
	return false
