extends Node3D

# stats
var storey_score :int

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
	if full_minimap:
		minimap.visible = true
		minimap2draw.visible = false
	else :
		minimap.visible = false
		minimap2draw.visible = true

var view_floor_ceiling :bool

func _ready() -> void:
	for i in PlayerCount:
		var pl = character_scene.instantiate()
		player_list.append(pl)
		add_child(pl)
		pl.auto_move = true
	start_new_maze()

func start_new_maze()->void:
	for st in storey_list:
		st.queue_free()
	storey_list.resize(0)
	for i in StoreyCount:
		var posy = i - StoreyPlay
		var st = new_storey()
		st.view_floor_ceiling(false,false)
		st.position.y = posy
		storey_list.append(st)
	storey_list[0].view_floor_ceiling(true,false)
	storey_list[StoreyCount-1].view_floor_ceiling(false,true)

	if minimap != null:
		minimap.queue_free()
	minimap = minimap_scene.instantiate()
	add_child(minimap)
	minimap.init(storey_list[StoreyPlay])

	if minimap2draw != null:
		minimap2draw.queue_free()
	minimap2draw = minimap2draw_scene.instantiate()
	add_child(minimap2draw)
	minimap2draw.init(storey_list[StoreyPlay])

	$Label.position.x = minimap.get_width()
	storey_score += 1

	for i in PlayerCount:
		if i == 0:
			player_list[i].enter_storey(storey_list[StoreyPlay],false)
			player_list[i].light_on(true)
		else:
			player_list[i].enter_storey(storey_list[StoreyPlay], true)
		animate_forward_by_dur(player_list[i], 0)
		animate_turn_by_dur(player_list[i], 0)
	set_minimap_mode()

func _process(_delta: float) -> void:
	for i in PlayerCount:
		var pl = player_list[i]
		var ani_dur = pl.get_ani_dur()
		if pl.act_end(ani_dur): # true on act end
			if i == 0:
				if storey_list[StoreyPlay].is_goal_pos(pl.pos_old):
					start_new_maze()
					return
				if storey_list[StoreyPlay].is_capsule_pos(pl.pos_old) : # capsule encounter
					pl.act_queue.push_back(Character.Act.RotateCamera)
					storey_list[StoreyPlay].remove_capsule_at(pl.pos_old)
				minimap.move_player(pl.pos_old.x, pl.pos_old.y)
				minimap2draw.move_player(pl.pos_old.x, pl.pos_old.y)
		pl.ai_act()
		if pl.start_new_act(): # new act start
			ani_dur = 0
			if i == 0:
				var walldir = storey_list[StoreyPlay].maze_cells.get_wall_dir_at(pl.pos_old.x,pl.pos_old.y)
				for d in walldir:
					minimap2draw.add_wall_at(pl.pos_old.x,pl.pos_old.y,Storey.MazeDir2Dir[d])
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
			player_list[0].act_queue.push_back(Character.Act.Forward)
		elif event.keycode == KEY_DOWN:
			player_list[0].act_queue.push_back(Character.Act.TurnLeft)
			player_list[0].act_queue.push_back(Character.Act.TurnLeft)
		elif event.keycode == KEY_LEFT:
			player_list[0].act_queue.push_back(Character.Act.TurnLeft)
		elif event.keycode == KEY_RIGHT:
			player_list[0].act_queue.push_back(Character.Act.TurnRight)
		elif event.keycode == KEY_SPACE:
			player_list[0].act_queue.push_back(Character.Act.RotateCamera)

		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass

func update_info(pl :Character)->void:
	$Label.text = "fullminimap:%s multistoreyview:%s storey %d\n%s" % [
		full_minimap, view_floor_ceiling,
		storey_score,
		pl.info_str()]

func animate_act(pl :Character, dur :float)->void:
	match pl.act_current:
		Character.Act.Forward:
			animate_forward_by_dur(pl, dur)
		Character.Act.TurnLeft, Character.Act.TurnRight:
			animate_turn_by_dur(pl, dur)
		Character.Act.RotateCamera:
			animate_rotate_camera_by_dur(pl,dur)

# dur : 0 - 1 :second
func animate_forward_by_dur(pl :Character, dur :float)->void:
	pl.position = pl.calc_animate_forward_by_dur(dur)

# dur : 0 - 1 :second
func animate_turn_by_dur(pl :Character, dur :float)->void:
	pl.rotation.y = pl.calc_animate_turn_by_dur(dur)

func animate_rotate_camera_by_dur(pl :Character, dur :float)->void:
	pl.rotate_camera(pl.calc_animate_camera_rotate(dur))
