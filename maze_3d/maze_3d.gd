extends Node3D
class_name Maze3D

static var darkcolorlist = NamedColorList.make_dark_color_list()
static var lightcolorlist = NamedColorList.make_light_color_list()

var wall_tex_dict = {
	brownbrick = preload("res://image/brownbrick50.png"),
	bluestone = preload("res://image/bluestone50.png"),
	drymud = preload("res://image/drymud50.png"),
	graystone = preload("res://image/graystone50.png"),
	pinkstone = preload("res://image/pinkstone50.png"),
	greenstone = preload("res://image/greenstone50.png"),
	ice50 = preload("res://image/ice50.png")
}

var wall_mat_dict = {
	aluminium = preload("res://test_materials/aluminium.tres"),
	#blue = preload("res://test_materials/blue.tres"),
	brick = preload("res://test_materials/brick.tres"),
	cheese = preload("res://test_materials/cheese.tres"),
	darkwood = preload("res://test_materials/dark_wood.tres"),
	#gray = preload("res://test_materials/gray.tres"),
	#ice = preload("res://test_materials/ice.tres"),
	marble = preload("res://test_materials/marble.tres"),
	#mirror = preload("res://test_materials/mirror.tres"),
	rock = preload("res://test_materials/rock.tres"),
	stones = preload("res://test_materials/stones.tres"),
	#toon = preload("res://test_materials/toon.tres"),
	wetsand = preload("res://test_materials/wet_sand.tres"),
	#white = preload("res://test_materials/white.tres"),
	#whiteplastic = preload("res://test_materials/white_plastic.tres"),
	wool = preload("res://test_materials/wool.tres"),
}

enum WallView {Reduced, Full, Off}
static func wallview2str(vd :WallView) -> String:
	return WallView.keys()[vd]
static func wallview_next(a :WallView) -> WallView:
	return (a +1) % WallView.keys().size() as WallView

var maze3d_setting :Maze3DSetting
var maze_cells :Maze
var main_wall_mat :StandardMaterial3D
var main_wall_mat_name :String
var sub_wall_mat :StandardMaterial3D
var sub_wall_tex_name :String
var pillar_mat :StandardMaterial3D
var line2d_subviewport :SubViewport
var clockcalendar_sel :int

func _to_string() -> String:
	return "Maze3D[mainwall:%s subwall:%s
	%s]" % [main_wall_mat_name, sub_wall_tex_name]

func init(ts :Maze3DSetting) -> Maze3D:
	maze3d_setting = ts
	#make_wall_texmat()
	make_wall_color_texmat()
	pillar_mat = main_wall_mat.duplicate()
	pillar_mat.uv1_scale = Vector3( 3.0/20, 2, 1)

	$Floor.init_with_color(maze3d_setting.CalcMeshSize(), maze3d_setting.CalcMeshSize()*2, 
		0.01, darkcolorlist.pick_random()[0])
	$Floor.position = Vector3(0, 0 ,0)
	$Ceiling.init_with_color(maze3d_setting.CalcMeshSize(), maze3d_setting.CalcMeshSize()*2, 
		0.01, lightcolorlist.pick_random()[0])
	$Ceiling.position = Vector3(0, maze3d_setting.StoryH  ,0)

	maze_cells = Maze.new(maze3d_setting.MazeSize)
	make_wall_by_maze()
	make_pillas()
	return self

func make_wall_color_texmat() -> void:
	sub_wall_mat = StandardMaterial3D.new()
	sub_wall_mat.albedo_color = Color( darkcolorlist.pick_random()[0], 0.5)
	sub_wall_mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA

	main_wall_mat = StandardMaterial3D.new()
	main_wall_mat.albedo_color = lightcolorlist.pick_random()[0]
	
	
func make_wall_texmat() -> void:
	var tex_keys = wall_tex_dict.keys()
	tex_keys.shuffle()
	sub_wall_tex_name = tex_keys[0]
	sub_wall_mat = StandardMaterial3D.new()
	sub_wall_mat.albedo_texture = wall_tex_dict[sub_wall_tex_name]
	sub_wall_mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	sub_wall_mat.uv1_scale = Vector3(3, 2, 1)
	#sub_wall_mat.uv1_scale = Vector3(maze3d_setting.LaneW/2, maze3d_setting.StoryH/2, 1)
	
	var mat_keys = wall_mat_dict.keys()
	mat_keys.shuffle()
	main_wall_mat_name = mat_keys[0]
	main_wall_mat = wall_mat_dict[main_wall_mat_name]
	main_wall_mat.uv1_scale = Vector3(3, 2, 1)
	#main_wall_mat.uv1_scale = Vector3(maze3d_setting.LaneW/2, maze3d_setting.StoryH/2, 1)
	

func make_pillas() -> void:
	var multi_inst = make_box_multi_inst(pillar_mat, Vector3(maze3d_setting.WallThick,maze3d_setting.StoryH,maze3d_setting.WallThick) )
	$PillarContainer.add_child(multi_inst)
	var pos_list :Array = []
	for y in maze3d_setting.MazeSize.y+1:
		for x in maze3d_setting.MazeSize.x+1:
			pos_list.append(Vector3( x *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0, y *maze3d_setting.LaneW) )
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
	wall_multi_inst_ew_main = make_box_multi_inst(main_wall_mat, maze3d_setting.CalcWallSize_EW_Reduced())
	wall_multi_inst_ns_main = make_box_multi_inst(main_wall_mat, maze3d_setting.CalcWallSize_NS_Reduced())
	wall_multi_inst_ew_sub = make_box_multi_inst(sub_wall_mat, maze3d_setting.CalcWallSize_EW_Reduced())
	wall_multi_inst_ns_sub = make_box_multi_inst(sub_wall_mat, maze3d_setting.CalcWallSize_NS_Reduced())
	$WallContainer.add_child(wall_multi_inst_ew_main)
	$WallContainer.add_child(wall_multi_inst_ns_main)
	$WallContainer.add_child(wall_multi_inst_ew_sub)
	$WallContainer.add_child(wall_multi_inst_ns_sub)

	for y in maze3d_setting.MazeSize.y:
		for x in maze3d_setting.MazeSize.x:
			if not maze_cells.is_open_dir_at(x,y,EnumDir.Flag.North):
				add_wall_at( x , y , EnumDir.Flag.North)
			if not maze_cells.is_open_dir_at(x,y,EnumDir.Flag.West):
				add_wall_at( x , y , EnumDir.Flag.West)

	for x in maze3d_setting.MazeSize.x :
		if not maze_cells.is_open_dir_at(x,maze3d_setting.MazeSize.y-1,EnumDir.Flag.South):
			add_wall_at( x , maze3d_setting.MazeSize.y , EnumDir.Flag.South)

	for y in maze3d_setting.MazeSize.y:
		if not maze_cells.is_open_dir_at(maze3d_setting.MazeSize.x-1,y,EnumDir.Flag.East):
			add_wall_at( maze3d_setting.MazeSize.x , y , EnumDir.Flag.East)

	pos_multimesh(wall_multi_inst_ew_main.multimesh, pos_list_ew_main)
	pos_multimesh(wall_multi_inst_ns_main.multimesh, pos_list_ns_main)
	pos_multimesh(wall_multi_inst_ew_sub.multimesh, pos_list_ew_sub)
	pos_multimesh(wall_multi_inst_ns_sub.multimesh, pos_list_ns_sub)

func add_wall_at(x :int, y :int, dir :EnumDir.Flag) -> void:
	var pos_face_ew = Vector3( x *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0, y *maze3d_setting.LaneW +maze3d_setting.LaneW/2)
	var pos_face_ns = Vector3( x *maze3d_setting.LaneW +maze3d_setting.LaneW/2, maze3d_setting.StoryH/2.0, y *maze3d_setting.LaneW)

	if randf() < maze3d_setting.MakeLine2DWallRate:
		if line2d_subviewport == null:
			line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
		match dir:
			EnumDir.Flag.West, EnumDir.Flag.East:
				var b = make_box_from_subviewport(line2d_subviewport, maze3d_setting.CalcWallSize_EW_Reduced())
				b.position = pos_face_ew
			EnumDir.Flag.North, EnumDir.Flag.South:
				var b = make_box_from_subviewport(line2d_subviewport, maze3d_setting.CalcWallSize_NS_Reduced())
				b.position = pos_face_ns
		return

	match dir:
		EnumDir.Flag.West, EnumDir.Flag.East:
			if randf() < maze3d_setting.MakeSubWallRate:
				pos_list_ew_sub.append(pos_face_ew)
			else:
				pos_list_ew_main.append(pos_face_ew)
		EnumDir.Flag.North, EnumDir.Flag.South:
			if randf() < maze3d_setting.MakeSubWallRate:
				pos_list_ns_sub.append(pos_face_ns)
			else:
				pos_list_ns_main.append(pos_face_ns)

	# add clock or calendar
	if randf() < maze3d_setting.MakeClockCalWallRate:
		var n :Node3D
		var depth = 0.1
		clockcalendar_sel +=1
		if clockcalendar_sel % 2 == 0:
			n = preload("res://calendar3d/calendar_3d.tscn").instantiate()
			n.init(maze3d_setting.LaneW, maze3d_setting.StoryH,depth, 5, false)
		else :
			n = preload("res://analogclock3d/analog_clock_3d.tscn").instantiate()
			n.init(min(maze3d_setting.LaneW,maze3d_setting.StoryH)/2,depth, 4, 9.0, false)
		n.rotate_z(PI/2)
		n.rotate_y(EnumDir.dir2rad(1+EnumDir.Flag2Dir[dir]))
		add_child(n)
		match dir:
			EnumDir.Flag.West:
				n.position = pos_face_ew + Vector3(maze3d_setting.WallThick,0,0)
			EnumDir.Flag.East:
				n.position = pos_face_ew - Vector3(maze3d_setting.WallThick,0,0)
			EnumDir.Flag.North:
				n.position = pos_face_ns + Vector3(0,0,maze3d_setting.WallThick)
			EnumDir.Flag.South:
				n.position = pos_face_ns - Vector3(0,0,maze3d_setting.WallThick)

func make_line2d_subvuewport(size_pixel:Vector2i) -> SubViewport:
	#print_debug(size_pixel)
	var l2d = preload("res://move_line2d/move_line_2d.tscn").instantiate().init_with_random(300,4,1.5,size_pixel)
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

func view_floor_ceiling(f :bool,c :bool) -> void:
	$Floor.visible = f
	$Ceiling.visible = c

func set_wall_size(full :bool) -> void:
	if full:
		wall_multi_inst_ns_main.multimesh.mesh.size = maze3d_setting.CalcWallSize_NS_Full()
		wall_multi_inst_ns_sub.multimesh.mesh.size = maze3d_setting.CalcWallSize_NS_Full()
		wall_multi_inst_ew_main.multimesh.mesh.size = maze3d_setting.CalcWallSize_EW_Full()
		wall_multi_inst_ew_sub.multimesh.mesh.size = maze3d_setting.CalcWallSize_EW_Full()
	else:
		wall_multi_inst_ns_main.multimesh.mesh.size = maze3d_setting.CalcWallSize_NS_Reduced()
		wall_multi_inst_ns_sub.multimesh.mesh.size = maze3d_setting.CalcWallSize_NS_Reduced()
		wall_multi_inst_ew_main.multimesh.mesh.size = maze3d_setting.CalcWallSize_EW_Reduced()
		wall_multi_inst_ew_sub.multimesh.mesh.size = maze3d_setting.CalcWallSize_EW_Reduced()

func view_walls(w :bool) -> void:
	$WallContainer.visible = w

func view_pillars(w :bool) -> void:
	$PillarContainer.visible = w

func set_wallview_mode(w :WallView) -> void:
	match w:
		WallView.Full:
			view_walls(true)
			set_wall_size(true)
		WallView.Reduced:
			view_walls(true)
			set_wall_size(false)
		WallView.Off:
			view_walls(false)
