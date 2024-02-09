extends Node3D

var storey_scene = preload("res://storey.tscn")
var storey :Storey
var maze_size = Vector2i(32,18)

var player_scene = preload("res://player.tscn")
var player :Player

enum ViewMode {Player, Top}
var view_mode :ViewMode
func set_view_mode()->void:
	match view_mode:
		ViewMode.Player:
			player.camera_current(true)
			storey.set_top_view(false)
		ViewMode.Top:
			player.camera_current(false)
			storey.set_top_view(true)

func _ready() -> void:
	player = player_scene.instantiate()
	add_child(player)
	view_mode = ViewMode.Player
	player.auto_move = true
	start_new_maze()

func start_new_maze()->void:
	if storey != null:
		remove_child(storey)
	storey = storey_scene.instantiate()
	add_child(storey)
	storey.init(maze_size)
	player.enter_storey(storey)
	animate_forward_by_dur(player, 0)
	animate_turn_by_dur(player, 0)
	set_view_mode()

func _process(_delta: float) -> void:
	var ani_dur = Time.get_unix_time_from_system() - player.act_start_time
	if player.act_end(ani_dur): # goal reached
		start_new_maze()
	player.ai_act()
	if player.start_new_act(): # new act start
		ani_dur = 0
	if player.act_current != Player.Act.None :
		animate_act(player, ani_dur/Player.ANI_ACT_DUR)
	update_info()

func update_info()->void:
	$Label.text = "view:%s %s" % [ViewMode.keys()[view_mode], player.info_str()]

func animate_act(pl :Player, dur :float)->void:
	match pl.act_current:
		Player.Act.Forward:
			animate_forward_by_dur(pl, dur)
		Player.Act.Turn_Left, Player.Act.Turn_Right:
			animate_turn_by_dur(pl, dur)

# dur : 0 - 1 :second
func animate_forward_by_dur(pl :Player, dur :float)->void:
	pl.position = pl.calc_animate_forward_by_dur(dur)

# dur : 0 - 1 :second
func animate_turn_by_dur(pl :Player, dur :float)->void:
	pl.rotation.y = pl.calc_animate_turn_by_dur(dur)

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
			player.auto_move = !player.auto_move

		elif event.keycode == KEY_UP:
			player.act_queue.push_back(Player.Act.Forward)
		elif event.keycode == KEY_DOWN:
			player.act_queue.push_back(Player.Act.Turn_Left)
			player.act_queue.push_back(Player.Act.Turn_Left)
		elif event.keycode == KEY_LEFT:
			player.act_queue.push_back(Player.Act.Turn_Left)
		elif event.keycode == KEY_RIGHT:
			player.act_queue.push_back(Player.Act.Turn_Right)
		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass
