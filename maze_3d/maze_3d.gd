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

static func SwapXZ(src :Vector3) -> Vector3:
	return Vector3(src.z,src.y,src.x)

func mazepos2storeypos( mp :Vector2i, y :float) -> Vector3:
	var rtn := calc_grid.posi_to_lanepos( CalcGrid3D.xz_Vector2iToVector3i(mp,0) )
	rtn.y = y
	return rtn

func storeypos2mazepos(pos :Vector3) -> Vector2i:
	var rtn := calc_grid.lanepos_to_posi(pos)
	return CalcGrid3D.xz_Vector3iToVector2i(rtn)

func init_params( maze2d :Maze, cell_size :Vector3, wall_thick :float, subwall_rate :float) -> Maze3D:
	WallThick = wall_thick
	MakeSubWallRate = subwall_rate
	maze_cells = maze2d
	var grid3d := Vector3(maze_cells.width,1,maze_cells.height)
	var sz := cell_size * (grid3d as Vector3)
	calc_grid = CalcGrid3D.new(CalcGrid3D.SizeToAABB(sz), grid3d)
	PreCalced.Grid2D = Vector2i(maze_cells.width,maze_cells.height)
	PreCalced.PillarSize = Vector3(wall_thick,cell_size.y,wall_thick)
	PreCalced.SizeV2 = (PreCalced.Grid2D as Vector2) * Vector2(cell_size.x, cell_size.z)
	PreCalced.SizeV3 = calc_grid.boundary.size
	PreCalced.SizeWithWallV2 = PreCalced.SizeV2 + Vector2(wall_thick, wall_thick)
	PreCalced.SizeWithWallV3 = Vector3(PreCalced.SizeWithWallV2.x, cell_size.y, PreCalced.SizeWithWallV2.y)
	PreCalced.WallSize_H_Long = Vector3(cell_size.x, cell_size.y, wall_thick)
	PreCalced.WallSize_H_Short = PreCalced.WallSize_H_Long - Vector3(wall_thick, 0, 0)
	PreCalced.WallSize_V_Long = Vector3(wall_thick, cell_size.y, cell_size.z)
	PreCalced.WallSize_V_Short = PreCalced.WallSize_V_Long - Vector3(0, 0, wall_thick)
	return self

func init_with_material(matmain :StandardMaterial3D, matsub :StandardMaterial3D) -> Maze3D:
	sub_wall_mat = matsub
	main_wall_mat = matmain
	pillar_box_mat = main_wall_mat.duplicate()
	pillar_box_mat.uv1_scale = Vector3( 3.0/20, 2, 1)
	pillar_capsule_mat = main_wall_mat.duplicate()
	pillar_capsule_mat.uv1_scale = Vector3( 3.0/20, 2, 1)
	exec_make()
	return self

func init_with_color(comain :Color, cosub :Color, copillarbox :Color, copillarcapsule :Color) -> Maze3D:
	sub_wall_mat = StandardMaterial3D.new()
	sub_wall_mat.albedo_color = Color( cosub, 0.5)
	sub_wall_mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	main_wall_mat = StandardMaterial3D.new()
	main_wall_mat.albedo_color = comain
	pillar_box_mat = StandardMaterial3D.new()
	pillar_box_mat.albedo_color = copillarbox
	pillar_capsule_mat = StandardMaterial3D.new()
	pillar_capsule_mat.albedo_color = copillarcapsule
	exec_make()
	return self

func exec_make() -> void:
	make_box_pillas()
	make_cylinder_pillas()
	make_wall_by_maze()

func init_floor_ceiling(grid_count :Vector2i, height :float, size_rate :float, co_floor :Color, co_ceiling :Color) -> Maze3D:
	var grid_count_3d := Vector3i(grid_count.x, 1, grid_count.y)
	var net_size :Vector2 = PreCalced.SizeWithWallV2
	$Floor.init_plot3d_box(Vector3(net_size.x, height, net_size.y), grid_count_3d, size_rate, true).fill_all(co_floor)
	#$Floor.rotation.x = PI/2
	$Floor.position.y -= calc_grid.unit_size.y/2 +height/2
	$Ceiling.init_plot3d_box(Vector3(net_size.x, height, net_size.y), grid_count_3d, size_rate, true).fill_all(co_ceiling)
	#$Ceiling.rotation.x = PI/2
	$Ceiling.position.y += calc_grid.unit_size.y/2 +height/2
	return self

func get_floor() -> Plot3D:
	return $Floor
func get_ceiling() -> Plot3D:
	return $Ceiling

func calc_tile_count(tg :Plot3D) -> Vector2:
	return Vector2( float(tg.calc_grid.grid_size.x) / maze_cells.width, float(tg.calc_grid.grid_size.z) / maze_cells.height)

func make_stair(tg :Plot3D, cell_posi :Vector2i, dir :Maze.Dir) -> void:
	var tile_count := calc_tile_count(tg)
	var step_x := calc_grid.unit_size.y / (tile_count.x+1)
	var step_y := calc_grid.unit_size.y / (tile_count.y+1)
	for y in tile_count.y:
		for x in tile_count.x:
			var tile_pos := cell_posi as Vector2 * tile_count + Vector2(x,y)
			var index :int = tg.calc_grid.get_index_by_posi_xyz(tile_pos.x as int, 0, tile_pos.y as int)
			var t := tg.multimesh.get_instance_transform(index)
			match dir:
				Maze.Dir.North:
					t.origin.y = -step_y * (y+1)
				Maze.Dir.South:
					t.origin.y = -step_y * (tile_count.y - y)
				Maze.Dir.East:
					t.origin.y = -step_x * (tile_count.x - x)
				Maze.Dir.West:
					t.origin.y = -step_x * (x+1)
				_ :
					assert(false, "invalid dir %s" % dir)
			#t.origin.y -= calc_grid.unit_size.z
			tg.multimesh.set_instance_transform(index, t)

func init_wall_deco(makedeco :Callable) -> void:
	if not makedeco.is_valid():
		return
	for y in PreCalced.Grid2D.y:
		for x in PreCalced.Grid2D.x:
			if not maze_cells.is_open_flag_at(x,y,Maze.Flag.North):
				makedeco.call(x, y, Maze.Flag.North)
			if not maze_cells.is_open_flag_at(x,y,Maze.Flag.West):
				makedeco.call(x, y, Maze.Flag.West)
	for x in PreCalced.Grid2D.x :
		if not maze_cells.is_open_flag_at(x,PreCalced.Grid2D.y-1,Maze.Flag.South):
			makedeco.call(x, PreCalced.Grid2D.y, Maze.Flag.South)
	for y in PreCalced.Grid2D.y:
		if not maze_cells.is_open_flag_at(PreCalced.Grid2D.x-1,y,Maze.Flag.East):
			makedeco.call(PreCalced.Grid2D.x, y, Maze.Flag.East)


func make_box_pillas() -> void:
	var pos_list :Array = []
	for y in PreCalced.Grid2D.y+1:
		for x in PreCalced.Grid2D.x+1:
			pos_list.append(
				calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(0,calc_grid.unit_size.y/2.0,0) )
	var mesh := BoxMesh.new()
	mesh.material = pillar_box_mat
	mesh.size = PreCalced.PillarSize
	$BoxPillars.init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape($BoxPillars, pos_list)

func make_cylinder_pillas() -> void:
	var pos_list :Array = []
	for y in PreCalced.Grid2D.y+1:
		for x in PreCalced.Grid2D.x+1:
			pos_list.append(
				calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(0,calc_grid.unit_size.y/2.0,0) )
	var mesh := CylinderMesh.new()
	mesh.material = pillar_capsule_mat
	mesh.bottom_radius = WallThick/1.5
	mesh.top_radius = WallThick/1.5
	mesh.height = calc_grid.unit_size.y
	mesh.radial_segments = 8
	$CapsulePillars.init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape_capsule($CapsulePillars, pos_list)

func pos_multimeshshape_capsule(mms :MultiMeshShape, pos_list :Array) -> void:
	for i in pos_list.size():
		var t := Transform3D(Basis(), pos_list[i])
		#t = t.rotated_local(Vector3.LEFT, PI/2)
		mms.multimesh.set_instance_transform(i,t)

func pos_multimeshshape(mms :MultiMeshShape, pos_list :Array) -> void:
	for i in pos_list.size():
		var t := Transform3D(Basis(), pos_list[i])
		mms.multimesh.set_instance_transform(i,t)

func make_wall_multi_shape(mms :MultiMeshShape, mat :Material, sz :Vector3, pos_list :Array) -> void:
	var mesh := BoxMesh.new()
	mesh.size = sz
	mesh.material = mat
	mms.init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape(mms, pos_list)

func make_wall_by_maze() -> void:
	var pos_list_V_main :Array
	var pos_list_H_main :Array
	var pos_list_V_sub :Array
	var pos_list_H_sub :Array
	var add_wall_at := func(x :int, y :int, dir :Maze.Flag) -> void:
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

	for y in PreCalced.Grid2D.y:
		for x in PreCalced.Grid2D.x:
			if not maze_cells.is_open_flag_at(x,y,Maze.Flag.North):
				add_wall_at.call(x, y, Maze.Flag.North)
			if not maze_cells.is_open_flag_at(x,y,Maze.Flag.West):
				add_wall_at.call(x, y, Maze.Flag.West)

	for x in PreCalced.Grid2D.x :
		if not maze_cells.is_open_flag_at(x,PreCalced.Grid2D.y-1,Maze.Flag.South):
			add_wall_at.call(x, PreCalced.Grid2D.y, Maze.Flag.South)

	for y in PreCalced.Grid2D.y:
		if not maze_cells.is_open_flag_at(PreCalced.Grid2D.x-1,y,Maze.Flag.East):
			add_wall_at.call(PreCalced.Grid2D.x, y, Maze.Flag.East)

	make_wall_multi_shape($WallContainer/VMain, main_wall_mat, PreCalced.WallSize_V_Long, pos_list_V_main)
	make_wall_multi_shape($WallContainer/HMain, main_wall_mat, PreCalced.WallSize_H_Long, pos_list_H_main)
	make_wall_multi_shape($WallContainer/VSub, sub_wall_mat, PreCalced.WallSize_V_Long, pos_list_V_sub)
	make_wall_multi_shape($WallContainer/HSub, sub_wall_mat, PreCalced.WallSize_H_Long, pos_list_H_sub)

func calc_pos_face_V(x :int, y :int) -> Vector3:
	return calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(0, calc_grid.unit_size.y/2, calc_grid.unit_size.z/2)

func calc_pos_face_H(x :int, y :int) -> Vector3:
	return calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(calc_grid.unit_size.x/2, calc_grid.unit_size.y/2, 0)

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
static func view_floor_ceiling_next(a :FloorCeiling) -> FloorCeiling:
	return (a +1) % FloorCeiling.keys().size() as FloorCeiling

func set_wall_size_long(b :bool) -> void:
	if b:
		$WallContainer/HMain.multimesh.mesh.size = PreCalced.WallSize_H_Long
		$WallContainer/HSub.multimesh.mesh.size = PreCalced.WallSize_H_Long
		$WallContainer/VMain.multimesh.mesh.size = PreCalced.WallSize_V_Long
		$WallContainer/VSub.multimesh.mesh.size = PreCalced.WallSize_V_Long
	else:
		$WallContainer/HMain.multimesh.mesh.size = PreCalced.WallSize_H_Short
		$WallContainer/HSub.multimesh.mesh.size = PreCalced.WallSize_H_Short
		$WallContainer/VMain.multimesh.mesh.size = PreCalced.WallSize_V_Short
		$WallContainer/VSub.multimesh.mesh.size = PreCalced.WallSize_V_Short

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

enum WallPillarView {Long, Short, ShortWithPillarBox, ShortWithPillarCylinder, Off, OffWithPillarBox, OffWithPillarCylinder}
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
		WallPillarView.ShortWithPillarCylinder:
			view_walls(WallView.Short)
			set_wall_size_long(false)
			view_pillars(PillarView.Capsule)
		WallPillarView.Off:
			view_walls(WallView.Off)
			view_pillars(PillarView.Off)
		WallPillarView.OffWithPillarBox:
			view_walls(WallView.Off)
			view_pillars(PillarView.Box)
		WallPillarView.OffWithPillarCylinder:
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
