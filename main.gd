extends Node3D

var storey_scene = preload("res://storey.tscn")
var storey :Storey
var maze_size = Vector2i(32,18)

enum ViewMode {Player, Top}
var view_mode :ViewMode
func set_view_mode()->void:
	match view_mode:
		ViewMode.Player:
			$Player.camera_current(true)
			storey.set_top_view(false)
		ViewMode.Top:
			$Player.camera_current(false)
			storey.set_top_view(true)


func _ready() -> void:
	view_mode = ViewMode.Player
	$Player.auto_move = true
	start_new_maze()

func start_new_maze()->void:
	if storey != null:
		remove_child(storey)
	storey = storey_scene.instantiate()
	add_child(storey)
	storey.init(maze_size)
	$Player.enter_storey(storey)
	forward_by_dur(0)
	turn_by_dur(0)
	set_view_mode()

func _process(_delta: float) -> void:
	var t = Time.get_unix_time_from_system()
	var dur = t - $Player.act_start_time

	# action ended
	if $Player.act_current != Player.Act.None && dur > Player.ACT_DUR :
		$Player.dir_old = $Player.dir_new
		$Player.pos_old = $Player.pos_new
		$Player.act_current = Player.Act.None
		if $Player.pos_old == storey.goal_pos:
			start_new_maze()

	if $Player.auto_move && $Player.act_current == Player.Act.None && $Player.act_queue.size() == 0: # add new ai action
		$Player.make_ai_action()

	if $Player.act_current == Player.Act.None && $Player.act_queue.size() > 0: # start new action
		$Player.act_start_time = t
		dur = 0
		$Player.act_current = $Player.act_queue.pop_front()
		match $Player.act_current:
			Player.Act.Forward:
				if $Player.can_move($Player.dir_old):
					$Player.pos_new = $Player.pos_old + Storey.Dir2Vt[$Player.dir_old]
				else :
					$Player.act_current = Player.Act.None
			Player.Act.Turn_Left:
				$Player.dir_new = Storey.dir_left($Player.dir_old)
			Player.Act.Turn_Right:
				$Player.dir_new = Storey.dir_right($Player.dir_old)

	if $Player.act_current != Player.Act.None :
		do_act_dur($Player.act_current, dur/Player.ACT_DUR)

	update_info()

func update_info()->void:
	$Label.text = "view:%s %s" % [
		ViewMode.keys()[view_mode],
		$Player.info_str(),
		]


func do_act_dur(act :Player.Act, dur :float)->void:
	match act:
		Player.Act.Forward:
			forward_by_dur(dur)
		Player.Act.Turn_Left, Player.Act.Turn_Right:
			turn_by_dur(dur)

# dur : 0 - 1 :second
func forward_by_dur(dur :float)->void:
	$Player.position = Vector3(
		0.5+ lerpf($Player.pos_old.x, $Player.pos_new.x, dur),
		1,
		0.5+ lerpf($Player.pos_old.y, $Player.pos_new.y, dur),
	)

# dur : 0 - 1 :second
func turn_by_dur(dur :float)->void:
	$Player.rotation.y = lerp_angle(Storey.dir2rad($Player.dir_old), Storey.dir2rad($Player.dir_new), dur)

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
			$Player.auto_move = !$Player.auto_move

		elif event.keycode == KEY_UP:
			$Player.act_queue.push_back(Player.Act.Forward)
		elif event.keycode == KEY_DOWN:
			$Player.act_queue.push_back(Player.Act.Turn_Left)
			$Player.act_queue.push_back(Player.Act.Turn_Left)
		elif event.keycode == KEY_LEFT:
			$Player.act_queue.push_back(Player.Act.Turn_Left)
		elif event.keycode == KEY_RIGHT:
			$Player.act_queue.push_back(Player.Act.Turn_Right)
		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass
