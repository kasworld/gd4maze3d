extends Node3D

class_name Storey

var line2d_scene = preload("res://move_line2d/move_line_2d.tscn")
var tree_scene = preload("res://bar_tree_2/bar_tree_2.tscn")
var clock_scene = preload("res://analogclock3d/analog_clock_3d.tscn")
var calendar_scene = preload("res://calendar3d/calendar_3d.tscn")
var ball_trail_scene = preload("res://ball_trail_2/ball_trail_2.tscn")
var donut_scene = preload("res://donut.tscn")
var capsule_scene = preload("res://capsule.tscn")
var text_mark_scene = preload("res://text_mark.tscn")

var storey_num :int
var maze_cells :Maze
var wall_info_all :Array
var main_wall_mat :StandardMaterial3D
var main_wall_mat_name :String
var sub_wall_mat :StandardMaterial3D
var sub_wall_tex_name :String
var line2d_subviewport :SubViewport
var clockcalendar_sel :int
var start_pos :Vector2i
var goal_pos :Vector2i

var 놓인것들 :PlacedThings # 배치된 capsule, donut tree start goal 들
var 구석자리목록 :Array[Vector2i] # capsule, donut 배치 가능 위치 목록

func _to_string() -> String:
	return "Storey[%d mainwall:%s subwall:%s]" % [
		storey_num, main_wall_mat_name, sub_wall_tex_name ]

func init(stn :int, stp :Vector2i, gp :Vector2i) -> void:
	storey_num = stn
	start_pos = stp
	goal_pos = gp
	놓인것들 = PlacedThings.new(Settings.MazeSize)
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

	var meshx = Settings.MazeSize.x*Settings.LaneW +Settings.WallThick
	var meshy = Settings.MazeSize.y*Settings.LaneW +Settings.WallThick
	$Floor.mesh.size = Vector2(meshx, meshy)
	$Floor.position = Vector3(meshx/2, 0 , meshy/2)
	$Floor.mesh.material.albedo_texture = Texmat.interfloor_mat
	$Floor.mesh.material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA_SCISSOR
	$Ceiling.mesh.size = $Floor.mesh.size
	$Ceiling.position = Vector3(meshx/2, Settings.StoryH , meshy/2)
	$Ceiling.mesh.material.albedo_texture = Texmat.interfloor_mat
	$Ceiling.mesh.material.transparency = $Floor.mesh.material.transparency

	maze_cells = Maze.new(Settings.MazeSize)
	make_wall_by_maze()

	$StartMark.init(5.0, 0.01, Color.YELLOW, "Start").position = mazepos2storeypos(start_pos, Settings.StoryH/2.0)
	$EndMark.init(5.0, 0.01, Color.YELLOW, "Goal").position = mazepos2storeypos(goal_pos, Settings.StoryH/2.0)
	놓인것들.set_at(start_pos,$StartMark)
	놓인것들.set_at(goal_pos,$EndMark)

	wall_info_all = []
	for y in Settings.MazeSize.y:
		wall_info_all.append([])
		for x in Settings.MazeSize.x:
			wall_info_all[y].append( make_cell_wallinfo(x,y) )
			if maze_cells.get_open_dir_at(x,y).size() == 1:
				구석자리목록.append(Vector2i(x,y))

	add_donut_capsule(Settings.DonutCapsuleCount)
	add_trees(Settings.TreeCount)
	add_ball_trails(Settings.BallTrailCount)

func add_donut_capsule(n :int) -> void:
	for i in n:
		var p = 구석자리목록.pick_random()
		if 놓인것들.get_at(p) != null:
			continue
		var co = NamedColorList.color_list.pick_random()[0]
		var pobj
		if randi()%2 ==0:
			pobj = capsule_scene.instantiate().init(Settings.LaneW*0.3, Settings.LaneW*0.05, co)
		else:
			pobj = donut_scene.instantiate().init(Settings.LaneW*0.07, Settings.LaneW*0.15,co)
		pobj.position = mazepos2storeypos(p, Settings.StoryH/4.0)
		add_child(pobj)
		놓인것들.set_at(p,pobj)

func add_trees(n :int) ->void:
	for i in n:
		var p = Settings.rand_pos_2i()
		if 놓인것들.get_at(p) != null:
			continue
		var t = tree_scene.instantiate().init_with_color(
			NamedColorList.color_list.pick_random()[0],
			NamedColorList.color_list.pick_random()[0],
			randf_range(Settings.LaneW*0.5, Settings.LaneW*0.9),
			randf_range(Settings.StoryH*0.5, Settings.StoryH*0.9),
			randf_range(Settings.LaneW*0.5, Settings.LaneW*0.9)/10,
			randi_range(10,100),
			randfn(0.0,0.3),
			true)
		t.position = mazepos2storeypos(p, Settings.StoryH*0.1)
		t.rotation.y = randf_range(0, 2*PI)
		add_child(t)
		놓인것들.set_at(p,t)

func add_ball_trails(n :int) ->void:
	var ba = AABB( Vector3(Settings.WallThick/2,0, Settings.WallThick/2),
		Vector3(Settings.MazeSize.x*Settings.LaneW -Settings.WallThick, Settings.StoryH, Settings.MazeSize.y*Settings.LaneW -Settings.WallThick) )
	for i in n:
		var pos = Vector3(
			randf_range(ba.position.x, ba.end.x),
			randf_range(ba.position.y, ba.end.y),
			randf_range(ba.position.z, ba.end.z),
		)
		var bt = ball_trail_scene.instantiate().init(bounce_cell ,Settings.StoryH/30, 20, i , pos)
		add_child(bt)

func make_cell_wallinfo(x:int, y:int) -> Array:
	var axis_wall = [
		[maze_cells.is_wall_dir_at(x,y, DirLib.Flag.West), maze_cells.is_wall_dir_at(x,y, DirLib.Flag.East)],
		[true,true],
		[maze_cells.is_wall_dir_at(x,y, DirLib.Flag.North), maze_cells.is_wall_dir_at(x,y, DirLib.Flag.South)],
	]
	var aabb = AABB( Vector3(Settings.LaneW*x +Settings.WallThick/2, 0, Settings.LaneW*y +Settings.WallThick/2),
		Vector3(Settings.LaneW -Settings.WallThick, Settings.StoryH, Settings.LaneW -Settings.WallThick) )
	return [aabb, axis_wall]

# wallinfo [aabb , axis_wall [3][2]bool ]
func bounce_cell(oldpos:Vector3, pos :Vector3, radius :float) -> Dictionary:
	var x = clampi(int(oldpos.x/Settings.LaneW),0, Settings.MazeSize.x-1)
	var y = clampi(int(oldpos.z/Settings.LaneW),0, Settings.MazeSize.y-1)
	var wallinfo = wall_info_all[y][x]
	var aabb = wallinfo[0]
	var axis_wall = wallinfo[1]
	return Bounce.v3f_wall(pos, aabb, axis_wall,radius)

func make_wall_by_maze() -> void:
	for y in Settings.MazeSize.y:
		for x in Settings.MazeSize.x :
			if not maze_cells.is_open_dir_at(x,y,DirLib.Flag.North):
				add_wall_at( x , y , DirLib.Flag.North)
			if not maze_cells.is_open_dir_at(x,y,DirLib.Flag.West):
				add_wall_at( x , y , DirLib.Flag.West)

	for x in Settings.MazeSize.x :
		if not maze_cells.is_open_dir_at(x,Settings.MazeSize.y-1,DirLib.Flag.South):
			add_wall_at( x , Settings.MazeSize.y , DirLib.Flag.South)

	for y in Settings.MazeSize.y:
		if not maze_cells.is_open_dir_at(Settings.MazeSize.x-1,y,DirLib.Flag.East):
			add_wall_at( Settings.MazeSize.x , y , DirLib.Flag.East)

func add_wall_at(x :int, y :int, dir :DirLib.Flag) -> void:
	var pos_face_ew = Vector3( x *Settings.LaneW, Settings.StoryH/2.0, y *Settings.LaneW +Settings.LaneW/2)
	var pos_face_ns = Vector3( x *Settings.LaneW +Settings.LaneW/2, Settings.StoryH/2.0, y *Settings.LaneW)
	var size_face_ew = Vector3(Settings.WallThick,Settings.StoryH*0.999,Settings.LaneW)
	var size_face_ns = Vector3(Settings.LaneW,Settings.StoryH*0.999,Settings.WallThick)

	if randf() < Settings.MakeLine2DWallRate:
		if line2d_subviewport == null:
			line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
		match dir:
			DirLib.Flag.West, DirLib.Flag.East:
				var b = make_box_from_subviewport(line2d_subviewport, size_face_ew)
				b.position = pos_face_ew
			DirLib.Flag.North, DirLib.Flag.South:
				var b = make_box_from_subviewport(line2d_subviewport, size_face_ns)
				b.position = pos_face_ns
		return

	var mat :StandardMaterial3D
	if randf() < Settings.MakeSubWallRate:
		mat = sub_wall_mat
	else:
		mat = main_wall_mat
	var w :MeshInstance3D
	match dir:
		DirLib.Flag.West, DirLib.Flag.East:
			w = Global3d.new_box(size_face_ew, mat)
			w.position = pos_face_ew
		DirLib.Flag.North, DirLib.Flag.South:
			w = Global3d.new_box(size_face_ns, mat)
			w.position = pos_face_ns
	$WallContainer.add_child(w)

	# add clock or calendar
	if randf() < Settings.MakeClockCalWallRate:
		var n :Node3D
		var depth = 0.1
		clockcalendar_sel +=1
		if clockcalendar_sel % 2 == 0:
			n = calendar_scene.instantiate()
			n.init(Settings.LaneW, Settings.StoryH,depth, 5, false)
		else :
			n = clock_scene.instantiate()
			n.init(min(Settings.LaneW,Settings.StoryH)/2,depth, 4, 9.0, false)
		n.rotate_z(PI/2)
		n.rotate_y(DirLib.dir2rad(1+DirLib.Flag2Dir[dir]))
		add_child(n)
		match dir:
			DirLib.Flag.West:
				n.position = pos_face_ew + Vector3(Settings.WallThick,0,0)
			DirLib.Flag.East:
				n.position = pos_face_ew - Vector3(Settings.WallThick,0,0)
			DirLib.Flag.North:
				n.position = pos_face_ns + Vector3(0,0,Settings.WallThick)
			DirLib.Flag.South:
				n.position = pos_face_ns - Vector3(0,0,Settings.WallThick)

func make_line2d_subvuewport(size_pixel:Vector2i) -> SubViewport:
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

func make_box_from_subviewport(sv :SubViewport, sz :Vector3) -> MeshInstance3D:
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

func can_move(x :int , y :int, dir :DirLib.Dir) -> bool:
	return maze_cells.is_open_dir_at(x,y, DirLib.Dir2Flag[dir] )

func mazepos2storeypos( mp :Vector2i, y :float) -> Vector3:
	return Vector3(Settings.LaneW/2+ mp.x*Settings.LaneW, y, Settings.LaneW/2+ mp.y*Settings.LaneW)

func view_floor_ceiling(f :bool,c :bool) -> void:
	$Floor.visible = f
	$Ceiling.visible = c

func is_goal_pos(p :Vector2i) -> bool:
	return goal_pos == p
