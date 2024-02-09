extends Node3D

class_name Player

var storey :Storey

const ANI_ACT_DUR = 1.0/5 # sec
enum Act {None, Forward, Turn_Right , Turn_Left}
func act2str(a :Act)->String:
	return Act.keys()[a]

var act_queue :Array[Act]
func queue_to_str()->String:
	var rtn = ""
	for a in act_queue:
		rtn += "%s " % [ act2str(a) ]
	return rtn

var dir_old : Storey.Dir
var dir_new : Storey.Dir
var pos_old :Vector2i
var pos_new :Vector2i

var act_start_time :float # unixtime sec
var act_current : Act

var auto_move :bool

func enter_storey(st :Storey)->void:
	storey = st
	pos_old = storey.start_pos
	pos_new = pos_old
	dir_old = Storey.Dir.North
	dir_new = dir_old

# return true on goal
func act_end(dur :float)->bool:
	# action ended
	if act_current != Act.None && dur > ANI_ACT_DUR :
		dir_old = dir_new
		pos_old = pos_new
		act_current = Act.None
		if pos_old == storey.goal_pos:
			return true
	return false

func ai_act()->void:
	if auto_move && act_current == Act.None && act_queue.size() == 0: # add new ai action
		make_ai_action()

# return true on new act
func start_new_act()->bool:
	if act_current == Act.None && act_queue.size() > 0: # start new action
		act_start_time = Time.get_unix_time_from_system()
		act_current = act_queue.pop_front()
		match act_current:
			Act.Forward:
				if can_move(dir_old):
					pos_new = pos_old + Storey.Dir2Vt[dir_old]
				else :
					act_current = Act.None
			Act.Turn_Left:
				dir_new = Storey.dir_left(dir_old)
			Act.Turn_Right:
				dir_new = Storey.dir_right(dir_old)
		return true
	return false

func info_str()->String:
	return "automove:%s\n%s [%s]\n%s->%s (%d, %d)->(%d, %d)\n[%s]" % [
		auto_move,
		act2str(act_current), queue_to_str(),
		Storey.dir2str(dir_old), Storey.dir2str(dir_new),
		pos_old.x, pos_old.y, pos_new.x, pos_new.y,
		storey.open_dir_str(pos_old.x, pos_old.y),
		]

func camera_current(b :bool)->void:
	$Camera3D.current = b

func make_ai_action()->bool:
	# try right
	if can_move(Storey.dir_right(dir_old)):
		act_queue.push_back(Act.Turn_Right)
		act_queue.push_back(Act.Forward)
		return true
	# try forward
	if can_move(dir_old):
		act_queue.push_back(Act.Forward)
		return true
	# try left
	if can_move(Storey.dir_left(dir_old)):
		act_queue.push_back(Act.Turn_Left)
		act_queue.push_back(Act.Forward)
		return true
	# try backward
	if can_move(Storey.dir_opposite(dir_old)):
		act_queue.push_back(Act.Turn_Left)
		act_queue.push_back(Act.Turn_Left)
		act_queue.push_back(Act.Forward)
		return true
	return false

func can_move(dir :Storey.Dir)->bool:
	return storey.can_move(pos_old.x, pos_old.y, dir )

func calc_animate_forward_by_dur(dur :float)->Vector3:
	return Vector3(
		0.5+ lerpf(pos_old.x, pos_new.x, dur),
		1,
		0.5+ lerpf(pos_old.y, pos_new.y, dur),
	)

func calc_animate_turn_by_dur(dur :float)->float:
	return lerp_angle(Storey.dir2rad(dir_old), Storey.dir2rad(dir_new), dur)
