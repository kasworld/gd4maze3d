extends Node3D
class_name Storey

signal goal_reached(st :Storey) # char will leave storey

static var darkcolorlist = NamedColorList.make_dark_color_list()
static var lightcolorlist = NamedColorList.make_light_color_list()

var move_animation := Animation3D.new()
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

func _to_string() -> String:
	return "Storey[%d %s]" % [storey_num, storey_setting]

func init(num :int, ss :StoreySetting, ms :Maze3DSetting ) -> Storey:
	maze3d_setting = ms
	storey_setting = ss
	
	if num % 2 ==0 :
		$Maze3D.init_with_mat(maze3d_setting, add_wall_deco_at, 
			TexMat.make_mainwall_mat(), 
			TexMat.make_subwall_mat() )
	else:
		$Maze3D.init_with_color(maze3d_setting, add_wall_deco_at, 
			darkcolorlist.pick_random()[0], 
			lightcolorlist.pick_random()[0],
			NamedColorList.color_list.pick_random()[0] )
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
	var 크기기준 = maze3d_setting.LaneW
	$StartMark.init(크기기준*1.5, 크기기준/100, darkcolorlist.pick_random()[0], "Start %d" % storey_num
		).position = maze3d_setting.mazepos2storeypos(start_pos, maze3d_setting.StoryH/2.0)
	$EndMark.init(크기기준*1.5, 크기기준/100, lightcolorlist.pick_random()[0], "Goal %d" % storey_num
		).position = maze3d_setting.mazepos2storeypos(goal_pos, maze3d_setting.StoryH/2.0)
	놓인것들.set_at(start_pos, $StartMark)
	놓인것들.set_at(goal_pos, $EndMark)

	add_donut_capsule(storey_setting.DonutCapsuleCount)
	for i in storey_setting.TreeCount:
		var p = maze3d_setting.rand_pos_2i()
		if 놓인것들.get_at(p) != null:
			continue
		add_tree(p)
	add_ball_trails(storey_setting.MeshTrailTypeList)
	$Label3D.pixel_size = maze3d_setting.StoryH/50
	$Label3D.text = "%d" % storey_num
	$Label3D.position = Vector3(-maze3d_setting.WallThick*2, maze3d_setting.StoryH/2, -maze3d_setting.WallThick*2)
	#$Label3D.position = Vector3(storey_setting.CalcMeshSize().x, maze3d_setting.StoryH/2, storey_setting.CalcMeshSize().y)
	
	$MiniMap.init(self)
	
	var shiftsize := maze3d_setting.CalcSizeV3()/2
	$Label3D.position += -shiftsize
	$WallDeco.position += -shiftsize
	return self

func chars_enter_storey(old_storey :Storey, char_list :Array, playernum :int) -> void:
	for ch in char_list:
		if ch.serial == playernum:
			ch.enter_storey(old_storey, self, start_pos)
		else:
			ch.enter_storey(old_storey, self, maze3d_setting.rand_pos_2i())
		
	$MiniMap.add_chars(char_list, playernum)
	$MiniMap.update_size()
	if old_storey != null:
		$MiniMap.set_minimap_mod(old_storey.get_mini_map().minimap_mode)
		old_storey.get_mini_map().visible = false

func act_character_list(char_list :Array, playernum :int) -> void:
	for ch in char_list:
		if ch.is_current_action_ended(): # true on act end
			ch.end_action()
			if ch.serial == playernum:
				if is_goal_pos(ch.pos_src):
					goal_reached.emit(self) #enter_next_storey()
					return
				놓인것들줍기(ch)
			get_mini_map().update_char_pos(ch)
		ch.act_character()

func get_mini_map() -> MiniMap:
	return $MiniMap

func 놓인것들줍기(ch :Crawler) -> void:
	var ft = 놓인것들.get_at(ch.pos_src)
	if ft is Donut:
		ch.enqueue_action(Crawler.Action.RollLeft)
		놓인것들.del_at(ch.pos_src)
		ft.queue_free()
	elif ft is Capsule:
		ch.enqueue_action(Crawler.Action.RollRight)
		놓인것들.del_at(ch.pos_src)
		ft.queue_free()

func add_donut_capsule(n :int) -> void:
	for i in n:
		var p = 구석자리목록.pick_random()
		if 놓인것들.get_at(p) != null:
			continue
		var co = NamedColorList.color_list.pick_random()[0]
		var pobj
		var 크기기준 = min(maze3d_setting.LaneW, maze3d_setting.StoryH)
		if randi()%2 ==0:
			pobj = preload("res://capsule.tscn").instantiate().init(크기기준*0.3, 크기기준*0.05, co)
		else:
			pobj = preload("res://donut.tscn").instantiate().init(크기기준*0.07, 크기기준*0.15,co)
		pobj.position = maze3d_setting.mazepos2storeypos(p, maze3d_setting.StoryH/4.0)
		add_child(pobj)
		놓인것들.set_at(p,pobj)

func add_tree(p :Vector2i) ->void:
	var 크기기준 = min(maze3d_setting.LaneW, maze3d_setting.StoryH)
	var tree_width := randf_range(크기기준*0.5, 크기기준*0.9)
	var tree_height := randf_range(크기기준*0.5, 크기기준*0.9)
	var bar_width = randf_range(크기기준*0.5, 크기기준*0.9)/10
	var bar_count := randi_range(20,50)
	var bar_rotation := randfn(0,PI/40)
	var bar_rotation_begin := randf_range(0, 2*PI)
	var t :BarTree2	= preload("res://bar_tree_2/bar_tree_2.tscn").instantiate().init_common_params(
		tree_width, tree_height, bar_width, bar_count, bar_rotation, bar_rotation_begin, 0, true,
	).init_with_color(random_color(), random_color())
	t.position = maze3d_setting.mazepos2storeypos(p, maze3d_setting.StoryH*0.1)
	add_child(t)
	놓인것들.set_at(p,t)

func random_color()->Color:
	#return Color(randf(),randf(),randf())
	return NamedColorList.color_list.pick_random()[0]

func add_ball_trails(mesh_type_list) ->void:
	var 크기기준 = min(maze3d_setting.LaneW, maze3d_setting.StoryH)
	for mt in mesh_type_list:
		if randf() > storey_setting.MakeMeshTrailRate:
			continue
		var pos2d := maze3d_setting.rand_pos_2i()
		var pos := maze3d_setting.mazepos2storeypos(pos2d, maze3d_setting.StoryH/2)
		var tc := randi_range(20,50)
		var bt = preload("res://mesh_trail/mesh_trail.tscn").instantiate().init_MeshGradient().init(bounce_cell, 크기기준/20, tc, mt, pos).set_speed(1,4,0.05)
		add_child(bt)

func make_cell_wallinfo(x:int, y:int) -> Array:
	var axis_wall = $Maze3D.maze_cells.make_wallinfo_for_bounce(x,y)
	var aabb = maze3d_setting.CalcCellBox(Vector2i(x,y))
	return [aabb, axis_wall]

# wallinfo [aabb , axis_wall [3][2]bool ]
func bounce_cell(oldpos:Vector3, pos :Vector3, radius :float) -> Dictionary:
	var pos2d := maze3d_setting.storeypos2mazepos(oldpos)
	var wallinfo = wall_info_all[pos2d.y][pos2d.x]
	var aabb = wallinfo[0]
	var axis_wall = wallinfo[1]
	return Bounce.v3f_wall(pos, aabb, axis_wall,radius)

var line2d_subviewport :SubViewport
var clockcalendar_sel :int
# add clock or calendar
func add_wall_deco_at(x :int, y :int, dir :EnumDir.Flag) -> void:
	if randf() < storey_setting.MakeLine2DWallRate:
		if line2d_subviewport == null:
			line2d_subviewport = make_line2d_subvuewport(Vector2i(2000,1500))
			$WallDeco.add_child(line2d_subviewport)
		var b = make_plane_from_subviewport(line2d_subviewport)
		$WallDeco.add_child(b)
		b.position = $Maze3D.deco_pos_by_dir(x,y,dir)
		b.rotate_y(EnumDir.dir2rad(EnumDir.Flag2Dir[dir]))
		return

	if randf() < storey_setting.MakeClockCalWallRate:
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
		n.position = $Maze3D.deco_pos_by_dir(x,y,dir)
		$WallDeco.add_child(n)

func make_line2d_subvuewport(size_pixel:Vector2i) -> SubViewport:
	var l2d = preload("res://move_line2d/move_line_2d.tscn").instantiate().init_with_random(300,4,1.5,size_pixel)
	l2d.start()
	var sv = SubViewport.new()
	sv.size = size_pixel
	#sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#sv.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	sv.transparent_bg = true
	sv.add_child(l2d)
	return sv

func make_plane_from_subviewport(sv :SubViewport) -> MeshInstance3D:
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(maze3d_setting.LaneW, maze3d_setting.StoryH)
	mesh.orientation = PlaneMesh.FACE_Z
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.material_override = StandardMaterial3D.new()
	sp.material_override.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	sp.material_override.albedo_texture = sv.get_texture()
	return sp

func can_move(x :int , y :int, dir :EnumDir.Dir) -> bool:
	return $Maze3D.maze_cells.is_open_dir_at(x,y, EnumDir.Dir2Flag[dir] )

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

func _process(_delta: float) -> void:
	move_animation.handle_animation()
	
