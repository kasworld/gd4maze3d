extends Node3D

const ACT_DUR = 1.0 # sec
enum Act {None, Forward, Turn_Right , Turn_Left}
func act2str(a :Act)->String:
	return Act.keys()[a]

# x90 == degree
enum Dir {
	North = 0,
	West = 1,
	South = 2,
	East = 3,
}
func to_maze_dir(d :Dir)->Maze.Dir:
	return Maze.DirList[d%4]
func dir2str(d :Dir)->String:
	return Dir.keys()[d]
func dir_left(d:Dir)->Dir:
	return (d+1)%4
func dir_right(d:Dir)->Dir:
	return (d-1+4)%4
func dir_opposite(d:Dir)->Dir:
	return (d+2)%4

var action_queue :Array[Act]
func queue_to_str()->String:
	var rtn = ""
	for a in action_queue:
		rtn += "%s " % [ act2str(a) ]
	return rtn

var act_start_time :float # unixtime sec
var act_current : Act
var actor_dir_old : Dir
var actor_dir_new : Dir
var actor_pos_old :Vector2i
var actor_pos_new :Vector2i

var maze_size = Vector2i(16,16)

func _ready() -> void:
	$MazeStorey.init(maze_size)
	actor_pos_old = maze_size/2
	actor_pos_new = actor_pos_old
	actor_dir_old = Dir.North
	actor_dir_new = actor_dir_old
	forward_by_dur(0)
	turn_by_dur(0)

func _process(delta: float) -> void:
	var t = Time.get_unix_time_from_system()
	var dur = t - act_start_time

	# action ended
	if act_current != Act.None && dur > ACT_DUR :
		actor_dir_old = actor_dir_new
		actor_pos_old = actor_pos_new
		act_current = Act.None

	if act_current == Act.None && action_queue.size() > 0: # start new action
		act_start_time = t
		dur = 0
		act_current = action_queue.pop_front()
		match act_current:
			Act.Forward:
				if can_move(actor_dir_old):
					actor_pos_new = actor_pos_old + Maze.Dir2Vt[to_maze_dir(actor_dir_old)]
				else :
					act_current = Act.None
			Act.Turn_Left:
				actor_dir_new = dir_left(actor_dir_old)
			Act.Turn_Right:
				actor_dir_new = dir_right(actor_dir_old)

	if act_current != Act.None :
		do_act_dur(act_current, dur/ACT_DUR)

	update_info()


func update_info()->void:
	$Label.text = "%s [%s]\n(%d, %d)->(%d, %d)\n[%s] %s->%s" % [
		act2str(act_current), queue_to_str(),
		actor_pos_old.x, actor_pos_old.y, actor_pos_new.x, actor_pos_new.y,
		$MazeStorey.open_dir_str(actor_pos_old.x, actor_pos_old.y),
		dir2str(actor_dir_old), dir2str(actor_dir_new)
		]


func make_queue_action()->bool:
	return try_queue_move_right() || try_queue_move_foward() || try_queue_move_left() || try_queue_move_backward()

func try_queue_move_foward()->bool:
	if can_move(actor_dir_old):
		action_queue.push_back(Act.Forward)
		return true
	return false

func try_queue_move_right()->bool:
	if can_move(dir_right(actor_dir_old)):
		action_queue.push_back(Act.Turn_Right)
		action_queue.push_back(Act.Forward)
		return true
	return false

func try_queue_move_left()->bool:
	if can_move(dir_left(actor_dir_old)):
		action_queue.push_back(Act.Turn_Left)
		action_queue.push_back(Act.Forward)
		return true
	return false

func try_queue_move_backward()->bool:
	if can_move(dir_opposite(actor_dir_old)):
		action_queue.push_back(Act.Turn_Left)
		action_queue.push_back(Act.Turn_Left)
		action_queue.push_back(Act.Forward)
		return true
	return false

func can_move(dir :Dir)->bool:
	return $MazeStorey.can_move(actor_pos_old.x, actor_pos_old.y, to_maze_dir(dir) )

func do_act_dur(act :Act, dur :float)->void:
	match act:
		Act.Forward:
			forward_by_dur(dur)
		Act.Turn_Left, Act.Turn_Right:
			turn_by_dur(dur)

# dur : 0 - 1 :second
func forward_by_dur(dur :float)->void:
	$Player.position = Vector3(
		0.5+ lerpf(actor_pos_old.x, actor_pos_new.x, dur),
		1,
		0.5+ lerpf(actor_pos_old.y, actor_pos_new.y, dur),
	)

# dur : 0 - 1 :second
func turn_by_dur(dur :float)->void:
	$Player.rotation.y = lerp_angle(deg_to_rad(actor_dir_old*90.0), deg_to_rad(actor_dir_new*90.0), dur)

func set_top_view()->void:
	$Player.camera_current(false)
	$MazeStorey.set_top_view(true)

func set_player_view()->void:
	$Player.camera_current(true)
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
			action_queue.push_back(Act.Forward)
		elif event.keycode == KEY_DOWN:
			action_queue.push_back(Act.Turn_Left)
			action_queue.push_back(Act.Turn_Left)
		elif event.keycode == KEY_LEFT:
			action_queue.push_back(Act.Turn_Left)
		elif event.keycode == KEY_RIGHT:
			action_queue.push_back(Act.Turn_Right)
		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass

