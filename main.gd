extends Node3D

var storey_scene = preload("res://storey.tscn")
var storey :Storey
var maze_size = Vector2i(32,18)

const ACT_DUR = 1.0/5 # sec
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
const Dir2Vt = {
	Dir.North : Vector2i(0,-1),
	Dir.West : Vector2i(-1,0),
	Dir.South : Vector2i(0, 1),
	Dir.East : Vector2i(1,0),
}
func to_maze_dir(d :Dir)->Maze.Dir:
	return Maze.DirList[d%4]
func dir2str(d :Dir)->String:
	return Dir.keys()[d]
func dir_left(d:Dir)->Dir:
	return (d+1)%4 as Dir
func dir_right(d:Dir)->Dir:
	return (d-1+4)%4 as Dir
func dir_opposite(d:Dir)->Dir:
	return (d+2)%4 as Dir
func dir2rad(d:Dir)->float:
	return deg_to_rad(d*90.0)


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

var auto_move :bool

func _ready() -> void:
	view_mode = ViewMode.Player
	auto_move = true
	start_new_maze()

func start_new_maze()->void:
	if storey != null:
		remove_child(storey)
	storey = storey_scene.instantiate()
	add_child(storey)
	storey.init(maze_size)
	actor_pos_old = storey.start_pos
	actor_pos_new = actor_pos_old
	actor_dir_old = Dir.North
	actor_dir_new = actor_dir_old
	forward_by_dur(0)
	turn_by_dur(0)
	set_view_mode()

func _process(_delta: float) -> void:
	var t = Time.get_unix_time_from_system()
	var dur = t - act_start_time

	# action ended
	if act_current != Act.None && dur > ACT_DUR :
		actor_dir_old = actor_dir_new
		actor_pos_old = actor_pos_new
		act_current = Act.None
		if actor_pos_old == storey.goal_pos:
			start_new_maze()

	if auto_move && act_current == Act.None && action_queue.size() == 0: # add new ai action
		make_ai_action()

	if act_current == Act.None && action_queue.size() > 0: # start new action
		act_start_time = t
		dur = 0
		act_current = action_queue.pop_front()
		match act_current:
			Act.Forward:
				if can_move(actor_dir_old):
					actor_pos_new = actor_pos_old + Dir2Vt[actor_dir_old]
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
	$Label.text = "view:%s automove:%s\n%s [%s]\n%s->%s (%d, %d)->(%d, %d)\n[%s]" % [
		ViewMode.keys()[view_mode], auto_move,
		act2str(act_current), queue_to_str(),
		dir2str(actor_dir_old), dir2str(actor_dir_new),
		actor_pos_old.x, actor_pos_old.y, actor_pos_new.x, actor_pos_new.y,
		storey.open_dir_str(actor_pos_old.x, actor_pos_old.y),
		]

func make_ai_action()->bool:
	# try right
	if can_move(dir_right(actor_dir_old)):
		action_queue.push_back(Act.Turn_Right)
		action_queue.push_back(Act.Forward)
		return true
	# try forward
	if can_move(actor_dir_old):
		action_queue.push_back(Act.Forward)
		return true
	# try left
	if can_move(dir_left(actor_dir_old)):
		action_queue.push_back(Act.Turn_Left)
		action_queue.push_back(Act.Forward)
		return true
	# try backward
	if can_move(dir_opposite(actor_dir_old)):
		action_queue.push_back(Act.Turn_Left)
		action_queue.push_back(Act.Turn_Left)
		action_queue.push_back(Act.Forward)
		return true
	return false

func can_move(dir :Dir)->bool:
	return storey.can_move(actor_pos_old.x, actor_pos_old.y, to_maze_dir(dir) )

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
	$Player.rotation.y = lerp_angle(dir2rad(actor_dir_old), dir2rad(actor_dir_new), dur)

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
			auto_move = !auto_move

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
