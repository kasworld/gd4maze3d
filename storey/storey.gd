extends Node3D
class_name Storey

static func MakeSubViewport(n2d :Node2D, size_pixel:Vector2i) -> SubViewport:
	var sv := SubViewport.new()
	sv.size = size_pixel
	#sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#sv.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	sv.transparent_bg = true
	sv.add_child(n2d)
	return sv

static func MakePlaneSubViewport(svp :SubViewport, mesh_size :Vector2) -> MeshInstance3D:
	var sp := MeshInstance3D.new()
	sp.mesh = PlaneMesh.new()
	sp.mesh.size = mesh_size
	sp.mesh.orientation = PlaneMesh.FACE_Z
	sp.material_override = StandardMaterial3D.new()
	sp.material_override.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	sp.material_override.albedo_texture = svp.get_texture()
	return sp

static func ClampfRand(v :float) -> float :
	var rtn := randfn( v, v/2 )
	return clampf(rtn, v/2 , v *2)

## maze default settings
const GridSize := Vector2i(4,4)
const CellSize := Vector3(4.0,3.0,4.0)

var storey_animation := SimpleAnimation.new()
func _process(delta: float) -> void:
	storey_animation.handle_animation()
	for mb in bouncing_list:
		mb.bounce(delta)
	for l2d in move_line_2d_list:
		l2d.process_animation(delta)

var DonutCapsuleCount :int
var WallDecoRate :float
var BouncingCount :int
func setting_default() -> Storey:
	DonutCapsuleCount = max(2, GridSize.x*GridSize.y/20.0)
	WallDecoRate = 2.0/(GridSize.x*GridSize.y)
	BouncingCount = 10
	return self
func setting_simple() -> Storey:
	DonutCapsuleCount = 0
	WallDecoRate = 0
	BouncingCount = 0
	return self

var maze3d :Maze3D
var storey_num :int
var start_pos :Vector2i
var goal_pos :Vector2i
func is_goal_pos(p :Vector2i) -> bool:
	return goal_pos == p

var wall_info_all :Array
var 놓인것들 :PlacedThings # 배치된 capsule, donut tree start goal 들

func get_maze3d() -> Maze3D:
	return maze3d

func get_maze_cells() -> Maze:
	return maze3d.maze_cells

func get_char_list() -> Array:
	return $CharacterContainer.get_children()

func get_mini_map() -> StoreyMiniMap:
	return $MiniMap

var storey_height :float

func _to_string() -> String:
	return "Storey[%d %s DonutCapsuleCount%s WallDecoRate%s BouncingCount%s]" % [
		storey_num, maze3d, DonutCapsuleCount, WallDecoRate, BouncingCount]


func init(num :int, make_random :bool = false) -> Storey:
	var grid_size := GridSize
	var cell_size := CellSize
	if make_random :
		grid_size = Vector2i(
			ClampfRand(GridSize.x) as int,
			ClampfRand(GridSize.y) as int,
		)
		cell_size = Vector3(
			ClampfRand(CellSize.x),
			ClampfRand(CellSize.y),
			ClampfRand(CellSize.z),
		)
	var maze2d := Maze.new(grid_size)
	var floor_ceiling_height :float = cell_size.y *0.01
	maze3d = preload("res://maze_3d/maze_3d.tscn").instantiate(
		).init_params(maze2d, cell_size, cell_size.y *0.05, 1.0/(grid_size.x*grid_size.y)
		).init_floor_ceiling(grid_size*4, floor_ceiling_height, 0.9,
		Color(NamedColors.random_color(), 0.5),
		Color(NamedColors.random_color(), 0.5),
	)
	storey_height = cell_size.y + floor_ceiling_height * 2
	add_child(maze3d)
	if num % 2 ==0 :
		maze3d.init_with_material(TexMat.make_mainwall_mat(),TexMat.make_subwall_mat() )
	else:
		maze3d.init_with_color(
			NamedColors.random_color(), NamedColors.random_color(), NamedColors.random_color(), NamedColors.random_color())
	maze3d.init_wall_deco(add_wall_deco_at)
	storey_num = num

	놓인것들 = PlacedThings.new(maze3d.PreCalced.Grid2D)
	var 구석자리목록 :Array[Vector2i] = []
	for y in maze3d.PreCalced.Grid2D.y:
		for x in maze3d.PreCalced.Grid2D.x:
			if maze3d.maze_cells.get_open_flag_at(x,y).size() == 1:
				구석자리목록.append(Vector2i(x,y))

	구석자리목록.shuffle()
	start_pos = 구석자리목록.pop_front()
	goal_pos = 구석자리목록.pop_front()
	maze3d.make_stair(maze3d.get_floor(), start_pos, maze2d.get_open_dir_at(start_pos.x,start_pos.y).pick_random())
	maze3d.make_stair(maze3d.get_ceiling(), goal_pos, Maze.DirOpppsite[maze2d.get_open_dir_at(goal_pos.x,goal_pos.y).pick_random()])

	var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
	$StartMark.init(크기기준*0.2, 크기기준/100, NamedColors.random_color(), "Start %d" % storey_num, start_pos
		).position = maze3d.mazepos2storeypos(start_pos, 0)
	$EndMark.init(크기기준*0.2, 크기기준/100, NamedColors.random_color(), "Goal %d" % storey_num, goal_pos
		).position = maze3d.mazepos2storeypos(goal_pos, 0)
	놓인것들.set_at(start_pos, $StartMark)
	놓인것들.set_at(goal_pos, $EndMark)

	add_donut_capsule(DonutCapsuleCount, 구석자리목록)
	$Label3D.pixel_size = maze3d.calc_grid.unit_size.y/50
	$Label3D.text = "%d" % storey_num
	$Label3D.position = Vector3(-maze3d.WallThick*2, 0, -maze3d.WallThick*2) + maze3d.calc_grid.boundary.position
	$MiniMap.init(maze2d)
	$MiniMap.add_obj($StartMark, "Start", $StartMark.get_color(), 1, true)
	$MiniMap.add_obj($EndMark, "Goal", $EndMark.get_color(), 1, true)

	add_bouncing(BouncingCount , 크기기준 /20)
	return self

var bouncing_list :Array
func add_bouncing(n :int, radius :float) -> void:
	bouncing_list = []
	for i in n:
		var mb :MazeBall = preload("res://maze_3d/maze_ball/maze_ball.tscn").instantiate(
			).init(maze3d, radius, radius*10, NamedColors.random_color())
		$BouncingContainer.add_child(mb)
		bouncing_list.append(mb)

func chars_enter_storey(old_storey :Storey, char_list :Array, playernum :int) -> void:
	for ch in char_list:
		ch.reparent($CharacterContainer)
		if ch.crawler_num == playernum:
			ch.enter_storey(old_storey, self, start_pos)
			$MiniMap.add_obj(ch, "%d" % ch.crawler_num, ch.get_color(), 1, true)
		else:
			var p := CalcGrid3D.xz_Vector3iToVector2i(maze3d.calc_grid.rand_posi())
			ch.enter_storey(old_storey, self, p)
			$MiniMap.add_obj(ch, "%d" % ch.crawler_num, ch.get_color(), 0, false)

	var rt := get_viewport().get_visible_rect()
	$MiniMap.update_size(rt.size)
	if old_storey != null:
		$MiniMap.set_minimap_mod(old_storey.get_mini_map().minimap_mode)
		old_storey.get_mini_map().visible = false


func 놓인것들줍기(ch :Crawler) -> void:
	var ft = 놓인것들.get_at(ch.pos_src)
	if ft is Donut:
		ch.action_queue.enqueue(ActionQueue.Action.RollLeft)
		놓인것들.del_at(ch.pos_src)
		ft.queue_free()
	elif ft is Capsule:
		ch.action_queue.enqueue(ActionQueue.Action.RollRight)
		놓인것들.del_at(ch.pos_src)
		ft.queue_free()

func add_donut_capsule(n :int, 구석자리목록 :Array[Vector2i]) -> void:
	for i in n:
		if 구석자리목록.size() <= 0:
			break
		var p = 구석자리목록.pop_front()
		if 놓인것들.get_at(p) != null:
			continue
		var co :Color = NamedColors.random_color()
		var pobj
		var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
		if randi()%2 ==0:
			pobj = preload("res://places_things/capsule.tscn").instantiate().init(크기기준*0.3, 크기기준*0.05, co)
		else:
			pobj = preload("res://places_things/donut.tscn").instantiate().init(크기기준*0.07, 크기기준*0.15,co)
		pobj.position = maze3d.mazepos2storeypos(p, -maze3d.calc_grid.unit_size.y*0.3)
		$PlacedThings.add_child(pobj)
		놓인것들.set_at(p,pobj)


var line2d_subviewport :SubViewport
var minimap_subviewport :SubViewport
# add clock or calendar
func add_wall_deco_at(x :int, y :int, dir :Maze.Flag) -> void:
	if randf() < WallDecoRate:
		match randi_range(0,3):
			0:
				if line2d_subviewport == null:
					line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
					$WallDeco.add_child(line2d_subviewport)
				var b := MakePlaneSubViewport(line2d_subviewport, Vector2(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y))
				$WallDeco.add_child(b)
				b.position = maze3d.deco_pos_by_dir(x,y,dir)
				#b.rotate_x(PI/2)
				b.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir]))
			1:
				if minimap_subviewport == null:
					minimap_subviewport = make_minimap_subvuewport(Vector2i(2000,1500))
					$WallDeco.add_child(minimap_subviewport)
				var b := MakePlaneSubViewport(minimap_subviewport, Vector2(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y))
				$WallDeco.add_child(b)
				b.position = maze3d.deco_pos_by_dir(x,y,dir)
				#b.rotate_x(PI/2)
				b.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir]))
			2:
				var depth := 0.1
				var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
				var n :Node3D = preload("res://calendar_3d/calendar_3d.tscn").instantiate()
				n.init(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y, depth, 크기기준/12, false)
				#n.rotate_x(PI/2)
				n.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir]))
				n.position = maze3d.deco_pos_by_dir(x,y,dir)
				$WallDeco.add_child(n)
			3:
				var depth := 0.1
				var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
				var n :Node3D = preload("res://analog_clock_3d/analog_clock_3d.tscn").instantiate()
				n.init(크기기준/2, depth, 크기기준/16, false)
				#n.rotate_x(PI/2)
				n.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir]))
				n.position = maze3d.deco_pos_by_dir(x,y,dir)
				$WallDeco.add_child(n)
				n.update_clock(AnalogClock3D.get_localtime_from_system())

var move_line_2d_list :Array = []
func make_line2d_subvuewport(size_pixel:Vector2i) -> SubViewport:
	var l2d :MoveLine2D = preload("res://move_line_2d/move_line_2d.tscn").instantiate().init_with_random(300,4,1.5,size_pixel)
	move_line_2d_list.append(l2d)
	return  MakeSubViewport(l2d,size_pixel)

func make_minimap_subvuewport(size_pixel:Vector2i) -> SubViewport:
	var mm :MazeMiniMap = preload("res://maze_3d/maze_mini_map/maze_mini_map.tscn").instantiate()
	mm.set_maze(maze3d.maze_cells)
	mm.set_color(Color.WHITE)
	mm.update_size(size_pixel)
	mm.position = size_pixel as Vector2 /2  - mm.maze2d_helper.get_size()/2
	return  MakeSubViewport(mm,size_pixel)
