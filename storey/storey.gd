extends Node3D
class_name Storey

static var themecolorlist = [
	NamedColorList.make_red_color_list(),
	NamedColorList.make_green_color_list(),
	NamedColorList.make_blue_color_list(),
	NamedColorList.make_cyan_color_list(),
	NamedColorList.make_magenta_color_list(),
	NamedColorList.make_yellow_color_list(),
]
func random_color()->Color:
	return themecolorlist.pick_random().pick_random()[0]

var storey_animation := Animation3D.new()
func _process(delta: float) -> void:
	storey_animation.handle_animation()
	for t in tree_list:
		t.rotate_tree_bar_y(0.1)
	for mt in mesh_trail_list:
		mt.move_trail(delta, bounce_cell, trailmesh_radius, 4*PI,)

var maze3d_setting :Maze3DSetting
var storey_setting :StoreySetting
var storey_num :int
var start_pos :Vector2i
var goal_pos :Vector2i
func is_goal_pos(p :Vector2i) -> bool:
	return goal_pos == p

var wall_info_all :Array
var 놓인것들 :PlacedThings # 배치된 capsule, donut tree start goal 들
var 구석자리목록 :Array[Vector2i] # capsule, donut 배치 가능 위치 목록
var tree_list :Array

func _to_string() -> String:
	return "Storey[%d %s]" % [storey_num, storey_setting]

func init(num :int, ss :StoreySetting, ms :Maze3DSetting) -> Storey:
	maze3d_setting = ms
	storey_setting = ss

	if num % 2 ==0 :
		$Maze3D.init_with_mat(maze3d_setting, add_wall_deco_at,
			TexMat.make_mainwall_mat(),
			TexMat.make_subwall_mat() )
	else:
		$Maze3D.init_with_color(maze3d_setting, add_wall_deco_at,
			random_color(), random_color(), random_color(),
		)
	storey_num = num

	놓인것들 = PlacedThings.new(maze3d_setting.MazeSize)
	wall_info_all = []
	for y in maze3d_setting.MazeSize.y:
		wall_info_all.append([])
		for x in maze3d_setting.MazeSize.x:
			wall_info_all[y].append( make_cell_wallinfo(x,y) )
			if $Maze3D.maze_cells.get_open_dir_at(x,y).size() == 1:
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
	var 크기기준 := maze3d_setting.LaneW
	$StartMark.init(크기기준*0.2, 크기기준/100, random_color(), "Start %d" % storey_num
		).position = maze3d_setting.mazepos2storeypos(start_pos, maze3d_setting.StoryH/2.0)
	$EndMark.init(크기기준*0.2, 크기기준/100, random_color(), "Goal %d" % storey_num
		).position = maze3d_setting.mazepos2storeypos(goal_pos, maze3d_setting.StoryH/2.0)
	놓인것들.set_at(start_pos, $StartMark)
	놓인것들.set_at(goal_pos, $EndMark)

	add_donut_capsule(storey_setting.DonutCapsuleCount)
	for i in storey_setting.TreeCount:
		var p = maze3d_setting.rand_pos_2i()
		if 놓인것들.get_at(p) != null:
			continue
		add_tree(p)
	add_mesh_trails(storey_setting.MeshTrailTypeList)
	$Label3D.pixel_size = maze3d_setting.StoryH/50
	$Label3D.text = "%d" % storey_num
	$Label3D.position = Vector3(-maze3d_setting.WallThick*2, maze3d_setting.StoryH/2, -maze3d_setting.WallThick*2)
	$MiniMap.init(self)

	var shiftsize := maze3d_setting.CalcSizeV3()/2
	$Label3D.position += -shiftsize
	$WallDeco.position += -shiftsize
	return self

func chars_enter_storey(old_storey :Storey, char_list :Array, playernum :int) -> void:
	for ch in char_list:
		ch.reparent($CharacterContainer)
		if ch.crawler_num == playernum:
			ch.enter_storey(old_storey, self, start_pos)
		else:
			ch.enter_storey(old_storey, self, maze3d_setting.rand_pos_2i())

	$MiniMap.add_chars(char_list, playernum)
	$MiniMap.update_size()
	if old_storey != null:
		$MiniMap.set_minimap_mod(old_storey.get_mini_map().minimap_mode)
		old_storey.get_mini_map().visible = false

func get_char_list() -> Array:
	return $CharacterContainer.get_children()

func get_mini_map() -> MiniMap:
	return $MiniMap

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

func add_donut_capsule(n :int) -> void:
	for i in n:
		var p = 구석자리목록.pick_random()
		if 놓인것들.get_at(p) != null:
			continue
		var co :Color = NamedColorList.color_list.pick_random()[0]
		var pobj
		var 크기기준 :float = min(maze3d_setting.LaneW, maze3d_setting.StoryH)
		if randi()%2 ==0:
			pobj = preload("res://places_things/capsule.tscn").instantiate().init(크기기준*0.3, 크기기준*0.05, co)
		else:
			pobj = preload("res://places_things/donut.tscn").instantiate().init(크기기준*0.07, 크기기준*0.15,co)
		pobj.position = maze3d_setting.mazepos2storeypos(p, maze3d_setting.StoryH/4.0)
		add_child(pobj)
		놓인것들.set_at(p,pobj)

func add_tree(p :Vector2i) ->void:
	var 크기기준 = min(maze3d_setting.LaneW, maze3d_setting.StoryH)
	var tree_width := randf_range(크기기준*0.5, 크기기준*0.9)
	var tree_height := randf_range(크기기준*0.5, 크기기준*0.9)
	var bar_width = randf_range(크기기준*0.5, 크기기준*0.9)/10
	var bar_count := randi_range(20,50)
	#var bar_rotation := randfn(0,PI/40)
	#var bar_rotation_begin := randf_range(0, 2*PI)
	var t :BarTree	= preload("res://bar_tree/bar_tree.tscn").instantiate(
		).init_bartree_with_color(random_color(), random_color(),bar_count
		).init_bartree_transform( Vector3(tree_width, tree_height, bar_width), 0)
	t.position = maze3d_setting.mazepos2storeypos(p, maze3d_setting.StoryH*0.1)
	add_child(t)
	놓인것들.set_at(p,t)
	tree_list.append(t)

var trailmesh_radius := 1.0
var mesh_trail_list :Array
func add_mesh_trails(mesh_type_list) ->void:
	trailmesh_radius = min(maze3d_setting.LaneW, maze3d_setting.StoryH) /20
	var mesh := BoxMesh.new()
	mesh.material = MultiMeshShape.make_color_material(1.0)
	mesh.size = Vector3(trailmesh_radius*2, trailmesh_radius*2, trailmesh_radius/10)
	for mt in mesh_type_list:
		if randf() > storey_setting.MakeMeshTrailRate:
			continue
		var pos2d := maze3d_setting.rand_pos_2i()
		var pos := maze3d_setting.mazepos2storeypos(pos2d, maze3d_setting.StoryH/2)
		var tc := randi_range(20,50)
		var bt :MeshTrail = preload("res://mesh_trail/mesh_trail.tscn").instantiate(
			).set_ColorChange_MeshGradient().init_with_color_mesh(mesh, tc, true, pos).set_speed(1,4)
		add_child(bt)
		mesh_trail_list.append(bt)

func make_cell_wallinfo(x:int, y:int) -> Array:
	var axis_wall :Array = $Maze3D.maze_cells.make_wallinfo_for_bounce(x,y)
	var aabb := maze3d_setting.CalcCellBox(Vector2i(x,y))
	return [aabb, axis_wall]

# wallinfo [aabb , axis_wall [3][2]bool ]
func bounce_cell(oldpos:Vector3, pos :Vector3, radius :float) -> Dictionary:
	var pos2d := maze3d_setting.storeypos2mazepos(oldpos)
	var wallinfo :Array = wall_info_all[pos2d.y][pos2d.x]
	var aabb :AABB= wallinfo[0]
	var axis_wall :Array = wallinfo[1]
	return Bounce.v3f_wall(pos, aabb, axis_wall,radius)

var line2d_subviewport :SubViewport
var clockcalendar_sel :int
# add clock or calendar
func add_wall_deco_at(x :int, y :int, dir :EnumDir.Flag) -> void:
	if randf() < storey_setting.MakeLine2DWallRate:
		if line2d_subviewport == null:
			line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
			$WallDeco.add_child(line2d_subviewport)
		var b := make_plane_from_subviewport(line2d_subviewport)
		$WallDeco.add_child(b)
		b.position = $Maze3D.deco_pos_by_dir(x,y,dir)
		b.rotate_y(EnumDir.DirToRadian(EnumDir.FlagToDir[dir]))
		return

	if randf() < storey_setting.MakeClockCalWallRate:
		var n :Node3D
		var depth := 0.1
		var 기준크기 :float = min(maze3d_setting.LaneW, maze3d_setting.StoryH)
		clockcalendar_sel +=1
		if clockcalendar_sel % 2 == 0:
			n = preload("res://calendar_3d/calendar_3d.tscn").instantiate()
			n.init(maze3d_setting.LaneW, maze3d_setting.StoryH,
				depth, 기준크기/12, false)
		else :
			n = preload("res://analog_clock_3d/analog_clock_3d.tscn").instantiate()
			n.init(기준크기/2, depth, 기준크기/16, 9.0, false)
		n.rotate_z(PI/2)
		n.rotate_y(EnumDir.DirToRadian(1+EnumDir.FlagToDir[dir]))
		n.position = $Maze3D.deco_pos_by_dir(x,y,dir)
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
	mesh.size = Vector2(maze3d_setting.LaneW, maze3d_setting.StoryH)
	mesh.orientation = PlaneMesh.FACE_Z
	var sp := MeshInstance3D.new()
	sp.mesh = mesh
	sp.material_override = StandardMaterial3D.new()
	sp.material_override.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	sp.material_override.albedo_texture = sv.get_texture()
	return sp

func view_floor_ceiling(f :bool,c :bool) -> void:
	$Maze3D.view_floor_ceiling(f,c)

func view_walls(w :bool) -> void:
	$Maze3D.view_walls(w)

func view_pillars(w :bool) -> void:
	$Maze3D.view_pillars(w)

func set_wallview_mode(w :Maze3D.WallView) -> void:
	$Maze3D.set_wallview_mode(w)

func get_maze_cells() -> Maze:
	return $Maze3D.maze_cells
