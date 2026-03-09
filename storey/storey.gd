extends Node3D
class_name Storey

## maze default settings
const GridSize := Vector2i(4,4)
const CellSize := Vector3(4.0,3.0,4.0)

var storey_animation := SimpleAnimation.new()
func _process(delta: float) -> void:
	storey_animation.handle_animation()
	for mb in bouncing_list:
		mb.bounce(delta)

var DonutCapsuleCount :int
var MakeLine2DWallRate :float
var MakeClockCalWallRate :float
var BouncingCount :int
func setting_default() -> Storey:
	DonutCapsuleCount = max(2, GridSize.x*GridSize.y/20.0)
	MakeLine2DWallRate = 1.0/(GridSize.x*GridSize.y)
	MakeClockCalWallRate = 1.0/(GridSize.x*GridSize.y)
	BouncingCount = 10
	return self
func setting_simple() -> Storey:
	DonutCapsuleCount = 0
	MakeLine2DWallRate = 0
	MakeClockCalWallRate = 0
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

func get_mini_map() -> MiniMap:
	return $MiniMap

var storey_height :float

func _to_string() -> String:
	return "Storey[%d DonutCapsuleCount%s MakeLine2DWallRate%s MakeClockCalWallRate%s BouncingCount%s]" % [
		storey_num, DonutCapsuleCount,MakeLine2DWallRate,MakeClockCalWallRate,BouncingCount]

func init(num :int) -> Storey:
	var grid_size = GridSize + Vector2i(randi_range(-1,1), randi_range(-1,1) )
	var cell_size = CellSize * Vector3(
		pow(1.2, randf()*2 -1 ),
		pow(1.2, randf()*2 -1 ),
		pow(1.2, randf()*2 -1 ),
	)
	var maze2d := Maze.new(grid_size)
	maze3d = preload("res://maze_3d/maze_3d.tscn").instantiate(
		).init_setting(maze2d, cell_size, cell_size.y *0.05, 1.0/(grid_size.x*grid_size.y)
		).init_floor_ceiling(grid_size*4, cell_size.y *0.01, 0.9,
		Color(NamedColors.random_color(), 0.5),
		Color(NamedColors.random_color(), 0.5),
	)
	storey_height = cell_size.y + cell_size.y *0.01 * 2
	change_floor_ceiling_colors()
	add_child(maze3d)
	if num % 2 ==0 :
		maze3d.init_with_mat(add_wall_deco_at,
			TexMat.make_mainwall_mat(),
			TexMat.make_subwall_mat() )
	else:
		maze3d.init_with_color(add_wall_deco_at,
			NamedColors.random_color(), NamedColors.random_color(), NamedColors.random_color(), NamedColors.random_color(),
		)
	storey_num = num

	놓인것들 = PlacedThings.new(maze3d.PreCalced.Grid2D)
	var 구석자리목록 :Array[Vector2i] = []
	for y in maze3d.PreCalced.Grid2D.y:
		for x in maze3d.PreCalced.Grid2D.x:
			if maze3d.maze_cells.get_open_dir_at(x,y).size() == 1:
				구석자리목록.append(Vector2i(x,y))

	구석자리목록.shuffle()
	start_pos = 구석자리목록.pop_front()
	goal_pos = 구석자리목록.pop_front()

	var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
	$StartMark.init(크기기준*0.2, 크기기준/100, NamedColors.random_color(), "Start %d" % storey_num
		).position = maze3d.mazepos2storeypos(start_pos, 0)
	$EndMark.init(크기기준*0.2, 크기기준/100, NamedColors.random_color(), "Goal %d" % storey_num
		).position = maze3d.mazepos2storeypos(goal_pos, 0)
	놓인것들.set_at(start_pos, $StartMark)
	놓인것들.set_at(goal_pos, $EndMark)

	add_donut_capsule(DonutCapsuleCount, 구석자리목록)
	$Label3D.pixel_size = maze3d.calc_grid.unit_size.y/50
	$Label3D.text = "%d" % storey_num
	$Label3D.position = Vector3(-maze3d.WallThick*2, 0, -maze3d.WallThick*2) + maze3d.calc_grid.boundary.position
	$MiniMap.init(self)

	add_bouncing(BouncingCount , 크기기준 /20)
	return self

func change_floor_ceiling_colors() -> void:
	maze3d.get_floor().set_tile_color_8way(NamedColors.color_list, randi_range(0,7))
	maze3d.get_ceiling().set_tile_color_8way(NamedColors.color_list, randi_range(0,7))

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
		else:
			var p := CalcGrid3D.xz_Vector3iToVector2i(maze3d.calc_grid.rand_posi())
			ch.enter_storey(old_storey, self, p)

	$MiniMap.add_chars(char_list, playernum)
	$MiniMap.update_size()
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
var clockcalendar_sel :int
# add clock or calendar
func add_wall_deco_at(x :int, y :int, dir :Maze.Flag) -> void:
	if randf() < MakeLine2DWallRate:
		if line2d_subviewport == null:
			line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
			$WallDeco.add_child(line2d_subviewport)
		var b := make_plane_from_subviewport(line2d_subviewport)
		$WallDeco.add_child(b)
		b.position = maze3d.deco_pos_by_dir(x,y,dir)
		#b.rotate_x(PI/2)
		b.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir]))
		return

	if randf() < MakeClockCalWallRate:
		var n :Node3D
		var depth := 0.1
		var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
		clockcalendar_sel +=1
		if clockcalendar_sel % 2 == 0:
			n = preload("res://calendar_3d/calendar_3d.tscn").instantiate()
			n.init(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,
				depth, 크기기준/12, false)
		else :
			n = preload("res://analog_clock_3d/analog_clock_3d.tscn").instantiate()
			n.init(크기기준/2, depth, 크기기준/16, 9.0, false)
		#n.rotate_x(PI/2)
		n.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir]))
		n.position = maze3d.deco_pos_by_dir(x,y,dir)
		$WallDeco.add_child(n)

func make_line2d_subvuewport(size_pixel:Vector2i) -> SubViewport:
	var l2d :MoveLine2D = preload("res://move_line_2d/move_line_2d.tscn").instantiate().init_with_random(300,4,1.5,size_pixel)
	l2d.start()
	var sv := SubViewport.new()
	sv.size = size_pixel
	#sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#sv.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	sv.transparent_bg = true
	sv.add_child(l2d)
	return sv

func make_plane_from_subviewport(sv :SubViewport) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y)
	mesh.orientation = PlaneMesh.FACE_Z
	var sp := MeshInstance3D.new()
	sp.mesh = mesh
	sp.material_override = StandardMaterial3D.new()
	sp.material_override.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	sp.material_override.albedo_texture = sv.get_texture()
	return sp
