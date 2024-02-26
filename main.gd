extends Node3D

var storey_scene = preload("res://storey.tscn")
var maze_size = Vector2i(32*1,18*1)
var storey_h :float = 3.0
var lane_w :float = 4.0
var wall_thick :float = lane_w *0.05
const StoreyCount :int = 7
const StoreyPlay :int = int(StoreyCount/2)
var storey_list :Array[Storey]
func get_cur_storey()->Storey:
	return storey_list[StoreyPlay]
func add_new_storey(msize :Vector2i, h :float, lw :float, wt :float, stp :Vector2i, gp :Vector2i)->void:
	var st = storey_scene.instantiate()
	add_child(st)
	st.init(msize,h,lw,wt,stp,gp)
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
	for i in PlayerCount:
		var pl = character_scene.instantiate()
		player_list.append(pl)
		add_child(pl)
		if i == 0: # set is_player
			pl.init(true, true)
		else :
			pl.init(false, true)
	for i in StoreyCount:
		add_new_storey(maze_size,storey_h,lane_w,wall_thick,rand_pos(),rand_pos())
	get_viewport().size_changed.connect(vpsize_changed)
	enter_new_storey()

func vpsize_changed()->void:
	minimap.position.y = get_viewport().get_visible_rect().size.y -minimap.get_height()
	minimap2draw.position.y = minimap.position.y

func enter_new_storey()->void:
	del_old_storey()
	add_new_storey(maze_size,storey_h,lane_w,wall_thick,rand_pos(),rand_pos())
	for i in StoreyCount:
		storey_list[i].view_floor_ceiling(false,false)
	storey_list[0].view_floor_ceiling(true,false)
	storey_list[StoreyCount-1].view_floor_ceiling(false,true)

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

func update_info(dur :float)->void:
	$Label.text = "fullminimap:%s, single storey view:%s, FPS:%f\nstorey %s\n%s" % [
		full_minimap, view_floor_ceiling, 1.0/dur,
		get_cur_storey().info_str(),
		get_main_char().info_str()]

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
				for i in StoreyCount:
					animate_storey_y_by_dur(i,dur)

# dur : 0 - 1 :second
func animate_storey_y_by_dur(i :int, dur :float)->void:
	var storey_h = storey_list[i].storey_h
	var posy = (i - StoreyPlay)*storey_h
	storey_list[i].position.y = lerpf(posy+storey_h, posy, dur)

# dur : 0 - 1 :second
func animate_move_by_dur(pl :Character, dur :float)->void:
	pl.position = pl.calc_animate_move_by_dur(dur)

# dur : 0 - 1 :second
func animate_turn_by_dur(pl :Character, dur :float)->void:
	pl.rotation.y = pl.calc_animate_turn_by_dur(dur)

func animate_rotate_camera_by_dur(pl :Character, dur :float)->void:
	pl.rotate_camera(pl.calc_animate_camera_rotate(dur))
