extends Node3D

var storey_scene = preload("res://storey.tscn")
var storey :Storey
var maze_size = Vector2i(32,18)

var character_scene = preload("res://character.tscn")
const PlayerCount = 100
var player_list :Array[Character]

enum ViewMode {Player, Top}
var view_mode :ViewMode
func set_view_mode()->void:
	match view_mode:
		ViewMode.Player:
			player_list[0].camera_current(true)
			storey.set_top_view(false)
		ViewMode.Top:
			player_list[0].camera_current(false)
			storey.set_top_view(true)

func _ready() -> void:
	for i in PlayerCount:
		player_list.append(character_scene.instantiate())
		add_child(player_list[i])
		player_list[i].auto_move = true
	view_mode = ViewMode.Player
	start_new_maze()

func start_new_maze()->void:
	if storey != null:
		storey.queue_free()
	storey = storey_scene.instantiate()
	add_child(storey)
	storey.init(maze_size)
	for i in PlayerCount:
		if i == 0:
			player_list[i].enter_storey(storey,false)
		else:
			player_list[i].enter_storey(storey, true)
		animate_forward_by_dur(player_list[i], 0)
		animate_turn_by_dur(player_list[i], 0)
	set_view_mode()

func _process(_delta: float) -> void:
	for i in PlayerCount:
		var ani_dur = player_list[i].get_ani_dur()
		if player_list[i].act_end(ani_dur): # goal reached
			if i == 0:
				start_new_maze()
		player_list[i].ai_act()
		if player_list[i].start_new_act(): # new act start
			ani_dur = 0
		if player_list[i].act_current != Character.Act.None :
			animate_act(player_list[i], ani_dur)
	update_info(player_list[0])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_1:
			view_mode = ViewMode.Top
			set_view_mode()
		elif event.keycode == KEY_2:
			view_mode = ViewMode.Player
			set_view_mode()

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

		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass

func update_info(pl :Character)->void:
	$Label.text = "view:%s %s" % [ViewMode.keys()[view_mode], pl.info_str()]

func animate_act(pl :Character, dur :float)->void:
	match pl.act_current:
		Character.Act.Forward:
			animate_forward_by_dur(pl, dur)
		Character.Act.TurnLeft, Character.Act.TurnRight:
			animate_turn_by_dur(pl, dur)

# dur : 0 - 1 :second
func animate_forward_by_dur(pl :Character, dur :float)->void:
	pl.position = pl.calc_animate_forward_by_dur(dur)

# dur : 0 - 1 :second
func animate_turn_by_dur(pl :Character, dur :float)->void:
	pl.rotation.y = pl.calc_animate_turn_by_dur(dur)
