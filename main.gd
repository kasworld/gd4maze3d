extends Node3D

var storey_scene = preload("res://storey.tscn")
var maze_size = Vector2i(32,18)
const StoreyCount = 7
const StoreyPlay = int(StoreyCount/2)
var storey_list :Array[Storey]

func new_storey()->Storey:
	var st = storey_scene.instantiate()
	add_child(st)
	st.init(maze_size)
	return st

var minimap_scene = preload("res://mini_map.tscn")
var minimap :MiniMap

var minimap2draw_scene = preload("res://mini_map_2_draw.tscn")
var minimap2draw :MiniMap2Draw

var character_scene = preload("res://character.tscn")
const PlayerCount = 10
var player_list :Array[Character]

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
		if i == 0:
			pl.init(true, true)
		else :
			pl.init(false, true)
	for i in StoreyCount:
		var st = new_storey()
		storey_list.append(st)
	enter_new_storey()

func enter_new_storey()->void:
	var todelst = storey_list.pop_front()
	remove_child(todelst)
	todelst.queue_free()
	var toaddst = new_storey()
	storey_list.push_back(toaddst)
	for i in StoreyCount:
		storey_list[i].view_floor_ceiling(false,false)
	storey_list[0].view_floor_ceiling(true,false)
	storey_list[StoreyCount-1].view_floor_ceiling(false,true)

	var cur_storey = storey_list[StoreyPlay]
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

	minimap.position.y = ProjectSettings.get_setting("display/window/size/viewport_height")-minimap.get_height()
	minimap2draw.position.y = minimap.position.y

func _process(_delta: float) -> void:
	var cur_storey = storey_list[StoreyPlay]
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
	update_info(player_list[0])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

		elif event.keycode == KEY_1:
			full_minimap = !full_minimap
			set_minimap_mode()
		elif event.keycode == KEY_2:
			view_floor_ceiling = !view_floor_ceiling
			storey_list[StoreyPlay].view_floor_ceiling(view_floor_ceiling,view_floor_ceiling)
		elif event.keycode == KEY_3:
			player_list[0].auto_move = !player_list[0].auto_move

		elif event.keycode == KEY_UP:
			player_list[0].queue_act(Character.Act.Forward)
		elif event.keycode == KEY_DOWN:
			player_list[0].queue_act(Character.Act.TurnLeft)
			player_list[0].queue_act(Character.Act.TurnLeft)
		elif event.keycode == KEY_LEFT:
			player_list[0].queue_act(Character.Act.TurnLeft)
		elif event.keycode == KEY_RIGHT:
			player_list[0].queue_act(Character.Act.TurnRight)

		elif event.keycode == KEY_SPACE:
			player_list[0].queue_act(Character.Act.RotateCameraRight)
			#player_list[0].queue_act(Character.Act.RotateCameraRight)
		elif event.keycode == KEY_ENTER:
			enter_new_storey()

		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass

func update_info(pl :Character)->void:
	$Label.text = "fullminimap:%s, single storey view:%s\n%s" % [
		full_minimap, view_floor_ceiling,
		pl.info_str()]

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
	var posy = i - StoreyPlay
	storey_list[i].position.y = lerpf(posy+1, posy, dur)

# dur : 0 - 1 :second
func animate_move_by_dur(pl :Character, dur :float)->void:
	pl.position = pl.calc_animate_move_by_dur(dur)

# dur : 0 - 1 :second
func animate_turn_by_dur(pl :Character, dur :float)->void:
	pl.rotation.y = pl.calc_animate_turn_by_dur(dur)

func animate_rotate_camera_by_dur(pl :Character, dur :float)->void:
	pl.rotate_camera(pl.calc_animate_camera_rotate(dur))
