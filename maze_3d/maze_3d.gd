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
	PreCalced.SizeV3 = calc_grid.aabb.size
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
	exec_make()
	return self

func init_with_color(comain :Color, cosub :Color, copillarbox :Color) -> Maze3D:
	sub_wall_mat = CSG.MakeColorMaterial(Color( cosub, 0.5), true)
	main_wall_mat = CSG.MakeColorMaterial(comain)
	pillar_box_mat = CSG.MakeColorMaterial(copillarbox)
	exec_make()
	return self

func exec_make() -> void:
	make_box_pillas()
	make_wall_by_maze()

var floor_ceiling_tile_per_cell :Vector2i
func init_floor_ceiling_box(tile_per_cell :Vector2i, height :float, size_rate :float, co_floor :Color, co_ceiling :Color) -> Maze3D:
	floor_ceiling_tile_per_cell = tile_per_cell
	var grid_count_3d := Vector3i(tile_per_cell.x * maze_cells.width, 1, tile_per_cell.y *maze_cells.height)
	var net_size :Vector2 = PreCalced.SizeV2
	$Floor.init_plot3d_box(Vector3(net_size.x, height, net_size.y), grid_count_3d, size_rate, true).fill_all(co_floor)
	$Floor.position.y -= calc_grid.unit_size.y/2 +height/2
	$Ceiling.init_plot3d_box(Vector3(net_size.x, height, net_size.y), grid_count_3d, size_rate, true).fill_all(co_ceiling)
	$Ceiling.position.y += calc_grid.unit_size.y/2 +height/2
	return self

func init_floor_ceiling_plane(tile_per_cell :Vector2i, height :float, size_rate :float, co_floor :Color, co_ceiling :Color) -> Maze3D:
	floor_ceiling_tile_per_cell = tile_per_cell
	var grid_count_3d := Vector3i(tile_per_cell.x * maze_cells.width, 1, tile_per_cell.y *maze_cells.height)
	var net_size :Vector2 = PreCalced.SizeV2
	var cg = Plot3D.MakeCalcGrid(Vector3(net_size.x, height, net_size.y), grid_count_3d)
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(cg.unit_size.x,cg.unit_size.z) *size_rate
	mesh.material = Plot3D.MakeMultiMeshColorMaterial(true)
	$Floor.init_plot3d_mesh_calcgrid(mesh, cg).fill_all(co_floor)
	$Floor.position.y -= calc_grid.unit_size.y/2 +height/2
	$Ceiling.init_plot3d_mesh_calcgrid(mesh, cg).fill_all(co_ceiling)
	$Ceiling.position.y += calc_grid.unit_size.y/2 +height/2
	$Ceiling.cell_rotation_x = PI
	return self

func get_floor() -> Plot3D:
	return $Floor
func get_ceiling() -> Plot3D:
	return $Ceiling

func add_stair(cell_posi :Vector3i, dir :Maze.Dir, co :Color) -> MeshInstance3D:
	var unit_size := calc_grid.unit_size
	var center := CSG.MakeDummyCenter()
	CSG.AddHWire(center,
		Vector2(unit_size.x*0.5, unit_size.z*0.9),Vector2i(2,6), unit_size.y/20, unit_size.y/5,
		CSG.MakeColorMaterial(co, false), Vector3(PI/4,0,0))
	CSG.AddVWire(center,
		Vector2(unit_size.x*0.5, unit_size.z),Vector2i(2,6), unit_size.y/30, unit_size.y/30,
		CSG.MakeColorMaterial(co, false))
	var wn := CSG.DefferedBake(center)
	wn.rotation.x = -PI/4
	wn.rotation.y = Maze.DirToRadian(dir)
	wn.position = calc_grid.posi_to_lanepos(cell_posi)
	add_child(wn)
	return wn

func add_ladder(cell_posi :Vector3i, dir :Maze.Dir, co :Color) -> MeshInstance3D:
	var unit_size := calc_grid.unit_size
	var mat := CSG.MakeColorMaterial(co, false)
	var center := CSG.MakeDummyCenter()
	CSG.AddHWire(center,
		Vector2(unit_size.x*0.5, unit_size.y*0.8), Vector2i(0,6), unit_size.y/30, unit_size.y/30,
		mat )
	CSG.AddVWire(center,
		Vector2(unit_size.x*0.5, unit_size.y), Vector2i(2,6), unit_size.y/30, unit_size.y/30,
		mat)
	var wn := CSG.DefferedBake(center)
	wn.rotation.y = Maze.DirToRadian(dir)
	wn.position = calc_grid.posi_to_lanepos(cell_posi)
	add_child(wn)
	return wn

func make_stair_hole(tg :Plot3D, cell_posi :Vector2i) -> void:
	for y in floor_ceiling_tile_per_cell.y:
		for x in floor_ceiling_tile_per_cell.x:
			var tile_pos := Vector3i(cell_posi.x * floor_ceiling_tile_per_cell.x + x , 0, cell_posi.y * floor_ceiling_tile_per_cell.y + y )
			tg.del_at( tile_pos)

func make_box_pillas() -> void:
	var pos_list :Array = []
	for y in maze_cells.height+1:
		for x in maze_cells.width+1:
			pos_list.append(
				calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(0,calc_grid.unit_size.y/2.0,0) )
	var mesh := BoxMesh.new()
	mesh.material = pillar_box_mat
	mesh.size = PreCalced.PillarSize
	$BoxPillars.init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape($BoxPillars, pos_list)

func pos_multimeshshape(mms :MultiMeshShape, pos_list :Array) -> void:
	for i in pos_list.size():
		var t := Transform3D(Basis(), pos_list[i])
		mms.multimesh.set_instance_transform(i,t)

func make_wall_by_maze() -> void:
	var pos_list_V_main :Array
	var pos_list_H_main :Array
	var pos_list_V_sub :Array
	var pos_list_H_sub :Array
	var add_wall_at := func(x :int, y :int, dir :Maze.Flag) -> void:
		match dir:
			Maze.Flag.West, Maze.Flag.East:
				if randf() < MakeSubWallRate:
					pos_list_V_sub.append(calc_wall_pos_face_V(x,y))
				else:
					pos_list_V_main.append(calc_wall_pos_face_V(x,y))
			Maze.Flag.North, Maze.Flag.South:
				if randf() < MakeSubWallRate:
					pos_list_H_sub.append(calc_wall_pos_face_H(x,y))
				else:
					pos_list_H_main.append(calc_wall_pos_face_H(x,y))
	maze_cells.iter_wall(add_wall_at)
	make_wall_multi_shape($WallContainer/VMain, main_wall_mat, PreCalced.WallSize_V_Long, pos_list_V_main)
	make_wall_multi_shape($WallContainer/HMain, main_wall_mat, PreCalced.WallSize_H_Long, pos_list_H_main)
	make_wall_multi_shape($WallContainer/VSub, sub_wall_mat, PreCalced.WallSize_V_Long, pos_list_V_sub)
	make_wall_multi_shape($WallContainer/HSub, sub_wall_mat, PreCalced.WallSize_H_Long, pos_list_H_sub)
func make_wall_multi_shape(mms :MultiMeshShape, mat :Material, sz :Vector3, pos_list :Array) -> void:
	var mesh := BoxMesh.new()
	mesh.size = sz
	mesh.material = mat
	mms.init_with_mesh(mesh, pos_list.size())
	pos_multimeshshape(mms, pos_list)

func make_door_by_maze(co_doorH :Color,co_doorV :Color, hole_rate := 0.8) -> void:
	var door_matH := CSG.MakeColorMaterial(co_doorH)
	var door_matV := CSG.MakeColorMaterial(co_doorV)
	var pos_list_V :Array
	var pos_list_H :Array
	var add_door_at := func(x :int, y :int, dir :Maze.Flag) -> void:
		match dir:
			Maze.Flag.West, Maze.Flag.East:
				pos_list_V.append(calc_wall_pos_face_V(x,y))
			Maze.Flag.North, Maze.Flag.South:
				pos_list_H.append(calc_wall_pos_face_H(x,y))
	maze_cells.iter_open(add_door_at)
	var csgH := PropArchDoor.MakeArchDoorMeshH(PreCalced.WallSize_H_Short, door_matH, hole_rate)
	bake_door.call_deferred($DoorContainer/HDoor,pos_list_H, csgH)
	var csgV := PropArchDoor.MakeArchDoorMeshV(PreCalced.WallSize_V_Short, door_matV, hole_rate)
	bake_door.call_deferred($DoorContainer/VDoor,pos_list_V, csgV)
func bake_door(mms :MultiMeshShape, pos_list :Array, csg :CSGShape3D) -> void:
	var sw := StopWatch.new("%s bake_door" % self)
	mms.init_with_mesh(csg.bake_static_mesh(), pos_list.size())
	sw.split("init_with_mesh")
	pos_multimeshshape(mms, pos_list)
	sw.split("pos_multimeshshape")
	#print_debug(sw)

func calc_wall_pos_face_V(x :int, y :int) -> Vector3:
	return calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(0, calc_grid.unit_size.y/2, calc_grid.unit_size.z/2)

func calc_wall_pos_face_H(x :int, y :int) -> Vector3:
	return calc_grid.posi_to_linepos(Vector3i(x,0,y)) + Vector3(calc_grid.unit_size.x/2, calc_grid.unit_size.y/2, 0)

## apply WallThick
func wall_deco_pos_by_dir(x :int, y :int, dir :Maze.Flag) -> Vector3:
	match dir:
		Maze.Flag.West:
			return calc_wall_pos_face_V(x,y) + Vector3(WallThick*0.55,0,0)
		Maze.Flag.East:
			return calc_wall_pos_face_V(x,y) - Vector3(WallThick*0.55,0,0)
		Maze.Flag.North:
			return calc_wall_pos_face_H(x,y) + Vector3(0,0,WallThick*0.55)
		Maze.Flag.South:
			return calc_wall_pos_face_H(x,y) - Vector3(0,0,WallThick*0.55)
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

func view_doors(b :bool) ->void:
	$DoorContainer.visible = b

func view_pillars(b :bool) -> void:
	$BoxPillars.visible = b

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

enum WallPillarDoorView {AllOff, WallShort, WallLong, WallShortPillar, Pillar, WallShortDoor, WallShortPillarDoor, PillarDoor}
static func wallpillardoorview2str(vd :WallPillarDoorView) -> String:
	return WallPillarDoorView.keys()[vd]
static func wallpillardoorview_next(a :WallPillarDoorView) -> WallPillarDoorView:
	return (a +1) % WallPillarDoorView.keys().size() as WallPillarDoorView

func set_wallpillardoor_view_mode(w :WallPillarDoorView) -> void:
	match w:
		WallPillarDoorView.AllOff:
			view_walls(WallView.Off)
			view_pillars(false)
			view_doors(false)
		WallPillarDoorView.WallLong:
			view_walls(WallView.Long)
			set_wall_size_long(true)
			view_pillars(false)
			view_doors(false)
		WallPillarDoorView.WallShort:
			view_walls(WallView.Short)
			set_wall_size_long(false)
			view_pillars(false)
			view_doors(false)
		WallPillarDoorView.WallShortPillar:
			view_walls(WallView.Short)
			set_wall_size_long(false)
			view_pillars(true)
			view_doors(false)
		WallPillarDoorView.Pillar:
			view_walls(WallView.Off)
			view_pillars(true)
			view_doors(false)
		WallPillarDoorView.WallShortDoor:
			view_walls(WallView.Short)
			set_wall_size_long(false)
			view_pillars(false)
			view_doors(true)
		WallPillarDoorView.WallShortPillarDoor:
			view_walls(WallView.Short)
			set_wall_size_long(false)
			view_pillars(true)
			view_doors(true)
		WallPillarDoorView.PillarDoor:
			view_walls(WallView.Off)
			view_pillars(true)
			view_doors(true)

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
