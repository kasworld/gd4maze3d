extends Node3D

const ACT_DUR = 1.0 # sec
enum Act {Forward, Turn_Right , Turn_Left}

var action_queue :Array[Act]
func queue_to_str()->String:
	var rtn = ""
	for a in action_queue:
		rtn += "%s " % [ Act.keys()[a] ]
	return rtn

var act_start_time :float # unixtime sec
var actor_dir_old : Maze.Dir
var actor_dir_new : Maze.Dir
var actor_pos_old :Vector2i
var actor_pos_new :Vector2i

var maze_size = Vector2i(16,16)

func _ready() -> void:
	$MazeStorey.init(maze_size)
	actor_pos_old = Vector2i(0,0) #maze_size/2
	actor_pos_new = Vector2i(0,0) #maze_size/2
	actor_dir_old = Maze.Dir.North
	actor_dir_new = Maze.Dir.North
	forward_by_dur(0)
	act_start_time = Time.get_unix_time_from_system()

func _process(delta: float) -> void:
	var t = Time.get_unix_time_from_system()
	var dur = t - act_start_time

	if dur > ACT_DUR :
		actor_dir_old = actor_dir_new
		actor_pos_old = actor_pos_new
		act_start_time = t
		action_queue.pop_front() # del done act
		if action_queue.size() == 0:
			return
			make_queue_action()
		match action_queue[0]:
			Act.Forward:
				actor_pos_new = actor_pos_old + Maze.Dir2Vt[actor_dir_old]
			Act.Turn_Left:
				actor_dir_new = Maze.TurnLeft[actor_dir_old]
			Act.Turn_Right:
				actor_dir_new = Maze.TurnRight[actor_dir_old]
	else:
		do_action(dur/ACT_DUR)

	$Label.text = "[%s]\n(%d, %d)->(%d, %d)\n[%s] %s->%s" % [
		queue_to_str(),
		actor_pos_old.x, actor_pos_old.y, actor_pos_new.x, actor_pos_new.y,
		$MazeStorey.open_dir_str(actor_pos_old.x, actor_pos_old.y),
		Maze.Dir2Str[actor_dir_old], Maze.Dir2Str[actor_dir_new]
		]


func make_queue_action()->bool:
	return try_queue_move_right() || try_queue_move_foward() || try_queue_move_left() || try_queue_move_backward()

func try_queue_move_foward()->bool:
	if can_move(actor_dir_old):
		action_queue.push_back(Act.Forward)
		return true
	return false

func try_queue_move_right()->bool:
	if can_move(Maze.TurnRight[actor_dir_old]):
		action_queue.push_back(Act.Turn_Right)
		action_queue.push_back(Act.Forward)
		return true
	return false

func try_queue_move_left()->bool:
	if can_move(Maze.TurnLeft[actor_dir_old]):
		action_queue.push_back(Act.Turn_Left)
		action_queue.push_back(Act.Forward)
		return true
	return false

func try_queue_move_backward()->bool:
	if can_move(Maze.Opppsite[actor_dir_old]):
		action_queue.push_back(Act.Turn_Left)
		action_queue.push_back(Act.Turn_Left)
		action_queue.push_back(Act.Forward)
		return true
	return false

func can_move(dir :Maze.Dir)->bool:
	return $MazeStorey.can_move(actor_pos_old.x,actor_pos_old.y, dir)

func do_action(dur :float)->void:
	if action_queue.size()==0:
		return
	match action_queue[0]:
		Act.Forward:
			forward_by_dur(dur)
		Act.Turn_Left:
			turn_by_dur(dur)
		Act.Turn_Right:
			turn_by_dur(dur)

# dur : 0 - 1 :second
func forward_by_dur(dur :float)->void:
	var vt = Vector3(
		0.5+ lerpf(actor_pos_old.x , actor_pos_new.x , dur ) ,
		1,
		0.5+ lerpf(actor_pos_old.y , actor_pos_new.y , dur ) ,
	)
	$Player.position = vt

# dur : 0 - 1 :second
func turn_by_dur(dur :float)->void:
	var a = lerp_angle( deg_to_rad(actor_dir_old*90.0),deg_to_rad(actor_dir_new*90.0) , dur  )
	$Player.rotation.y = a

func set_top_view()->void:
	$Player/PlayerCamera3D.current = false
	$MazeStorey.set_top_view(true)

func set_player_view()->void:
	$Player/PlayerCamera3D.current = true
	$MazeStorey.set_top_view(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_1:
			set_top_view()
		elif event.keycode == KEY_2:
			set_player_view()
		elif event.keycode == KEY_UP:
			try_queue_move_foward()
		elif event.keycode == KEY_LEFT:
			action_queue.push_back(Act.Turn_Left)
		elif event.keycode == KEY_RIGHT:
			action_queue.push_back(Act.Turn_Right)
		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass

