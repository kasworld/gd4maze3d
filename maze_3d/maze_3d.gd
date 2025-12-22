extends Node3D
class_name Maze3D

static var darkcolorlist = NamedColorList.make_dark_color_list()
static var lightcolorlist = NamedColorList.make_light_color_list()

enum WallView {Reduced, Full, Off}
static func wallview2str(vd :WallView) -> String:
	return WallView.keys()[vd]
static func wallview_next(a :WallView) -> WallView:
	return (a +1) % WallView.keys().size() as WallView

var maze3d_setting :Maze3DSetting
var maze_cells :Maze
var main_wall_mat :StandardMaterial3D
var sub_wall_mat :StandardMaterial3D
var pillar_mat :StandardMaterial3D

func _to_string() -> String:
	return "Maze3D[%s]" % [maze3d_setting]

func init_with_mat(ts :Maze3DSetting, makedecofn :Callable, matmain :StandardMaterial3D, matsub :StandardMaterial3D) -> Maze3D:
	maze3d_setting = ts
	sub_wall_mat = matsub
	main_wall_mat = matmain
	pillar_mat = main_wall_mat.duplicate()
	pillar_mat.uv1_scale = Vector3( 3.0/20, 2, 1)
	maze_cells = Maze.new(maze3d_setting.MazeSize)
	make_wall_by_maze()
	make_box_pillas()
	make_wall_deco_by_maze(makedecofn)
	init_floor_ceiling()
	return self

func init_with_color(ts :Maze3DSetting, makedecofn :Callable, comain :Color, cosub :Color, copillar :Color) -> Maze3D:
	maze3d_setting = ts
	sub_wall_mat = StandardMaterial3D.new()
	sub_wall_mat.albedo_color = Color( cosub, 0.5)
	sub_wall_mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	main_wall_mat = StandardMaterial3D.new()
	main_wall_mat.albedo_color = comain
	pillar_mat = StandardMaterial3D.new()
	pillar_mat.albedo_color = copillar
	maze_cells = Maze.new(maze3d_setting.MazeSize)
	make_wall_by_maze()
	make_capsule_pillas()
	make_wall_deco_by_maze(makedecofn)
	init_floor_ceiling()
	return self

func init_floor_ceiling() -> void:
	var wire_r := maze3d_setting.WallThick * 0.5
	var net_size := maze3d_setting.CalcSizeWithWallV2() - Vector2(wire_r,wire_r)
	$Floor.init_wire_net(net_size, maze3d_setting.MazeSize*2, wire_r, darkcolorlist.pick_random()[0])
	$Ceiling.init_wire_net(net_size, maze3d_setting.MazeSize*2, wire_r, lightcolorlist.pick_random()[0])
	$Floor.position.y -= maze3d_setting.StoryH/2
	$Ceiling.position.y += maze3d_setting.StoryH/2
	var shiftsize := maze3d_setting.CalcSizeV3()/2
	$WallContainer.position = -shiftsize
	$PillarContainer.position = -shiftsize

func make_box_pillas() -> void:
	var pos_list :Array = []
	for y in maze3d_setting.MazeSize.y+1:
		for x in maze3d_setting.MazeSize.x+1:
			pos_list.append(Vector3( x *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0, y *maze3d_setting.LaneW) )
	var mesh := BoxMesh.new()
	mesh.size = Vector3(maze3d_setting.WallThick,maze3d_setting.StoryH,maze3d_setting.WallThick)
	var rtn : MultiMeshShape = preload("res://multi_mesh_shape/multi_mesh_shape.tscn").instantiate(
		).init_with_material(mesh, pillar_mat, pos_list.size())
	pos_multimeshshape(rtn, pos_list)
	$PillarContainer.add_child(rtn)

func make_capsule_pillas() -> void:
	var pos_list :Array = []
	for y in maze3d_setting.MazeSize.y+1:
		for x in maze3d_setting.MazeSize.x+1:
			pos_list.append(Vector3( x *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0, y *maze3d_setting.LaneW) )
	var mesh := CapsuleMesh.new()
	mesh.radius = maze3d_setting.WallThick/2
	mesh.height = maze3d_setting.StoryH
	var rtn : MultiMeshShape = preload("res://multi_mesh_shape/multi_mesh_shape.tscn").instantiate(
		).init_with_material(mesh, pillar_mat, pos_list.size())
	pos_multimeshshape(rtn, pos_list)
	$PillarContainer.add_child(rtn)

func pos_multimeshshape(mms :MultiMeshShape, pos_list :Array) -> void:
	for i in pos_list.size():
		var t := Transform3D(Basis(), pos_list[i])
		mms.multimesh.set_instance_transform(i,t)

func make_wall_multi_shape(mat :Material, sz :Vector3, pos_list :Array) -> MultiMeshShape:
	var mesh := BoxMesh.new()
	mesh.size = sz
	var rtn : MultiMeshShape = preload("res://multi_mesh_shape/multi_mesh_shape.tscn").instantiate(
		).init_with_material(mesh, mat, pos_list.size())
	pos_multimeshshape(rtn, pos_list)
	$WallContainer.add_child(rtn)
	return rtn

var wall_multi_inst_ew_main :MultiMeshShape
var wall_multi_inst_ns_main :MultiMeshShape
var wall_multi_inst_ew_sub :MultiMeshShape
var wall_multi_inst_ns_sub :MultiMeshShape
var pos_list_ew_main :Array
var pos_list_ns_main :Array
var pos_list_ew_sub :Array
var pos_list_ns_sub :Array
func make_wall_by_maze() -> void:
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

	wall_multi_inst_ew_main = make_wall_multi_shape(main_wall_mat, maze3d_setting.CalcWallSize_EW_Reduced(), pos_list_ew_main)
	wall_multi_inst_ns_main = make_wall_multi_shape(main_wall_mat, maze3d_setting.CalcWallSize_NS_Reduced(), pos_list_ns_main)
	wall_multi_inst_ew_sub = make_wall_multi_shape(sub_wall_mat, maze3d_setting.CalcWallSize_EW_Reduced(), pos_list_ew_sub)
	wall_multi_inst_ns_sub = make_wall_multi_shape(sub_wall_mat, maze3d_setting.CalcWallSize_NS_Reduced(), pos_list_ns_sub)

func add_wall_at(x :int, y :int, dir :EnumDir.Flag) -> void:
	var pos_face_ew := Vector3( x *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0, y *maze3d_setting.LaneW +maze3d_setting.LaneW/2)
	var pos_face_ns := Vector3( x *maze3d_setting.LaneW +maze3d_setting.LaneW/2, maze3d_setting.StoryH/2.0, y *maze3d_setting.LaneW)

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

func make_wall_deco_by_maze(makedeco :Callable) -> void:
	if not makedeco.is_valid():
		return

	for y in maze3d_setting.MazeSize.y:
		for x in maze3d_setting.MazeSize.x:
			if not maze_cells.is_open_dir_at(x,y,EnumDir.Flag.North):
				makedeco.call( x , y , EnumDir.Flag.North)
			if not maze_cells.is_open_dir_at(x,y,EnumDir.Flag.West):
				makedeco.call( x , y , EnumDir.Flag.West)

	for x in maze3d_setting.MazeSize.x :
		if not maze_cells.is_open_dir_at(x,maze3d_setting.MazeSize.y-1,EnumDir.Flag.South):
			makedeco.call( x , maze3d_setting.MazeSize.y , EnumDir.Flag.South)

	for y in maze3d_setting.MazeSize.y:
		if not maze_cells.is_open_dir_at(maze3d_setting.MazeSize.x-1,y,EnumDir.Flag.East):
			makedeco.call( maze3d_setting.MazeSize.x , y , EnumDir.Flag.East)

func deco_pos_by_dir(x :int, y :int, dir :EnumDir.Flag) -> Vector3:
	var pos_face_ew := Vector3( x *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0, y *maze3d_setting.LaneW +maze3d_setting.LaneW/2)
	var pos_face_ns := Vector3( x *maze3d_setting.LaneW +maze3d_setting.LaneW/2, maze3d_setting.StoryH/2.0, y *maze3d_setting.LaneW)
	var pos :Vector3
	match dir:
		EnumDir.Flag.West:
			pos =  pos_face_ew + Vector3(maze3d_setting.WallThick,0,0)
		EnumDir.Flag.East:
			pos =  pos_face_ew - Vector3(maze3d_setting.WallThick,0,0)
		EnumDir.Flag.North:
			pos =  pos_face_ns + Vector3(0,0,maze3d_setting.WallThick)
		EnumDir.Flag.South:
			pos =  pos_face_ns - Vector3(0,0,maze3d_setting.WallThick)
	return pos

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
