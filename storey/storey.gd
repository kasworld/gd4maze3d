extends Node3D
class_name Storey

static var RandomColorIter := ListIter.new(NamedColors.color_list)

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

## maze default settings
const GridSize := Vector2i(2,2)
const CellSize := Vector3(4.0,3.0,4.0)

var storey_animation := SimpleAnimation.new()
func _process(delta: float) -> void:
	storey_animation.handle_animation()
	for mb in bouncing_list:
		mb.bounce(delta)
	for l2d in move_line_2d_list:
		l2d.process_animation(delta)

var DonutCapsuleCount :int = 0
var WallDecoRate :float = 0
var BouncingCount :int = 0
func set_param(grid_size) -> Storey:
	DonutCapsuleCount = min(100, max(2, grid_size.x*grid_size.y/20.0) )
	WallDecoRate = 1.0/20.0
	BouncingCount = 10
	return self

var maze3d :Maze3D
var storey_num :int

var start_posi :Vector2i
var start_dir :Maze.Dir
var start_color :Color
var goal_posi :Vector2i
var goal_dir :Maze.Dir
var goal_color :Color

func is_goal_pos(p :Vector2i) -> bool:
	return goal_posi == p

func get_goal_pos() -> Vector3:
	return maze3d.mazepos2storeypos(goal_posi, 0)

func get_start_pos() -> Vector3:
	return maze3d.mazepos2storeypos(start_posi, 0)

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


func init(num :int, grid_size := GridSize, cell_size := CellSize) -> Storey:
	var sw := StopWatch.new("storey")
	var maze2d := Maze.new(grid_size)
	sw.split("maze2d")
	var floor_ceiling_height :float = cell_size.y *0.01
	maze3d = preload("res://maze_3d/maze_3d.tscn").instantiate()
	maze3d.init_params(maze2d, cell_size, cell_size.y *0.05, 1.0/(grid_size.x*grid_size.y))
	sw.split("maze3d init_params")
	maze3d.init_floor_ceiling_plane(Vector2i(1,1), floor_ceiling_height, 0.9,
		Color(RandomColorIter.get_and_next(), 0.5),
		Color(RandomColorIter.get_and_next(), 0.5),
	)
	sw.split("maze3d init_floor_ceiling")
	storey_height = cell_size.y + floor_ceiling_height * 2
	add_child(maze3d)
	if num % 2 ==0 :
		maze3d.init_with_material(TexMat.make_mainwall_mat(),TexMat.make_subwall_mat() )
	else:
		maze3d.init_with_color(
			RandomColorIter.get_and_next(), RandomColorIter.get_and_next(), RandomColorIter.get_and_next(), RandomColorIter.get_and_next())
	sw.split("maze3d init_with_material")
	maze3d.init_wall_deco(add_wall_deco_at)
	sw.split("maze3d init_wall_deco")
	storey_num = num

	놓인것들 = PlacedThings.new(maze3d.PreCalced.Grid2D)
	var 구석자리목록 :Array[Vector2i] = []
	for y in maze3d.PreCalced.Grid2D.y:
		for x in maze3d.PreCalced.Grid2D.x:
			if maze3d.maze_cells.get_open_flag_at(x,y).size() == 1:
				구석자리목록.append(Vector2i(x,y))
	sw.split("구석자리목록")

	구석자리목록.shuffle()
	sw.split("구석자리목록 shuffle")

	var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
	# floor
	start_posi = 구석자리목록.pop_back()
	start_color = RandomColorIter.get_and_next()
	start_dir = maze2d.get_open_dir_at(start_posi.x,start_posi.y).pick_random()
	maze3d.add_ladder( Vector3i(start_posi.x, -1, start_posi.y) , start_dir , start_color)
	maze3d.make_stair_hole( maze3d.get_floor(), start_posi )
	$StartMark.set_minimap_posi(start_posi).init(크기기준*0.2, 크기기준/100, start_color, "Start %d" % storey_num,
		).position = maze3d.mazepos2storeypos(start_posi, 0)
	놓인것들.set_at(start_posi, $StartMark)
	# ceiling
	goal_posi = 구석자리목록.pop_back()
	goal_color = RandomColorIter.get_and_next()
	goal_dir = Maze.DirOpppsite[maze2d.get_open_dir_at(goal_posi.x,goal_posi.y).pick_random()]
	maze3d.add_stair(Vector3i(goal_posi.x, 0, goal_posi.y), goal_dir, goal_color )
	maze3d.make_stair_hole(maze3d.get_ceiling(), goal_posi)
	sw.split("maze3d add_stair")
	$EndMark.set_minimap_posi(goal_posi).init(크기기준*0.2, 크기기준/100, goal_color, "Goal %d" % storey_num,
		).position = maze3d.mazepos2storeypos(goal_posi, 0)
	놓인것들.set_at(goal_posi, $EndMark)
	sw.split("mark")

	add_donut_capsule(DonutCapsuleCount, 구석자리목록)
	sw.split("add_donut_capsule")
	$Label3D.pixel_size = maze3d.calc_grid.unit_size.y/30
	$Label3D.text = "%d" % storey_num
	$Label3D.position = Vector3(-maze3d.WallThick*2, storey_height/2, -maze3d.WallThick*2) + maze3d.calc_grid.aabb.position
	sw.split("Label3D")
	$MiniMap.init(maze2d)
	$MiniMap.add_obj($StartMark, "Start", start_color, 1, true)
	$MiniMap.add_obj($EndMark, "Goal", goal_color, 1, true)
	sw.split("MiniMap")
	add_table4leg(구석자리목록)
	add_bouncing(BouncingCount , 크기기준 /20)
	sw.split("add_bouncing")
	#print_debug(sw)
	return self

func add_table4leg(posi_list :Array[Vector2i]) -> void:
	var unit_size := maze3d.calc_grid.unit_size
	for posi in posi_list:
		var t4l :Table4Leg = preload("res://table_4_leg/table_4_leg.tscn").instantiate()
		var thick := unit_size.y/50
		t4l.init(
			Vector3(unit_size.x/2 * randfn(1,0.5), thick, unit_size.z/2 * randfn(1,0.5)),
			Vector3(thick,unit_size.y/4 * randfn(1,0.5), thick),
			RandomColorIter.get_and_next(),RandomColorIter.get_and_next())
		add_child(t4l)
		var aabb := maze3d.calc_grid.cell_aabb_by_posi( Vector3i(posi.x, 0, posi.y) ).grow(-maze3d.WallThick)
		t4l.position = Vector3(
			CalcGrid3D.CalcAxisAlignInner(aabb, t4l.aabb.size, 0, randi_range(-1,1) ),
			CalcGrid3D.CalcAxisAlignInner(aabb, t4l.aabb.size, 1, -1 ),
			CalcGrid3D.CalcAxisAlignInner(aabb, t4l.aabb.size, 2, randi_range(-1,1) )
			)

var bouncing_list :Array
func add_bouncing(n :int, radius :float) -> void:
	bouncing_list = []
	for i in n:
		var mb :MazeBall = preload("res://maze_3d/maze_ball/maze_ball.tscn").instantiate(
			).init(maze3d, radius, radius*10, RandomColorIter.get_and_next())
		$BouncingContainer.add_child(mb)
		bouncing_list.append(mb)

func chars_enter_storey(old_storey :Storey, char_list :Array, playernum :int) -> void:
	for ch in char_list:
		ch.reparent($CharacterContainer)
		if ch.crawler_num == playernum:
			ch.enter_storey(old_storey, self, start_posi)
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
	var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
	for i in n:
		var p = 구석자리목록.pop_back()
		if p == null:
			break
		if 놓인것들.get_at(p) != null:
			continue
		var co :Color = RandomColorIter.get_and_next()
		var pobj
		if randi()%2 ==0:
			pobj = preload("res://places_things/capsule.tscn").instantiate().init(크기기준*0.3, 크기기준*0.05, co)
		else:
			pobj = preload("res://places_things/donut.tscn").instantiate().init(크기기준*0.07, 크기기준*0.15,co)
		pobj.position = maze3d.mazepos2storeypos(p, -maze3d.calc_grid.unit_size.y*0.3)
		$PlacedThings.add_child(pobj)
		놓인것들.set_at(p,pobj)


var line2d_subviewport :SubViewport
var minimap_subviewport :SubViewport
## add wall deco
var deco_order := ListIter.new(range(5))
func add_wall_deco_at(x :int, y :int, dir_flag :Maze.Flag) -> void:
	if randf() < WallDecoRate:
		match deco_order.get_and_next():
			0:
				if line2d_subviewport == null:
					line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
					$WallDeco.add_child(line2d_subviewport)
				var b := MakePlaneSubViewport(line2d_subviewport, Vector2(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y))
				$WallDeco.add_child(b)
				b.position = maze3d.deco_pos_by_dir(x,y,dir_flag)
				#b.rotate_x(PI/2)
				b.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir_flag]))
			1:
				if minimap_subviewport == null:
					minimap_subviewport = make_minimap_subvuewport(Vector2i(2000,1500))
					$WallDeco.add_child(minimap_subviewport)
				var b := MakePlaneSubViewport(minimap_subviewport, Vector2(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y))
				$WallDeco.add_child(b)
				b.position = maze3d.deco_pos_by_dir(x,y,dir_flag)
				#b.rotate_x(PI/2)
				b.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir_flag]))
			2:
				var depth := 0.1
				var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
				var n :Node3D = preload("res://calendar_3d/calendar_3d.tscn").instantiate()
				n.init(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y, depth, 크기기준/12, false)
				#n.rotate_x(PI/2)
				n.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir_flag]))
				n.position = maze3d.deco_pos_by_dir(x,y,dir_flag)
				$WallDeco.add_child(n)
			3:
				var depth := 0.1
				var 크기기준 :float = min(maze3d.calc_grid.unit_size.x, maze3d.calc_grid.unit_size.y,maze3d.calc_grid.unit_size.z)
				var n :Node3D = preload("res://analog_clock_3d/analog_clock_3d.tscn").instantiate()
				n.init(크기기준/2, depth, 크기기준/16, false)
				#n.rotate_x(PI/2)
				n.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir_flag]))
				n.position = maze3d.deco_pos_by_dir(x,y,dir_flag)
				$WallDeco.add_child(n)
				n.update_clock(AnalogClock3D.get_localtime_from_system())
			4: # make bookcase
				var n :Node3D = preload("res://wire_net/wire_net.tscn").instantiate()
				var net_size := Vector2(maze3d.calc_grid.unit_size.x-maze3d.WallThick*2,maze3d.calc_grid.unit_size.y)
				n.init(
					net_size,
					Vector2i(4,8),
					maze3d.WallThick /4, maze3d.WallThick*2 ,
					RandomColorIter.get_and_next(),
					)
				#print_debug(net_size, n.size)
				n.rotate_y(Maze.DirToRadian(Maze.FlagToDir[dir_flag]))
				var wall_shift := Maze.FlagToVt2[dir_flag]*maze3d.WallThick/2
				n.position = maze3d.deco_pos_by_dir(x,y,dir_flag) - Vector3(wall_shift.x,0,wall_shift.y)
				$WallDeco.add_child(n)

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
