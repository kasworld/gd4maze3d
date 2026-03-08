extends Node3D
class_name Maze3D

static var darkcolorlist = NamedColors.filter_dark_color_list()
static var lightcolorlist = NamedColors.filter_light_color_list()

var WallThick :float
var MakeSubWallRate :float
var calc_grid :CalcGrid3D
var maze_cells :Maze

var main_wall_mat :StandardMaterial3D
var sub_wall_mat :StandardMaterial3D
var pillar_box_mat :StandardMaterial3D
var pillar_capsule_mat :StandardMaterial3D

func _to_string() -> String:
	return "Maze3D[calc_grid:%s wall thick:%.1f]" % [
		calc_grid, WallThick,
	]


var PreCalced := {}

func init_setting( grid_size :Vector2i, cell_size :Vector3, wall_thick :float, subwall_rate :float) -> Maze3D:
	WallThick = wall_thick
	MakeSubWallRate = subwall_rate

	var grid3d := CalcGrid3D.xz_Vector2iToVector3i(grid_size,1)
	var sz := cell_size * (grid3d as Vector3)
	calc_grid = CalcGrid3D.new(CalcGrid3D.SizeToAABB(sz), grid3d)
	maze_cells = Maze.new(grid_size)
	PreCalced.Grid2D = grid_size
	PreCalced.PillarSize = Vector3(wall_thick,cell_size.y,wall_thick)
	PreCalced.SizeV2 = (grid_size as Vector2) * Vector2(cell_size.x, cell_size.z)
	PreCalced.SizeV3 = calc_grid.boundary.size
	PreCalced.SizeWithWallV2 = PreCalced.SizeV2 + Vector2(wall_thick, wall_thick)
	PreCalced.SizeWithWallV3 = Vector3(PreCalced.SizeWithWallV2.x, cell_size.y, PreCalced.SizeWithWallV2.y)
	PreCalced.WallSize_H_Long = Vector3(cell_size.x, cell_size.y, wall_thick)
	PreCalced.WallSize_H_Short = PreCalced.WallSize_H_Long - Vector3(wall_thick, 0, 0)
	PreCalced.WallSize_V_Long = Vector3(wall_thick, cell_size.y, cell_size.z)
	PreCalced.WallSize_V_Short = PreCalced.WallSize_V_Long - Vector3(0, 0, wall_thick)
	return self

static func SwapXZ(src :Vector3) -> Vector3:
	return Vector3(src.z,src.y,src.x)

func mazepos2storeypos( mp :Vector2i, y :float) -> Vector3:
	var rtn := calc_grid.posi_to_lanepos( CalcGrid3D.xz_Vector2iToVector3i(mp,0) )
	rtn.y = y
	return rtn

func storeypos2mazepos(pos :Vector3) -> Vector2i:
	var rtn := calc_grid.lanepos_to_posi(pos)
	return CalcGrid3D.xz_Vector3iToVector2i(rtn)

# end settings

func init_with_mat(makedecofn :Callable, matmain :StandardMaterial3D, matsub :StandardMaterial3D) -> Maze3D:
	sub_wall_mat = matsub
	main_wall_mat = matmain
	pillar_box_mat = main_wall_mat.duplicate()
	pillar_box_mat.uv1_scale = Vector3( 3.0/20, 2, 1)
	pillar_capsule_mat = main_wall_mat.duplicate()
	pillar_capsule_mat.uv1_scale = Vector3( 3.0/20, 2, 1)
	make_wall_by_maze()
	make_box_pillas()
	make_capsule_pillas()
	make_wall_deco_by_maze(makedecofn)
	return self

func init_with_color(makedecofn :Callable, comain :Color, cosub :Color, copillarbox :Color, copillarcapsule :Color) -> Maze3D:
	sub_wall_mat = StandardMaterial3D.new()
	sub_wall_mat.albedo_color = Color( cosub, 0.5)
	sub_wall_mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	main_wall_mat = StandardMaterial3D.new()
	main_wall_mat.albedo_color = comain
	pillar_box_mat = StandardMaterial3D.new()
	pillar_box_mat.albedo_color = copillarbox
	pillar_capsule_mat = StandardMaterial3D.new()
	pillar_capsule_mat.albedo_color = copillarcapsule
	make_wall_by_maze()
	make_box_pillas()
	make_capsule_pillas()
	make_wall_deco_by_maze(makedecofn)
	return self

func init_floor_ceiling(grid_count :Vector2i, height :float, size_rate :float, co_floor :Color, co_ceiling :Color) -> Maze3D:
	var net_size :Vector2 = PreCalced.SizeWithWallV2
	$Floor.init_tile_grid_with_box( Vector3(net_size.x, net_size.y, height), grid_count, size_rate, co_floor)
	$Floor.rotation.x = -PI/2
	$Floor.position.y -= calc_grid.unit_size.y/2 +height/2
	$Ceiling.init_tile_grid_with_box(Vector3(net_size.x, net_size.y, height), grid_count, size_rate, co_ceiling)
	$Ceiling.rotation.x = PI/2
	$Ceiling.position.y += calc_grid.unit_size.y/2 +height/2
	return self

func get_floor() -> TileGrid:
	return $Floor
func get_ceiling() -> TileGrid:
	return $Ceiling

func make_box_pillas() -> void:
	var pos_list :Array = []
	for y in PreCalced.Grid2D.y+1:
		for x in PreCalced.Grid2D.x+1:
			pos_list.append(
				calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(0,calc_grid.unit_size.y/2.0,0) )
	var mesh := BoxMesh.new()
	mesh.material = pillar_box_mat
	mesh.size = PreCalced.PillarSize
	var rtn : MultiMeshShape = preload("res://multi_mesh_shape/multi_mesh_shape.tscn").instantiate(
		).init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape(rtn, pos_list)
	$BoxPillars.add_child(rtn)

func make_capsule_pillas() -> void:
	var pos_list :Array = []
	for y in PreCalced.Grid2D.y+1:
		for x in PreCalced.Grid2D.x+1:
			pos_list.append(
				calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(0,calc_grid.unit_size.y/2.0,0) )
	var mesh := CapsuleMesh.new()
	mesh.material = pillar_capsule_mat
	mesh.radius = WallThick/2
	mesh.height = calc_grid.unit_size.y
	var rtn : MultiMeshShape = preload("res://multi_mesh_shape/multi_mesh_shape.tscn").instantiate(
		).init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape_capsule(rtn, pos_list)
	$CapsulePillars.add_child(rtn)

func pos_multimeshshape_capsule(mms :MultiMeshShape, pos_list :Array) -> void:
	for i in pos_list.size():
		var t := Transform3D(Basis(), pos_list[i])
		#t = t.rotated_local(Vector3.LEFT, PI/2)
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
	for y in PreCalced.Grid2D.y:
		for x in PreCalced.Grid2D.x:
			if not maze_cells.is_open_dir_at(x,y,Maze.Flag.North):
				add_wall_at( x , y , Maze.Flag.North)
			if not maze_cells.is_open_dir_at(x,y,Maze.Flag.West):
				add_wall_at( x , y , Maze.Flag.West)

	for x in PreCalced.Grid2D.x :
		if not maze_cells.is_open_dir_at(x,PreCalced.Grid2D.y-1,Maze.Flag.South):
			add_wall_at( x , PreCalced.Grid2D.y , Maze.Flag.South)

	for y in PreCalced.Grid2D.y:
		if not maze_cells.is_open_dir_at(PreCalced.Grid2D.x-1,y,Maze.Flag.East):
			add_wall_at( PreCalced.Grid2D.x , y , Maze.Flag.East)

	wall_multi_inst_V_main = make_wall_multi_shape(main_wall_mat, PreCalced.WallSize_V_Long, pos_list_V_main)
	wall_multi_inst_H_main = make_wall_multi_shape(main_wall_mat, PreCalced.WallSize_H_Long, pos_list_H_main)
	wall_multi_inst_V_sub = make_wall_multi_shape(sub_wall_mat, PreCalced.WallSize_V_Long, pos_list_V_sub)
	wall_multi_inst_H_sub = make_wall_multi_shape(sub_wall_mat, PreCalced.WallSize_H_Long, pos_list_H_sub)

func calc_pos_face_V(x :int, y :int) -> Vector3:
	return calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(0, calc_grid.unit_size.y/2, calc_grid.unit_size.z/2)

func calc_pos_face_H(x :int, y :int) -> Vector3:
	return calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(calc_grid.unit_size.x/2, calc_grid.unit_size.y/2, 0)

func add_wall_at(x :int, y :int, dir :Maze.Flag) -> void:
	match dir:
		Maze.Flag.West, Maze.Flag.East:
			if randf() < MakeSubWallRate:
				pos_list_V_sub.append(calc_pos_face_V(x,y))
			else:
				pos_list_V_main.append(calc_pos_face_V(x,y))
		Maze.Flag.North, Maze.Flag.South:
			if randf() < MakeSubWallRate:
				pos_list_H_sub.append(calc_pos_face_H(x,y))
			else:
				pos_list_H_main.append(calc_pos_face_H(x,y))

func make_wall_deco_by_maze(makedeco :Callable) -> void:
	if not makedeco.is_valid():
		return

	for y in PreCalced.Grid2D.y:
		for x in PreCalced.Grid2D.x:
			if not maze_cells.is_open_dir_at(x,y,Maze.Flag.North):
				makedeco.call(x, y, Maze.Flag.North)
			if not maze_cells.is_open_dir_at(x,y,Maze.Flag.West):
				makedeco.call(x, y, Maze.Flag.West)

	for x in PreCalced.Grid2D.x :
		if not maze_cells.is_open_dir_at(x,PreCalced.Grid2D.y-1,Maze.Flag.South):
			makedeco.call(x, PreCalced.Grid2D.y, Maze.Flag.South)

	for y in PreCalced.Grid2D.y:
		if not maze_cells.is_open_dir_at(PreCalced.Grid2D.x-1,y,Maze.Flag.East):
			makedeco.call(PreCalced.Grid2D.x, y, Maze.Flag.East)

func deco_pos_by_dir(x :int, y :int, dir :Maze.Flag) -> Vector3:
	match dir:
		Maze.Flag.West:
			return calc_pos_face_V(x,y) + Vector3(WallThick,0,0)
		Maze.Flag.East:
			return calc_pos_face_V(x,y) - Vector3(WallThick,0,0)
		Maze.Flag.North:
			return calc_pos_face_H(x,y) + Vector3(0,0,WallThick)
		Maze.Flag.South:
			return calc_pos_face_H(x,y) - Vector3(0,0,WallThick)
	assert(false,"invalid dir %s" % dir)
	return Vector3.ZERO

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
		wall_multi_inst_H_main.multimesh.mesh.size = PreCalced.WallSize_H_Long
		wall_multi_inst_H_sub.multimesh.mesh.size = PreCalced.WallSize_H_Long
		wall_multi_inst_V_main.multimesh.mesh.size = PreCalced.WallSize_V_Long
		wall_multi_inst_V_sub.multimesh.mesh.size = PreCalced.WallSize_V_Long
	else:
		wall_multi_inst_H_main.multimesh.mesh.size = PreCalced.WallSize_H_Short
		wall_multi_inst_H_sub.multimesh.mesh.size = PreCalced.WallSize_H_Short
		wall_multi_inst_V_main.multimesh.mesh.size = PreCalced.WallSize_V_Short
		wall_multi_inst_V_sub.multimesh.mesh.size = PreCalced.WallSize_V_Short

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

func bounce_cell(oldpos:Vector3, pos :Vector3, radius :float) -> Dictionary:
	var posi := calc_grid.lanepos_to_posi(oldpos)
	var v := maze_cells.get_cell(posi.x,posi.z)
	return Bounce.v3f_wall(
		pos,
		calc_grid.cell_aabb_by_posi(posi),
		[
			(v & Maze.Flag.West) == 0 , (v & Maze.Flag.East) == 0 ,
			true, true,
			(v & Maze.Flag.North) == 0 , (v & Maze.Flag.South) == 0 ,
		],
		radius)
