extends Node3D

# main params
var maze_size = Vector2i(32*1,18*1)
var storey_h :float = 3.0
var lane_w :float = 4.0
var wall_thick :float = lane_w *0.05
const InitialStoreyCount :int = 3 # +1 on enter_new_storey
const MaxStoreyCount :int = InitialStoreyCount *3
var cur_storey_index :int = -1 # +1 on enter_new_storey

var tex_dict = {
	brownbrick = preload("res://image/brownbrick50.png"),
	bluestone = preload("res://image/bluestone50.png"),
	drymud = preload("res://image/drymud50.png"),
	graystone = preload("res://image/graystone50.png"),
	pinkstone = preload("res://image/pinkstone50.png"),
	greenstone = preload("res://image/greenstone50.png"),
	ice50 = preload("res://image/ice50.png")
}

var storey_scene = preload("res://storey.tscn")
var storey_list :Array[Storey]
func get_cur_storey()->Storey:
	return storey_list[cur_storey_index]
func add_new_storey(msize :Vector2i, h :float, lw :float, wt :float)->void:
	var gp = rand_pos()
	var stp = rand_pos()
	if storey_list.size() > 0 :
		stp = storey_list[-1].goal_pos
	var st = storey_scene.instantiate()
	add_child(st)
	st.init(msize,h,lw,wt,stp,gp)
	st.view_floor_ceiling(false,false)
	storey_list.append(st)
func del_old_storey()->void:
	var st = storey_list.pop_front()
	remove_child(st)
	st.queue_free()
func rand_pos()->Vector2i:
	return Vector2i(randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1) )

var minimap_scene = preload("res://mini_map.tscn")
var minimap :MiniMap

var minimap2draw_scene = preload("res://mini_map_2_draw.tscn")
var minimap2draw :MiniMap2Draw

var character_scene = preload("res://character.tscn")
const PlayerCount = 10
var player_list :Array[Character]
func get_main_char()->Character:
	return player_list[0]

var full_minimap :bool
func set_minimap_mode()->void:
	minimap.visible = full_minimap
	minimap2draw.visible = !minimap.visible

var view_floor_ceiling :bool

func _ready() -> void:
	var tex_keys = tex_dict.keys()
	tex_keys.shuffle()
	$Floor.mesh.size = Vector2(maze_size.x*lane_w, maze_size.y*lane_w)
	$Floor.position = Vector3(maze_size.x*lane_w/2.0, 0, maze_size.y*lane_w/2.0)
	$Floor.mesh.material.albedo_texture = tex_dict[tex_keys[0]]
	#$Floor.mesh.material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA

	$Ceiling.mesh.size = $Floor.mesh.size
	$Ceiling.position = Vector3(maze_size.x*lane_w/2.0, storey_h, maze_size.y*lane_w/2.0)
	$Ceiling.mesh.material.albedo_texture = tex_dict[tex_keys[1]]
	#$Ceiling.mesh.material.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA

	for i in PlayerCount:
		var pl = character_scene.instantiate()
		player_list.append(pl)
		add_child(pl)
		if i == 0: # set is_player
			pl.init(true, true)
		else :
			pl.init(false, true)
	for i in InitialStoreyCount:
		add_new_storey(maze_size,storey_h,lane_w,wall_thick)
	get_viewport().size_changed.connect(vpsize_changed)
	enter_new_storey()

func vpsize_changed()->void:
	minimap.position.y = get_viewport().get_visible_rect().size.y -minimap.get_height()
	minimap2draw.position.y = minimap.position.y

func enter_new_storey()->void:
	if storey_list.size() >= MaxStoreyCount:
		del_old_storey()
	else :
		cur_storey_index +=1
	add_new_storey(maze_size,storey_h,lane_w,wall_thick)
	for i in storey_list.size():
		storey_list[i].view_floor_ceiling(false,false)
	$Floor.position.y = -storey_h * cur_storey_index
	$Ceiling.position.y = storey_h * (storey_list.size()-cur_storey_index)

	var cur_storey = get_cur_storey()
	if minimap != null:
		minimap.queue_free()
	minimap = minimap_scene.instantiate()
	add_child(minimap)
	minimap.init(cur_storey)

	if minimap2draw != null:
		minimap2draw.queue_free()
	minimap2draw = minimap2draw_scene.instantiate()
	add_child(minimap2draw)
	minimap2draw.init(cur_storey)

	for i in PlayerCount:
		player_list[i].enter_storey(cur_storey)
		animate_move_by_dur(player_list[i], 0)
		animate_turn_by_dur(player_list[i], 0)
	set_minimap_mode()

	vpsize_changed()

func _process(delta: float) -> void:
	var cur_storey = get_cur_storey()
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
					#pl.queue_act(Character.Act.RotateCameraRight)
					cur_storey.remove_capsule_at(pl.pos_src)
				if cur_storey.is_donut_pos(pl.pos_src) : # donut encounter
					#pl.queue_act(Character.Act.RotateCameraLeft)
					pl.queue_act(Character.Act.RotateCameraLeft)
					cur_storey.remove_donut_at(pl.pos_src)
				minimap.move_player(pl.pos_src.x, pl.pos_src.y)
				minimap2draw.move_player(pl.pos_src.x, pl.pos_src.y)
				pl.rotation.y = snapped(pl.rotation.y, PI/2)
		pl.ai_act()
		if pl.start_new_act(): # new act start
			ani_dur = 0
			if pl.is_player and pl.act_current != Character.Act.EnterStorey:
				var walldir = cur_storey.maze_cells.get_wall_dir_at(pl.pos_src.x,pl.pos_src.y)
				for d in walldir:
					minimap2draw.add_wall_at(pl.pos_src.x,pl.pos_src.y,Storey.MazeDir2Dir[d])
		if pl.act_current != Character.Act.None :
			animate_act(pl, ani_dur)
	update_info(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

		elif event.keycode == KEY_1:
			full_minimap = !full_minimap
			set_minimap_mode()
		elif event.keycode == KEY_2:
			view_floor_ceiling = !view_floor_ceiling
			get_cur_storey().view_floor_ceiling(view_floor_ceiling,view_floor_ceiling)
		elif event.keycode == KEY_3:
			get_main_char().auto_move = !get_main_char().auto_move
		elif event.keycode == KEY_H:
			help_on = !help_on
		elif event.keycode == KEY_D:
			debug_on = !debug_on

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
			#get_main_char().queue_act(Character.Act.RotateCameraRight)
		elif event.keycode == KEY_ENTER:
			enter_new_storey()

		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass

var help_on :bool = true
var debug_on :bool
func update_info(dur :float)->void:
	var helpstr = ""
	if help_on:
		helpstr = help_str()
	var debugstr = ""
	if debug_on:
		debugstr = get_main_char().debug_str()
	$Label.text = "storey %d/%d, fullminimap:%s, single storey view:%s, FPS:%f\nstorey %s\n%s\n%s\n%s" % [
		cur_storey_index,storey_list.size(), full_minimap, view_floor_ceiling, 1.0/dur,
		get_cur_storey().info_str(),
		get_main_char().info_str(),
		helpstr, debugstr,
		]

func help_str()->String:
	return "gd4maze3d 3.1.0\nArrowKey to move\n1:Minimap, 2:ViewFloorCeiling, 3:Toggle automove\nSpace:RotateCamera, Enter:Next storey, H:Toggle help, D:Toggle debuginfo"

func animate_act(pl :Character, dur :float)->void:
	match pl.act_current:
		Character.Act.Forward:
			animate_move_by_dur(pl, dur)
		Character.Act.TurnLeft, Character.Act.TurnRight:
			animate_turn_by_dur(pl, dur)
		Character.Act.RotateCameraRight,Character.Act.RotateCameraLeft:
			animate_rotate_camera_by_dur(pl,dur)
		Character.Act.EnterStorey:
			animate_move_by_dur(pl, dur)
			if pl.is_player:
				for i in storey_list.size():
					animate_storey_y_by_dur(i,dur)

# dur : 0 - 1 :second
func animate_storey_y_by_dur(i :int, dur :float)->void:
	var sth = storey_list[i].storey_h
	var posy = (i - cur_storey_index)*sth
	storey_list[i].position.y = lerpf(posy+sth, posy, dur)

# dur : 0 - 1 :second
func animate_move_by_dur(pl :Character, dur :float)->void:
	pl.position = pl.calc_animate_move_by_dur(dur)

# dur : 0 - 1 :second
func animate_turn_by_dur(pl :Character, dur :float)->void:
	pl.rotation.y = pl.calc_animate_turn_by_dur(dur)

func animate_rotate_camera_by_dur(pl :Character, dur :float)->void:
	pl.rotate_camera(pl.calc_animate_camera_rotate(dur))
