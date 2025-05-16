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

var tower_setting :TowerSetting
var storey_num :int
var maze_cells :Maze
var wall_info_all :Array
var main_wall_mat :StandardMaterial3D
var main_wall_mat_name :String
var sub_wall_mat :StandardMaterial3D
var sub_wall_tex_name :String
var pillar_mat :StandardMaterial3D
var line2d_subviewport :SubViewport
var clockcalendar_sel :int
var start_pos :Vector2i
var goal_pos :Vector2i

var 놓인것들 :PlacedThings # 배치된 capsule, donut tree start goal 들
var 구석자리목록 :Array[Vector2i] # capsule, donut 배치 가능 위치 목록

func _to_string() -> String:
	return "Storey[%d mainwall:%s subwall:%s]" % [
		storey_num, main_wall_mat_name, sub_wall_tex_name ]

func init(ts :TowerSetting, stn :int, stp :Vector2i, gp :Vector2i) -> Storey:
	tower_setting = ts
	storey_num = stn
	start_pos = stp
	goal_pos = gp
	놓인것들 = PlacedThings.new(tower_setting.MazeSize)
	var tex_keys = Texmat.wall_tex_dict.keys()
	tex_keys.shuffle()
	sub_wall_tex_name = tex_keys[0]
	sub_wall_mat = StandardMaterial3D.new()
	sub_wall_mat.albedo_texture = Texmat.wall_tex_dict[sub_wall_tex_name]
	sub_wall_mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	sub_wall_mat.uv1_scale = Vector3(3, 2, 1)
	#sub_wall_mat.uv1_scale = Vector3(tower_setting.LaneW/2, tower_setting.StoryH/2, 1)

	var mat_keys = Texmat.wall_mat_dict.keys()
	mat_keys.shuffle()
	main_wall_mat_name = mat_keys[0]
	main_wall_mat = Texmat.wall_mat_dict[main_wall_mat_name]
	main_wall_mat.uv1_scale = Vector3(3, 2, 1)
	#main_wall_mat.uv1_scale = Vector3(tower_setting.LaneW/2, tower_setting.StoryH/2, 1)

	pillar_mat = main_wall_mat.duplicate()
	pillar_mat.uv1_scale = Vector3( 3.0/20, 2, 1)

	var meshx = tower_setting.MazeSize.x*tower_setting.LaneW +tower_setting.WallThick
	var meshy = tower_setting.MazeSize.y*tower_setting.LaneW +tower_setting.WallThick
	$Floor.mesh.size = Vector2(meshx, meshy)
	$Floor.position = Vector3(meshx/2, -tower_setting.calc_current_storey_gap()/2 , meshy/2)
	$Floor.mesh.material.albedo_texture = Texmat.interfloor_mat
	$Floor.mesh.material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA_SCISSOR
	$Ceiling.mesh.size = $Floor.mesh.size
	$Ceiling.position = Vector3(meshx/2, tower_setting.StoryH + tower_setting.calc_current_storey_gap()/2 , meshy/2)
	$Ceiling.mesh.material.albedo_texture = Texmat.interfloor_mat
	$Ceiling.mesh.material.transparency = $Floor.mesh.material.transparency

	maze_cells = Maze.new(tower_setting.MazeSize)
	make_wall_by_maze()
	make_pillas()

	$StartMark.init(5.0, 0.01, Color.YELLOW, "Start").position = mazepos2storeypos(start_pos, tower_setting.StoryH/2.0)
	$EndMark.init(5.0, 0.01, Color.YELLOW, "Goal").position = mazepos2storeypos(goal_pos, tower_setting.StoryH/2.0)
	놓인것들.set_at(start_pos,$StartMark)
	놓인것들.set_at(goal_pos,$EndMark)

	wall_info_all = []
	for y in tower_setting.MazeSize.y:
		wall_info_all.append([])
		for x in tower_setting.MazeSize.x:
			wall_info_all[y].append( make_cell_wallinfo(x,y) )
			if maze_cells.get_open_dir_at(x,y).size() == 1:
				구석자리목록.append(Vector2i(x,y))

	add_donut_capsule(tower_setting.DonutCapsuleCount)
	add_trees(tower_setting.TreeCount)
	add_ball_trails(tower_setting.BallTrailCount)
	return self

func add_donut_capsule(n :int) -> void:
	for i in n:
		var p = 구석자리목록.pick_random()
		if 놓인것들.get_at(p) != null:
			continue
		var co = NamedColorList.color_list.pick_random()[0]
		var pobj
		if randi()%2 ==0:
			pobj = capsule_scene.instantiate().init(tower_setting.LaneW*0.3, tower_setting.LaneW*0.05, co)
		else:
			pobj = donut_scene.instantiate().init(tower_setting.LaneW*0.07, tower_setting.LaneW*0.15,co)
		pobj.position = mazepos2storeypos(p, tower_setting.StoryH/4.0)
		add_child(pobj)
		놓인것들.set_at(p,pobj)

func add_trees(n :int) ->void:
	for i in n:
		var p = tower_setting.rand_pos_2i()
		if 놓인것들.get_at(p) != null:
			continue
		var t = tree_scene.instantiate().init_with_color(
			NamedColorList.color_list.pick_random()[0],
			NamedColorList.color_list.pick_random()[0],
			randf_range(tower_setting.LaneW*0.5, tower_setting.LaneW*0.9),
			randf_range(tower_setting.StoryH*0.5, tower_setting.StoryH*0.9),
			randf_range(tower_setting.LaneW*0.5, tower_setting.LaneW*0.9)/10,
			randi_range(10,100),
			randfn(0.0,0.3),
			true)
		t.position = mazepos2storeypos(p, tower_setting.StoryH*0.1)
		t.rotation.y = randf_range(0, 2*PI)
		add_child(t)
		놓인것들.set_at(p,t)

func add_ball_trails(n :int) ->void:
	var ba = AABB( Vector3(tower_setting.WallThick/2,0, tower_setting.WallThick/2),
		Vector3(tower_setting.MazeSize.x*tower_setting.LaneW -tower_setting.WallThick, tower_setting.StoryH, tower_setting.MazeSize.y*tower_setting.LaneW -tower_setting.WallThick) )
	for i in n:
		var pos = Vector3(
			randf_range(ba.position.x, ba.end.x),
			randf_range(ba.position.y, ba.end.y),
			randf_range(ba.position.z, ba.end.z),
		)
		var bt = ball_trail_scene.instantiate().init(bounce_cell ,tower_setting.StoryH/30, 20, i , pos)
		add_child(bt)

func make_cell_wallinfo(x:int, y:int) -> Array:
	var axis_wall = [
		[maze_cells.is_wall_dir_at(x,y, DirLib.Flag.West), maze_cells.is_wall_dir_at(x,y, DirLib.Flag.East)],
		[true,true],
		[maze_cells.is_wall_dir_at(x,y, DirLib.Flag.North), maze_cells.is_wall_dir_at(x,y, DirLib.Flag.South)],
	]
	var aabb = AABB( Vector3(tower_setting.LaneW*x +tower_setting.WallThick/2, 0, tower_setting.LaneW*y +tower_setting.WallThick/2),
		Vector3(tower_setting.LaneW -tower_setting.WallThick, tower_setting.StoryH, tower_setting.LaneW -tower_setting.WallThick) )
	return [aabb, axis_wall]

# wallinfo [aabb , axis_wall [3][2]bool ]
func bounce_cell(oldpos:Vector3, pos :Vector3, radius :float) -> Dictionary:
	var x = clampi(int(oldpos.x/tower_setting.LaneW),0, tower_setting.MazeSize.x-1)
	var y = clampi(int(oldpos.z/tower_setting.LaneW),0, tower_setting.MazeSize.y-1)
	var wallinfo = wall_info_all[y][x]
	var aabb = wallinfo[0]
	var axis_wall = wallinfo[1]
	return Bounce.v3f_wall(pos, aabb, axis_wall,radius)

func make_pillas() -> void:
	var multi_inst = make_box_multi_inst(pillar_mat, Vector3(tower_setting.WallThick,tower_setting.StoryH,tower_setting.WallThick) )
	$PillarContainer.add_child(multi_inst)
	var pos_list :Array = []
	for y in tower_setting.MazeSize.y+1:
		for x in tower_setting.MazeSize.x+1:
			pos_list.append(Vector3( x *tower_setting.LaneW, tower_setting.StoryH/2.0, y *tower_setting.LaneW) )
	pos_multimesh(multi_inst.multimesh, pos_list)

func make_box_multi_inst(mat :Material, sz :Vector3) -> MultiMeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = sz
	mesh.material = mat
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var multi_inst = MultiMeshInstance3D.new()
	multi_inst.multimesh = multimesh
	return multi_inst

func pos_multimesh(multimesh :MultiMesh, pos_list :Array) -> void:
	multimesh.instance_count = pos_list.size()
	multimesh.visible_instance_count = pos_list.size()
	for i in pos_list.size():
		var t = Transform3D(Basis(), pos_list[i])
		multimesh.set_instance_transform(i,t)

func set_wall_size(full :bool) -> void:
	if full:
		wall_multi_inst_ns_main.multimesh.mesh.size = tower_setting.WallSize_NS_Full
		wall_multi_inst_ns_sub.multimesh.mesh.size = tower_setting.WallSize_NS_Full
		wall_multi_inst_ew_main.multimesh.mesh.size = tower_setting.WallSize_EW_Full
		wall_multi_inst_ew_sub.multimesh.mesh.size = tower_setting.WallSize_EW_Full
	else:
		wall_multi_inst_ns_main.multimesh.mesh.size = tower_setting.WallSize_NS_Reduced
		wall_multi_inst_ns_sub.multimesh.mesh.size = tower_setting.WallSize_NS_Reduced
		wall_multi_inst_ew_main.multimesh.mesh.size = tower_setting.WallSize_EW_Reduced
		wall_multi_inst_ew_sub.multimesh.mesh.size = tower_setting.WallSize_EW_Reduced

var wall_multi_inst_ew_main :MultiMeshInstance3D
var wall_multi_inst_ns_main :MultiMeshInstance3D
var wall_multi_inst_ew_sub :MultiMeshInstance3D
var wall_multi_inst_ns_sub :MultiMeshInstance3D
var pos_list_ew_main :Array
var pos_list_ns_main :Array
var pos_list_ew_sub :Array
var pos_list_ns_sub :Array
func make_wall_by_maze() -> void:
	wall_multi_inst_ew_main = make_box_multi_inst(main_wall_mat,tower_setting.WallSize_EW_Reduced)
	wall_multi_inst_ns_main = make_box_multi_inst(main_wall_mat,tower_setting.WallSize_NS_Reduced)
	wall_multi_inst_ew_sub = make_box_multi_inst(sub_wall_mat,tower_setting.WallSize_EW_Reduced)
	wall_multi_inst_ns_sub = make_box_multi_inst(sub_wall_mat,tower_setting.WallSize_NS_Reduced)
	$WallContainer.add_child(wall_multi_inst_ew_main)
	$WallContainer.add_child(wall_multi_inst_ns_main)
	$WallContainer.add_child(wall_multi_inst_ew_sub)
	$WallContainer.add_child(wall_multi_inst_ns_sub)

	for y in tower_setting.MazeSize.y:
		for x in tower_setting.MazeSize.x:
			if not maze_cells.is_open_dir_at(x,y,DirLib.Flag.North):
				add_wall_at( x , y , DirLib.Flag.North)
			if not maze_cells.is_open_dir_at(x,y,DirLib.Flag.West):
				add_wall_at( x , y , DirLib.Flag.West)

	for x in tower_setting.MazeSize.x :
		if not maze_cells.is_open_dir_at(x,tower_setting.MazeSize.y-1,DirLib.Flag.South):
			add_wall_at( x , tower_setting.MazeSize.y , DirLib.Flag.South)

	for y in tower_setting.MazeSize.y:
		if not maze_cells.is_open_dir_at(tower_setting.MazeSize.x-1,y,DirLib.Flag.East):
			add_wall_at( tower_setting.MazeSize.x , y , DirLib.Flag.East)

	pos_multimesh(wall_multi_inst_ew_main.multimesh, pos_list_ew_main)
	pos_multimesh(wall_multi_inst_ns_main.multimesh, pos_list_ns_main)
	pos_multimesh(wall_multi_inst_ew_sub.multimesh, pos_list_ew_sub)
	pos_multimesh(wall_multi_inst_ns_sub.multimesh, pos_list_ns_sub)

func add_wall_at(x :int, y :int, dir :DirLib.Flag) -> void:
	var pos_face_ew = Vector3( x *tower_setting.LaneW, tower_setting.StoryH/2.0, y *tower_setting.LaneW +tower_setting.LaneW/2)
	var pos_face_ns = Vector3( x *tower_setting.LaneW +tower_setting.LaneW/2, tower_setting.StoryH/2.0, y *tower_setting.LaneW)

	if randf() < tower_setting.MakeLine2DWallRate:
		if line2d_subviewport == null:
			line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
		match dir:
			DirLib.Flag.West, DirLib.Flag.East:
				var b = make_box_from_subviewport(line2d_subviewport, tower_setting.WallSize_EW_Reduced)
				b.position = pos_face_ew
			DirLib.Flag.North, DirLib.Flag.South:
				var b = make_box_from_subviewport(line2d_subviewport, tower_setting.WallSize_NS_Reduced)
				b.position = pos_face_ns
		return

	match dir:
		DirLib.Flag.West, DirLib.Flag.East:
			if randf() < tower_setting.MakeSubWallRate:
				pos_list_ew_sub.append(pos_face_ew)
			else:
				pos_list_ew_main.append(pos_face_ew)
		DirLib.Flag.North, DirLib.Flag.South:
			if randf() < tower_setting.MakeSubWallRate:
				pos_list_ns_sub.append(pos_face_ns)
			else:
				pos_list_ns_main.append(pos_face_ns)

	# add clock or calendar
	if randf() < tower_setting.MakeClockCalWallRate:
		var n :Node3D
		var depth = 0.1
		clockcalendar_sel +=1
		if clockcalendar_sel % 2 == 0:
			n = calendar_scene.instantiate()
			n.init(tower_setting.LaneW, tower_setting.StoryH,depth, 5, false)
		else :
			n = clock_scene.instantiate()
			n.init(min(tower_setting.LaneW,tower_setting.StoryH)/2,depth, 4, 9.0, false)
		n.rotate_z(PI/2)
		n.rotate_y(DirLib.dir2rad(1+DirLib.Flag2Dir[dir]))
		add_child(n)
		match dir:
			DirLib.Flag.West:
				n.position = pos_face_ew + Vector3(tower_setting.WallThick,0,0)
			DirLib.Flag.East:
				n.position = pos_face_ew - Vector3(tower_setting.WallThick,0,0)
			DirLib.Flag.North:
				n.position = pos_face_ns + Vector3(0,0,tower_setting.WallThick)
			DirLib.Flag.South:
				n.position = pos_face_ns - Vector3(0,0,tower_setting.WallThick)


func make_line2d_subvuewport(size_pixel:Vector2i) -> SubViewport:
	#print_debug(size_pixel)
	var l2d = line2d_scene.instantiate().init_with_random(300,4,1.5,size_pixel)
	l2d.start()
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
	return Vector3(tower_setting.LaneW/2+ mp.x*tower_setting.LaneW, y, tower_setting.LaneW/2+ mp.y*tower_setting.LaneW)

func view_floor_ceiling(f :bool,c :bool) -> void:
	$Floor.visible = f
	$Ceiling.visible = c

func view_walls(w :bool) -> void:
	$WallContainer.visible = w

func view_pillars(w :bool) -> void:
	$PillarContainer.visible = w

func is_goal_pos(p :Vector2i) -> bool:
	return goal_pos == p
