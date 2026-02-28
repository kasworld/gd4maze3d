extends Node3D
class_name Maze3D

static var darkcolorlist = NamedColors.filter_dark_color_list()
static var lightcolorlist = NamedColors.filter_light_color_list()


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
	make_capsule_pillas()
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
	make_box_pillas()
	make_capsule_pillas()
	make_wall_deco_by_maze(makedecofn)
	init_floor_ceiling()
	return self

func init_floor_ceiling() -> void:
	var wire_r := maze3d_setting.WallThick * 0.5
	var net_size := maze3d_setting.CalcSizeWithWallV2() - Vector2(wire_r,wire_r)
	$Floor.init_wire_net(net_size, maze3d_setting.MazeSize*2, wire_r, darkcolorlist.pick_random())
	$Ceiling.init_wire_net(net_size, maze3d_setting.MazeSize*2, wire_r, lightcolorlist.pick_random())
	$Floor.position.z -= maze3d_setting.StoryH/2
	$Ceiling.position.z += maze3d_setting.StoryH/2
	var shiftsize := maze3d_setting.CalcSizeV3()/2
	$WallContainer.position = -shiftsize
	$CapsulePillars.position = -shiftsize
	$BoxPillars.position = -shiftsize

func make_box_pillas() -> void:
	var pos_list :Array = []
	for y in maze3d_setting.MazeSize.y+1:
		for x in maze3d_setting.MazeSize.x+1:
			pos_list.append(Vector3( x *maze3d_setting.LaneW, y *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0) )
	var mesh := BoxMesh.new()
	mesh.material = pillar_mat
	mesh.size = maze3d_setting.PillarSize()
	var rtn : MultiMeshShape = preload("res://multi_mesh_shape/multi_mesh_shape.tscn").instantiate(
		).init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape(rtn, pos_list)
	$BoxPillars.add_child(rtn)

func make_capsule_pillas() -> void:
	var pos_list :Array = []
	for y in maze3d_setting.MazeSize.y+1:
		for x in maze3d_setting.MazeSize.x+1:
			pos_list.append(Vector3( x *maze3d_setting.LaneW, y *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0) )
	var mesh := CapsuleMesh.new()
	mesh.material = pillar_mat
	mesh.radius = maze3d_setting.WallThick/2
	mesh.height = maze3d_setting.StoryH
	var rtn : MultiMeshShape = preload("res://multi_mesh_shape/multi_mesh_shape.tscn").instantiate(
		).init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape_capsule(rtn, pos_list)
	$CapsulePillars.add_child(rtn)

func pos_multimeshshape_capsule(mms :MultiMeshShape, pos_list :Array) -> void:
	for i in pos_list.size():
		var t := Transform3D(Basis(), pos_list[i])
		t = t.rotated_local(Vector3.LEFT, PI/2)
		mms.multimesh.set_instance_transform(i,t)

func pos_multimeshshape(mms :MultiMeshShape, pos_list :Array) -> void:
	for i in pos_list.size():
		var t := Transform3D(Basis(), pos_list[i])
		mms.multimesh.set_instance_transform(i,t)

func make_wall_multi_shape(mat :Material, sz :Vector3, pos_list :Array) -> MultiMeshShape:
	var mesh := BoxMesh.new()
	mesh.size = sz
	mesh.material = mat
	var rtn : MultiMeshShape = preload("res://multi_mesh_shape/multi_mesh_shape.tscn").instantiate(
		).init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape(rtn, pos_list)
	$WallContainer.add_child(rtn)
	return rtn

var wall_multi_inst_V_main :MultiMeshShape
var wall_multi_inst_H_main :MultiMeshShape
var wall_multi_inst_V_sub :MultiMeshShape
var wall_multi_inst_H_sub :MultiMeshShape
var pos_list_V_main :Array
var pos_list_H_main :Array
var pos_list_V_sub :Array
var pos_list_H_sub :Array
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

	wall_multi_inst_V_main = make_wall_multi_shape(main_wall_mat, maze3d_setting.CalcWallSize_V_Short(), pos_list_V_main)
	wall_multi_inst_H_main = make_wall_multi_shape(main_wall_mat, maze3d_setting.CalcWallSize_H_Short(), pos_list_H_main)
	wall_multi_inst_V_sub = make_wall_multi_shape(sub_wall_mat, maze3d_setting.CalcWallSize_V_Short(), pos_list_V_sub)
	wall_multi_inst_H_sub = make_wall_multi_shape(sub_wall_mat, maze3d_setting.CalcWallSize_H_Short(), pos_list_H_sub)

func add_wall_at(x :int, y :int, dir :EnumDir.Flag) -> void:
	var pos_face_V := Vector3( x *maze3d_setting.LaneW, y *maze3d_setting.LaneW +maze3d_setting.LaneW/2, maze3d_setting.StoryH/2.0)
	var pos_face_H := Vector3( x *maze3d_setting.LaneW +maze3d_setting.LaneW/2, y *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0)

	match dir:
		EnumDir.Flag.West, EnumDir.Flag.East:
			if randf() < maze3d_setting.MakeSubWallRate:
				pos_list_V_sub.append(pos_face_V)
			else:
				pos_list_V_main.append(pos_face_V)
		EnumDir.Flag.North, EnumDir.Flag.South:
			if randf() < maze3d_setting.MakeSubWallRate:
				pos_list_H_sub.append(pos_face_H)
			else:
				pos_list_H_main.append(pos_face_H)

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
	var pos_face_V := Vector3( x *maze3d_setting.LaneW, y *maze3d_setting.LaneW +maze3d_setting.LaneW/2, maze3d_setting.StoryH/2.0)
	var pos_face_H := Vector3( x *maze3d_setting.LaneW +maze3d_setting.LaneW/2, y *maze3d_setting.LaneW, maze3d_setting.StoryH/2.0)
	var pos :Vector3
	match dir:
		EnumDir.Flag.West:
			pos =  pos_face_V + Vector3(maze3d_setting.WallThick,0,0)
		EnumDir.Flag.East:
			pos =  pos_face_V - Vector3(maze3d_setting.WallThick,0,0)
		EnumDir.Flag.North:
			pos =  pos_face_H + Vector3(0,maze3d_setting.WallThick,0)
		EnumDir.Flag.South:
			pos =  pos_face_H - Vector3(0,maze3d_setting.WallThick,0)
	return pos


enum FloorCeiling {Off, Floor, Ceiling, Both}
func view_floor_ceiling(v :FloorCeiling) -> void:
	match v:
		FloorCeiling.Off:
			$Floor.visible = false
			$Ceiling.visible = false
		FloorCeiling.Floor:
			$Floor.visible = true
			$Ceiling.visible = false
		FloorCeiling.Ceiling:
			$Floor.visible = false
			$Ceiling.visible = true
		FloorCeiling.Both:
			$Floor.visible = true
			$Ceiling.visible = true

func set_wall_size_long(b :bool) -> void:
	if b:
		wall_multi_inst_H_main.multimesh.mesh.size = maze3d_setting.CalcWallSize_H_Long()
		wall_multi_inst_H_sub.multimesh.mesh.size = maze3d_setting.CalcWallSize_H_Long()
		wall_multi_inst_V_main.multimesh.mesh.size = maze3d_setting.CalcWallSize_V_Long()
		wall_multi_inst_V_sub.multimesh.mesh.size = maze3d_setting.CalcWallSize_V_Long()
	else:
		wall_multi_inst_H_main.multimesh.mesh.size = maze3d_setting.CalcWallSize_H_Short()
		wall_multi_inst_H_sub.multimesh.mesh.size = maze3d_setting.CalcWallSize_H_Short()
		wall_multi_inst_V_main.multimesh.mesh.size = maze3d_setting.CalcWallSize_V_Short()
		wall_multi_inst_V_sub.multimesh.mesh.size = maze3d_setting.CalcWallSize_V_Short()

enum WallView {Off, Short, Long}
func view_walls(v :WallView) -> void:
	match v:
		WallView.Off:
			$WallContainer.visible = false
		WallView.Short:
			$WallContainer.visible = true
			set_wall_size_long(false)
		WallView.Long:
			$WallContainer.visible = true
			set_wall_size_long(true)

enum PillarView {Off, Box, Capsule}
func view_pillars(v :PillarView) -> void:
	match v:
		PillarView.Off:
			$CapsulePillars.visible = false
			$BoxPillars.visible = false
		PillarView.Box:
			$CapsulePillars.visible = false
			$BoxPillars.visible = true
		PillarView.Capsule:
			$CapsulePillars.visible = true
			$BoxPillars.visible = false

enum WallPillarView {Long, Short, ShortWithPillarBox, ShortWithPillarCapsule, Off, OffWithPillarBox, OffWithPillarCapsule}
static func wallview2str(vd :WallPillarView) -> String:
	return WallPillarView.keys()[vd]
static func wallview_next(a :WallPillarView) -> WallPillarView:
	return (a +1) % WallPillarView.keys().size() as WallPillarView

func set_wallpillar_view_mode(w :WallPillarView) -> void:
	match w:
		WallPillarView.Long:
			view_walls(WallView.Long)
			set_wall_size_long(true)
			view_pillars(PillarView.Off)
		WallPillarView.Short:
			view_walls(WallView.Short)
			set_wall_size_long(false)
			view_pillars(PillarView.Off)
		WallPillarView.ShortWithPillarBox:
			view_walls(WallView.Short)
			set_wall_size_long(false)
			view_pillars(PillarView.Box)
		WallPillarView.ShortWithPillarCapsule:
			view_walls(WallView.Short)
			set_wall_size_long(false)
			view_pillars(PillarView.Capsule)
		WallPillarView.Off:
			view_walls(WallView.Off)
			view_pillars(PillarView.Off)
		WallPillarView.OffWithPillarBox:
			view_walls(WallView.Off)
			view_pillars(PillarView.Box)
		WallPillarView.OffWithPillarCapsule:
			view_walls(WallView.Off)
			view_pillars(PillarView.Capsule)

var bounce_wall_info_all :Array
# wallinfo [aabb , axis_wall [3][2]bool ]
func make_bounce_wall_info() -> void:
	var cell_size := maze3d_setting.CellSize()
	var maze_size_half := maze3d_setting.CalcSizeV3()/2
	bounce_wall_info_all = []
	bounce_wall_info_all.resize(maze3d_setting.MazeSize.y)
	for y in maze3d_setting.MazeSize.y:
		bounce_wall_info_all[y] = []
		bounce_wall_info_all[y].resize(maze3d_setting.MazeSize.x)
		for x in maze3d_setting.MazeSize.x:
			bounce_wall_info_all[y][x] = [
				AABB(
					Vector3(maze3d_setting.LaneW*x, maze3d_setting.LaneW*y, 0) -maze_size_half,
					cell_size), # AABB
				make_wallinfo_for_bounce(x,y), # axis_wall [3:xyz][2]bool
			]
func bounce_cell(oldpos:Vector3, pos :Vector3, radius :float) -> Dictionary:
	var pos2d := maze3d_setting.storeypos2mazepos(oldpos)
	var wallinfo :Array = bounce_wall_info_all[pos2d.y][pos2d.x]
	var aabb :AABB = wallinfo[0]
	var axis_wall :Array = wallinfo[1]
	return Bounce.v3f_wall(pos, aabb, axis_wall, radius)

# wall [axis:3][2]bool : [ [-x,+x], [-y,+y], [-z,+z] ]
func make_wallinfo_for_bounce(x:int, y:int) -> Array[Array]:
	return [
		[maze_cells.is_wall_dir_at(x,y, EnumDir.Flag.West), maze_cells.is_wall_dir_at(x,y, EnumDir.Flag.East)],
		[maze_cells.is_wall_dir_at(x,y, EnumDir.Flag.North), maze_cells.is_wall_dir_at(x,y, EnumDir.Flag.South)],
		[true,true],
	]
