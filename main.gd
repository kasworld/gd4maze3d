extends Node3D

# main params
const PlayerCount = 10
const VisibleStoreyUp :int = 3
const VisibleStoreyDown :int = 3
var maze_size = Vector2i(16*1,9*1)
var storey_h :float = 3.0
var lane_w :float = 4.0
var wall_thick :float = lane_w *0.05

var storey_scene = preload("res://storey.tscn")
var storey_list :Array[Storey]
var cur_storey_index :int = -1 # +1 on enter_new_storey
func get_cur_storey()->Storey:
	return storey_list[cur_storey_index]

# thread unsafe
func add_new_storey(stnum :int, msize :Vector2i, h :float, lw :float, wt :float)->void:
	var st = new_storey(stnum,msize,h,lw,wt)
	if stnum > 0 :
		st.set_start_pos(storey_list[-1].goal_pos)
	st.position.y = storey_h * stnum
	storey_list.append(st)
	add_child(st)

# thread safe
func new_storey(stnum :int, msize :Vector2i, h :float, lw :float, wt :float)->Storey:
	var gp = rand_pos()
	var stp = rand_pos()
	var st = storey_scene.instantiate()
	st.init(stnum, msize, h, lw, wt, stp, gp)
	return st

#func del_old_storey()->void:
	#var st = storey_list.pop_front()
	#remove_child(st)
	#st.queue_free()

func hide_old_storey()->void:
	if visible_down_index()-1 >=0 :
		storey_list[visible_down_index()-1].visible = false
func visible_down_index()->int:
	var rtn = cur_storey_index - VisibleStoreyDown
	if rtn < 0:
		return 0
	return rtn

func rand_pos()->Vector2i:
	return Vector2i(randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1) )

var minimap_scene = preload("res://mini_map.tscn")
var minimap :MiniMap

var character_scene = preload("res://character.tscn")
var player_list :Array[Character]
func get_main_char()->Character:
	return player_list[0]

var full_minimap :bool
func set_minimap_mode()->void:
	if full_minimap:
		minimap.view_full_map()
	else:
		minimap.view_known_map()

func _ready() -> void:
	var meshx = maze_size.x*lane_w +wall_thick*2
	var meshy = maze_size.y*lane_w +wall_thick*2

	var mat_keys = Texmat.floor_mat_dict.keys()
	mat_keys.shuffle()
	$Floor.mesh.size = Vector2(meshx, meshy)
	$Floor.position = Vector3(meshx/2, 0, meshy/2)
	$Floor.mesh.material = Texmat.floor_mat_dict[mat_keys[0]].duplicate()
	$Floor.mesh.material.uv1_scale = Vector3(maze_size.x,(maze_size.x+maze_size.y)/2.0,maze_size.y)

	mat_keys = Texmat.ceiling_mat_dict.keys()
	mat_keys.shuffle()
	$Ceiling.mesh.size = Vector2(meshx, meshy)
	$Ceiling.position = Vector3(meshx/2, storey_h, meshy/2)
	$Ceiling.mesh.material = Texmat.ceiling_mat_dict[mat_keys[1]].duplicate()
	$Ceiling.mesh.material.uv1_scale = $Floor.mesh.material.uv1_scale

	for i in PlayerCount:
		var pl = character_scene.instantiate()
		player_list.append(pl)
		add_child(pl)
		if i == 0: # set is_player
			pl.init(lane_w, true, true)
		else :
			pl.init(lane_w, false, true)

	var use_thread = false
	if use_thread:
		var thread_list = []
		for i in VisibleStoreyUp:
			var th = Thread.new()
			thread_list.append(th)
			th.start(new_storey.bind(i,maze_size,storey_h,lane_w,wall_thick))
		storey_list.resize(VisibleStoreyUp)
		for th in thread_list:
			var st = th.wait_to_finish()
			storey_list[st.storey_num]=st
			add_child(st)
		thread_list.resize(0)
		for st in storey_list:
			if st.storey_num > 0 :
				st.set_start_pos(storey_list[st.storey_num-1].goal_pos)
			st.position.y = storey_h * st.storey_num
	else :
		for i in VisibleStoreyUp:
			add_new_storey(i,maze_size,storey_h,lane_w,wall_thick)

	get_viewport().size_changed.connect(_on_vpsize_changed)
	enter_new_storey()

var vp_size :Vector2
func _on_vpsize_changed()->void:
	vp_size = get_viewport().get_visible_rect().size

	var cur_storey = get_cur_storey()
	var map_scale = min( vp_size.x / cur_storey.maze_size.x , vp_size.y / cur_storey.maze_size.y )
	minimap.change_scale(map_scale)

	minimap.position.y = (vp_size.y -minimap.get_height())/2
	minimap.position.x = (vp_size.x - minimap.get_width())/2

func enter_new_storey()->void:
	cur_storey_index +=1
	hide_old_storey()
	add_new_storey(storey_list.size(), maze_size,storey_h,lane_w,wall_thick)
	$Floor.position.y = visible_down_index()*storey_h
	$Ceiling.position.y = storey_list.size()*storey_h
	change_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)

	vp_size = get_viewport().get_visible_rect().size
	var cur_storey = get_cur_storey()
	var map_scale = min( vp_size.x / cur_storey.maze_size.x , vp_size.y / cur_storey.maze_size.y )
	if minimap != null:
		minimap.queue_free()
	minimap = minimap_scene.instantiate()
	add_child(minimap)
	minimap.init(cur_storey,map_scale)

	for i in PlayerCount:
		player_list[i].enter_storey(cur_storey)
		animate_move_by_dur(player_list[i], 0)
		animate_turn_by_dur(player_list[i], 0)
	set_minimap_mode()
	_on_vpsize_changed()

var view_floor_ceiling :bool = true
func change_floor_ceiling_visible(f :bool,c :bool)->void:
	for i in storey_list.size():
		storey_list[i].view_floor_ceiling(f,c)
	storey_list[0].view_floor_ceiling(false,c)
	storey_list[-1].view_floor_ceiling(f,false)

func _process(delta: float) -> void:
	var cur_storey = get_cur_storey()
	move_character(cur_storey)
	update_info()

func move_character(cur_storey :Storey)->void:
	for i in PlayerCount:
		var pl = player_list[i]
		var ani_dur = pl.get_ani_dur()
		if pl.act_end(ani_dur): # true on act end
			if pl.is_player:
				if cur_storey.is_goal_pos(pl.pos_src):
					enter_new_storey()
					return
				if cur_storey.is_capsule_pos(pl.pos_src) : # capsule encounter
					pl.queue_act(Character.Act.RotateCameraRight)
					cur_storey.remove_capsule_at(pl.pos_src)
				if cur_storey.is_donut_pos(pl.pos_src) : # donut encounter
					pl.queue_act(Character.Act.RotateCameraLeft)
					cur_storey.remove_donut_at(pl.pos_src)
				minimap.move_player(pl.pos_src.x, pl.pos_src.y)
				pl.rotation.y = snapped(pl.rotation.y, PI/2)
		pl.ai_act()
		if pl.start_new_act(): # new act start
			ani_dur = 0
			if pl.is_player and pl.act_current != Character.Act.EnterStorey:
				var walldir = cur_storey.maze_cells.get_wall_dir_at(pl.pos_src.x,pl.pos_src.y)
				for d in walldir:
					minimap.add_wall_at(pl.pos_src.x,pl.pos_src.y,Storey.MazeDir2Dir[d])
		if pl.act_current != Character.Act.None :
			animate_act(pl, ani_dur)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

		elif event.keycode == KEY_1:
			help_on = !help_on
		elif event.keycode == KEY_2:
			full_minimap = !full_minimap
			set_minimap_mode()
		elif event.keycode == KEY_3:
			view_floor_ceiling = !view_floor_ceiling
			change_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)
		elif event.keycode == KEY_4:
			get_main_char().auto_move = !get_main_char().auto_move
		elif event.keycode == KEY_5:
			debug_on = !debug_on
		elif event.keycode == KEY_6:
			perfo_on = !perfo_on
		elif event.keycode == KEY_7:
			info_on = !info_on
		#elif event.keycode == KEY_8:
			#get_tree().root.use_occlusion_culling = not get_tree().root.use_occlusion_culling

		elif event.keycode == KEY_UP:
			get_main_char().queue_act(Character.Act.Forward)
		elif event.keycode == KEY_DOWN:
			get_main_char().queue_act(Character.Act.TurnLeft)
			get_main_char().queue_act(Character.Act.TurnLeft)
		elif event.keycode == KEY_LEFT:
			get_main_char().queue_act(Character.Act.TurnLeft)
		elif event.keycode == KEY_RIGHT:
			get_main_char().queue_act(Character.Act.TurnRight)

		elif event.keycode == KEY_SPACE:
			get_main_char().queue_act(Character.Act.RotateCameraRight)
		elif event.keycode == KEY_ENTER:
			enter_new_storey()

		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass

var help_on :bool = true
func help_str()->String:
	return """gd4maze3d 10.0.0
Space:RotateCamera, Enter:Next storey,
1:Toggle help, 2:Minimap, 3:ViewFloorCeiling, 4:Toggle automove, 5:Toggle debug info, 6:Toggle Perfomance info, 7:info
ArrowKey to move
"""
var debug_on :bool
var perfo_on :bool
func performance_info()->String:
	return 	"""%d FPS (%.2f mspf)
Currently rendering: occlusion culling:%s
%d objects
%dK primitive indices
%d draw calls
""" % [
	Engine.get_frames_per_second(),1000.0 / Engine.get_frames_per_second(),
	get_tree().root.use_occlusion_culling,
	RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
	RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) * 0.001,
	RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
]
var info_on :bool
func update_info()->void:
	var helpstr = ""
	if help_on:
		helpstr = help_str()
	var debugstr = ""
	if debug_on:
		debugstr = get_main_char().debug_str()
	var perfo_str = ""
	if perfo_on:
		perfo_str = performance_info()
	var info_s = ""
	if info_on :
		info_s = info_str()
	$Label.text = "%s%s%s%s" % [
		info_s,
		helpstr, debugstr,
		perfo_str,
		]

func info_str()->String:
	return """storey %d/%d, fullminimap:%s, single storey view:%s
storey %s
%s
""" % [
		cur_storey_index,storey_list.size(),
		full_minimap, view_floor_ceiling,
		get_cur_storey().info_str(),
		get_main_char().info_str(),
		]

func animate_act(pl :Character, dur :float)->void:
	match pl.act_current:
		Character.Act.Forward:
			animate_move_by_dur(pl, dur)
		Character.Act.TurnLeft, Character.Act.TurnRight:
			animate_turn_by_dur(pl, dur)
		Character.Act.RotateCameraRight,Character.Act.RotateCameraLeft:
			animate_rotate_camera_by_dur(pl,dur)
		Character.Act.EnterStorey:
			animate_move_storey_by_dur(pl, dur)

# dur : 0 - 1 :second
func animate_move_by_dur(pl :Character, dur :float)->void:
	pl.position = pl.calc_animate_move_by_dur(dur)

func animate_move_storey_by_dur(pl :Character, dur :float)->void:
	var from = cur_storey_index -1
	pl.position = pl.calc_animate_move_storey_by_dur(dur, from)

# dur : 0 - 1 :second
func animate_turn_by_dur(pl :Character, dur :float)->void:
	pl.rotation.y = pl.calc_animate_turn_by_dur(dur)

func animate_rotate_camera_by_dur(pl :Character, dur :float)->void:
	pl.rotate_camera(pl.calc_animate_camera_rotate(dur))
