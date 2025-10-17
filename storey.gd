extends Node3D

class_name Storey

static var darkcolorlist = NamedColorList.make_dark_color_list()
static var lightcolorlist = NamedColorList.make_light_color_list()

var line2d_scene = preload("res://move_line2d/move_line_2d.tscn")
var tree_scene = preload("res://bar_tree_2/bar_tree_2.tscn")
var clock_scene = preload("res://analogclock3d/analog_clock_3d.tscn")
var calendar_scene = preload("res://calendar3d/calendar_3d.tscn")
var mesh_trail_scene = preload("res://mesh_trail/mesh_trail.tscn")
var donut_scene = preload("res://donut.tscn")
var capsule_scene = preload("res://capsule.tscn")
var text_mark_scene = preload("res://text_mark.tscn")

var storey_setting :StoreySetting
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

func get_center_pos() -> Vector3:
	return position + storey_setting.CalcCenterV3()

func _to_string() -> String:
	return "Storey[%d mainwall:%s subwall:%s
	%s]" % [storey_num, main_wall_mat_name, sub_wall_tex_name, storey_setting ]

func init(ts :StoreySetting, stn :int) -> Storey:
	storey_setting = ts
	storey_num = stn
	놓인것들 = PlacedThings.new(storey_setting.MazeSize)
	var tex_keys = Texmat.wall_tex_dict.keys()
	tex_keys.shuffle()
	sub_wall_tex_name = tex_keys[0]
	sub_wall_mat = StandardMaterial3D.new()
	sub_wall_mat.albedo_texture = Texmat.wall_tex_dict[sub_wall_tex_name]
	sub_wall_mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	sub_wall_mat.uv1_scale = Vector3(3, 2, 1)
	#sub_wall_mat.uv1_scale = Vector3(storey_setting.LaneW/2, storey_setting.StoryH/2, 1)

	var mat_keys = Texmat.wall_mat_dict.keys()
	mat_keys.shuffle()
	main_wall_mat_name = mat_keys[0]
	main_wall_mat = Texmat.wall_mat_dict[main_wall_mat_name]
	main_wall_mat.uv1_scale = Vector3(3, 2, 1)
	#main_wall_mat.uv1_scale = Vector3(storey_setting.LaneW/2, storey_setting.StoryH/2, 1)

	pillar_mat = main_wall_mat.duplicate()
	pillar_mat.uv1_scale = Vector3( 3.0/20, 2, 1)

	var wire_w = [0.01]
	$Floor.init_with_color(storey_setting.CalcMeshSize(), storey_setting.CalcMeshSize()*2, 
		wire_w.pick_random(), darkcolorlist.pick_random()[0],
		).rotate_x(PI/2)
	$Floor.position = Vector3(0, 0 ,0)
	$Ceiling.init_with_color(storey_setting.CalcMeshSize(), storey_setting.CalcMeshSize()*2, 
		wire_w.pick_random(), lightcolorlist.pick_random()[0],
		).rotate_x(PI/2)
	$Ceiling.position = Vector3(0, storey_setting.StoryH  ,0)

	maze_cells = Maze.new(storey_setting.MazeSize)
	make_wall_by_maze()
	make_pillas()

	wall_info_all = []
	for y in storey_setting.MazeSize.y:
		wall_info_all.append([])
		for x in storey_setting.MazeSize.x:
			wall_info_all[y].append( make_cell_wallinfo(x,y) )
			if maze_cells.get_open_dir_at(x,y).size() == 1:
				구석자리목록.append(Vector2i(x,y))

	start_pos = 구석자리목록.pick_random()
	var trycount := 100
	while trycount > 0:
		goal_pos = 구석자리목록.pick_random()
		if goal_pos != start_pos:
			break
		trycount -=1
	if goal_pos == start_pos:
		print_debug("start, goal pos same %s" % start_pos)
	var 크기기준 = storey_setting.LaneW
	$StartMark.init(크기기준*1.5, 크기기준/100, darkcolorlist.pick_random()[0], "Start %d" % storey_num
		).position = mazepos2storeypos(start_pos, storey_setting.StoryH/2.0)
	$EndMark.init(크기기준*1.5, 크기기준/100, lightcolorlist.pick_random()[0], "Goal %d" % storey_num
		).position = mazepos2storeypos(goal_pos, storey_setting.StoryH/2.0)
	놓인것들.set_at(start_pos, $StartMark)
	놓인것들.set_at(goal_pos, $EndMark)

	add_donut_capsule(storey_setting.DonutCapsuleCount)
	for i in storey_setting.TreeCount:
		var p = storey_setting.rand_pos_2i()
		if 놓인것들.get_at(p) != null:
			continue
		add_tree(p)
	add_ball_trails(storey_setting.MeshTrailTypeList)
	$Label3D.pixel_size = storey_setting.StoryH/50
	$Label3D.text = "%d" % storey_num
	$Label3D.position = Vector3(-storey_setting.WallThick, storey_setting.StoryH/2, -storey_setting.WallThick)
	#$Label3D.position = Vector3(storey_setting.CalcMeshSize().x, storey_setting.StoryH/2, storey_setting.CalcMeshSize().y)
	
	$MiniMap.init(self)
	return self

func chars_enter_storey(old_storey :Storey, char_list :Array, playernum :int) -> void:
	for ch in char_list:
		var stpos = storey_setting.rand_pos_2i()
		if ch.serial == playernum:
			stpos = start_pos
		ch.enter_storey(self, stpos)
	$MiniMap.add_chars(char_list, playernum)
	$MiniMap.update_size()
	if old_storey != null:
		$MiniMap.set_minimap_mod(old_storey.get_mini_map().minimap_mode)
		old_storey.get_mini_map().visible = false

func get_mini_map() -> MiniMap:
	return $MiniMap

func add_donut_capsule(n :int) -> void:
	for i in n:
		var p = 구석자리목록.pick_random()
		if 놓인것들.get_at(p) != null:
			continue
		var co = NamedColorList.color_list.pick_random()[0]
		var pobj
		var 크기기준 = min(storey_setting.LaneW, storey_setting.StoryH)
		if randi()%2 ==0:
			pobj = capsule_scene.instantiate().init(크기기준*0.3, 크기기준*0.05, co)
		else:
			pobj = donut_scene.instantiate().init(크기기준*0.07, 크기기준*0.15,co)
		pobj.position = mazepos2storeypos(p, storey_setting.StoryH/4.0)
		add_child(pobj)
		놓인것들.set_at(p,pobj)

func add_tree(p :Vector2i) ->void:
	var 크기기준 = min(storey_setting.LaneW, storey_setting.StoryH)
	var tree_width := randf_range(크기기준*0.5, 크기기준*0.9)
	var tree_height := randf_range(크기기준*0.5, 크기기준*0.9)
	var bar_width = randf_range(크기기준*0.5, 크기기준*0.9)/10
	var bar_count := randi_range(20,50)
	var bar_rotation := randfn(0,PI/40)
	var bar_rotation_begin := randf_range(0, 2*PI)
	var t :BarTree2	= tree_scene.instantiate().init_common_params(
		tree_width, tree_height, bar_width, bar_count, bar_rotation, bar_rotation_begin, 0, true,
	).init_with_color(random_color(), random_color())
	t.position = mazepos2storeypos(p, storey_setting.StoryH*0.1)
	add_child(t)
	놓인것들.set_at(p,t)

func random_color()->Color:
	#return Color(randf(),randf(),randf())
	return NamedColorList.color_list.pick_random()[0]

func add_ball_trails(mesh_type_list) ->void:
	var 크기기준 = min(storey_setting.LaneW, storey_setting.StoryH)
	var ba = AABB( Vector3(storey_setting.WallThick/2,0, storey_setting.WallThick/2),
		Vector3(storey_setting.CalcStoreySize().x -storey_setting.WallThick, storey_setting.StoryH, storey_setting.CalcStoreySize().y -storey_setting.WallThick) )
	for mt in mesh_type_list:
		if randf() > storey_setting.MakeMeshTrailRate:
			continue
		var pos = Vector3(
			randf_range(ba.position.x, ba.end.x),
			randf_range(ba.position.y, ba.end.y),
			randf_range(ba.position.z, ba.end.z),
		)
		var tc := randi_range(20,50)
		var bt = mesh_trail_scene.instantiate().init_MeshGradient().init(bounce_cell, 크기기준/20, tc, mt, pos).set_speed(1,4,0.05)
		add_child(bt)

func make_cell_wallinfo(x:int, y:int) -> Array:
	var axis_wall = [
		[maze_cells.is_wall_dir_at(x,y, EnumDir.Flag.West), maze_cells.is_wall_dir_at(x,y, EnumDir.Flag.East)],
		[true,true],
		[maze_cells.is_wall_dir_at(x,y, EnumDir.Flag.North), maze_cells.is_wall_dir_at(x,y, EnumDir.Flag.South)],
	]
	var aabb = AABB( Vector3(storey_setting.LaneW*x +storey_setting.WallThick/2, 0, storey_setting.LaneW*y +storey_setting.WallThick/2),
		Vector3(storey_setting.LaneW -storey_setting.WallThick, storey_setting.StoryH, storey_setting.LaneW -storey_setting.WallThick) )
	return [aabb, axis_wall]

# wallinfo [aabb , axis_wall [3][2]bool ]
func bounce_cell(oldpos:Vector3, pos :Vector3, radius :float) -> Dictionary:
	var x = clampi(int(oldpos.x/storey_setting.LaneW),0, storey_setting.MazeSize.x-1)
	var y = clampi(int(oldpos.z/storey_setting.LaneW),0, storey_setting.MazeSize.y-1)
	var wallinfo = wall_info_all[y][x]
	var aabb = wallinfo[0]
	var axis_wall = wallinfo[1]
	return Bounce.v3f_wall(pos, aabb, axis_wall,radius)

func make_pillas() -> void:
	var multi_inst = make_box_multi_inst(pillar_mat, Vector3(storey_setting.WallThick,storey_setting.StoryH,storey_setting.WallThick) )
	$PillarContainer.add_child(multi_inst)
	var pos_list :Array = []
	for y in storey_setting.MazeSize.y+1:
		for x in storey_setting.MazeSize.x+1:
			pos_list.append(Vector3( x *storey_setting.LaneW, storey_setting.StoryH/2.0, y *storey_setting.LaneW) )
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

var wall_multi_inst_ew_main :MultiMeshInstance3D
var wall_multi_inst_ns_main :MultiMeshInstance3D
var wall_multi_inst_ew_sub :MultiMeshInstance3D
var wall_multi_inst_ns_sub :MultiMeshInstance3D
var pos_list_ew_main :Array
var pos_list_ns_main :Array
var pos_list_ew_sub :Array
var pos_list_ns_sub :Array
func make_wall_by_maze() -> void:
	wall_multi_inst_ew_main = make_box_multi_inst(main_wall_mat, storey_setting.CalcWallSize_EW_Reduced())
	wall_multi_inst_ns_main = make_box_multi_inst(main_wall_mat, storey_setting.CalcWallSize_NS_Reduced())
	wall_multi_inst_ew_sub = make_box_multi_inst(sub_wall_mat, storey_setting.CalcWallSize_EW_Reduced())
	wall_multi_inst_ns_sub = make_box_multi_inst(sub_wall_mat, storey_setting.CalcWallSize_NS_Reduced())
	$WallContainer.add_child(wall_multi_inst_ew_main)
	$WallContainer.add_child(wall_multi_inst_ns_main)
	$WallContainer.add_child(wall_multi_inst_ew_sub)
	$WallContainer.add_child(wall_multi_inst_ns_sub)

	for y in storey_setting.MazeSize.y:
		for x in storey_setting.MazeSize.x:
			if not maze_cells.is_open_dir_at(x,y,EnumDir.Flag.North):
				add_wall_at( x , y , EnumDir.Flag.North)
			if not maze_cells.is_open_dir_at(x,y,EnumDir.Flag.West):
				add_wall_at( x , y , EnumDir.Flag.West)

	for x in storey_setting.MazeSize.x :
		if not maze_cells.is_open_dir_at(x,storey_setting.MazeSize.y-1,EnumDir.Flag.South):
			add_wall_at( x , storey_setting.MazeSize.y , EnumDir.Flag.South)

	for y in storey_setting.MazeSize.y:
		if not maze_cells.is_open_dir_at(storey_setting.MazeSize.x-1,y,EnumDir.Flag.East):
			add_wall_at( storey_setting.MazeSize.x , y , EnumDir.Flag.East)

	pos_multimesh(wall_multi_inst_ew_main.multimesh, pos_list_ew_main)
	pos_multimesh(wall_multi_inst_ns_main.multimesh, pos_list_ns_main)
	pos_multimesh(wall_multi_inst_ew_sub.multimesh, pos_list_ew_sub)
	pos_multimesh(wall_multi_inst_ns_sub.multimesh, pos_list_ns_sub)

func add_wall_at(x :int, y :int, dir :EnumDir.Flag) -> void:
	var pos_face_ew = Vector3( x *storey_setting.LaneW, storey_setting.StoryH/2.0, y *storey_setting.LaneW +storey_setting.LaneW/2)
	var pos_face_ns = Vector3( x *storey_setting.LaneW +storey_setting.LaneW/2, storey_setting.StoryH/2.0, y *storey_setting.LaneW)

	if randf() < storey_setting.MakeLine2DWallRate:
		if line2d_subviewport == null:
			line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
		match dir:
			EnumDir.Flag.West, EnumDir.Flag.East:
				var b = make_box_from_subviewport(line2d_subviewport, storey_setting.CalcWallSize_EW_Reduced())
				b.position = pos_face_ew
			EnumDir.Flag.North, EnumDir.Flag.South:
				var b = make_box_from_subviewport(line2d_subviewport, storey_setting.CalcWallSize_NS_Reduced())
				b.position = pos_face_ns
		return

	match dir:
		EnumDir.Flag.West, EnumDir.Flag.East:
			if randf() < storey_setting.MakeSubWallRate:
				pos_list_ew_sub.append(pos_face_ew)
			else:
				pos_list_ew_main.append(pos_face_ew)
		EnumDir.Flag.North, EnumDir.Flag.South:
			if randf() < storey_setting.MakeSubWallRate:
				pos_list_ns_sub.append(pos_face_ns)
			else:
				pos_list_ns_main.append(pos_face_ns)

	# add clock or calendar
	if randf() < storey_setting.MakeClockCalWallRate:
		var n :Node3D
		var depth = 0.1
		clockcalendar_sel +=1
		if clockcalendar_sel % 2 == 0:
			n = calendar_scene.instantiate()
			n.init(storey_setting.LaneW, storey_setting.StoryH,depth, 5, false)
		else :
			n = clock_scene.instantiate()
			n.init(min(storey_setting.LaneW,storey_setting.StoryH)/2,depth, 4, 9.0, false)
		n.rotate_z(PI/2)
		n.rotate_y(EnumDir.dir2rad(1+EnumDir.Flag2Dir[dir]))
		add_child(n)
		match dir:
			EnumDir.Flag.West:
				n.position = pos_face_ew + Vector3(storey_setting.WallThick,0,0)
			EnumDir.Flag.East:
				n.position = pos_face_ew - Vector3(storey_setting.WallThick,0,0)
			EnumDir.Flag.North:
				n.position = pos_face_ns + Vector3(0,0,storey_setting.WallThick)
			EnumDir.Flag.South:
				n.position = pos_face_ns - Vector3(0,0,storey_setting.WallThick)

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

func can_move(x :int , y :int, dir :EnumDir.Dir) -> bool:
	return maze_cells.is_open_dir_at(x,y, EnumDir.Dir2Flag[dir] )

func mazepos2storeypos( mp :Vector2i, y :float) -> Vector3:
	return Vector3(storey_setting.LaneW/2+ mp.x*storey_setting.LaneW, y, storey_setting.LaneW/2+ mp.y*storey_setting.LaneW)

func view_floor_ceiling(f :bool,c :bool) -> void:
	$Floor.visible = f
	$Ceiling.visible = c

func set_wall_size(full :bool) -> void:
	if full:
		wall_multi_inst_ns_main.multimesh.mesh.size = storey_setting.CalcWallSize_NS_Full()
		wall_multi_inst_ns_sub.multimesh.mesh.size = storey_setting.CalcWallSize_NS_Full()
		wall_multi_inst_ew_main.multimesh.mesh.size = storey_setting.CalcWallSize_EW_Full()
		wall_multi_inst_ew_sub.multimesh.mesh.size = storey_setting.CalcWallSize_EW_Full()
	else:
		wall_multi_inst_ns_main.multimesh.mesh.size = storey_setting.CalcWallSize_NS_Reduced()
		wall_multi_inst_ns_sub.multimesh.mesh.size = storey_setting.CalcWallSize_NS_Reduced()
		wall_multi_inst_ew_main.multimesh.mesh.size = storey_setting.CalcWallSize_EW_Reduced()
		wall_multi_inst_ew_sub.multimesh.mesh.size = storey_setting.CalcWallSize_EW_Reduced()

func view_walls(w :bool) -> void:
	$WallContainer.visible = w

func view_pillars(w :bool) -> void:
	$PillarContainer.visible = w

func is_goal_pos(p :Vector2i) -> bool:
	return goal_pos == p
