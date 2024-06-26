extends Node3D

class_name MazeCrawl

enum RollDir {Up,Right,Down,Left}
static func rolldir2str(vd :RollDir)->String:
	return RollDir.keys()[vd]
static func rolldir_left(d:RollDir)->RollDir:
	return (d+1)%4 as RollDir
static func rolldir_right(d:RollDir)->RollDir:
	return (d-1+4)%4 as RollDir
static func rolldir_opposite(d:RollDir)->RollDir:
	return (d+2)%4 as RollDir
static func rolldir2rad(d:RollDir)->float:
	return deg_to_rad(d*90.0)

enum Action {None, EnterStorey, Forward, TurnRight , TurnLeft, RollRight, RollLeft}
static func action2str(a :Action)->String:
	return Action.keys()[a]

static func new_action_stats_dict()->Dictionary:
	var rtn = {}
	for k in Action.values():
		rtn[k]=0
	return rtn
static func act_stats_str(d:Dictionary)->String:
	var rtn = ""
	for i in Action.values():
		rtn += " %s:%d" % [action2str(i), d[i]]
	return rtn

func enqueue_action(a :Action, args :=[])->void:
	action_queue.push_back([a,action_per_second.get_value(), args])
	crop_action_queue()
func enqueue_action_with_speed(a :Action,s :float, args :=[])->void:
	action_queue.push_back([a,s, args])
	crop_action_queue()
func crop_action_queue()->void:
	if action_queue.size() > QueueLimit:
		action_queue = action_queue.slice(action_queue.size()-QueueLimit)
func queue_to_str()->String:
	var rtn = ""
	for a in action_queue:
		rtn += "%s(%.1f)%s " % [ MazeCrawl.action2str(a[0]), a[1], a[2] ]
	return rtn

var roll_dir :RollDir
var roll_dir_dst :RollDir
var total_action_stats :Dictionary
var storey_action_stats :Dictionary
const QueueLimit = 10
var action_queue :Array
var storey :Storey
var action_per_second := ClampedFloat.new(2,0.5,4.5) # sec
var dir_src : Storey.Dir
var dir_dst : Storey.Dir
var pos_src :Vector2i
var pos_dst :Vector2i
var action_start_time :float # unixtime sec
var action_current : Array # [Action, action_per_second.value]
var auto_move :bool

func init(auto :bool)->void:
	auto_move = auto
	total_action_stats = MazeCrawl.new_action_stats_dict()
	dir_src = Storey.Dir.North
	action_current = [Action.None, 0,[]]
	action_per_second.set_randfn()

# return true on new act
func start_new_action()->bool:
	if action_current[0] != Action.None || action_queue.size() == 0:
		return false
	action_start_time = Time.get_unix_time_from_system()
	action_current = action_queue.pop_front()
	match action_current[0]:
		Action.Forward:
			if can_move(dir_src):
				pos_dst = pos_src + Storey.Dir2Vt[dir_src]
			else :
				action_current = [Action.None, 0,[]]
		Action.TurnLeft:
			dir_dst = Storey.dir_left(dir_src)
		Action.TurnRight:
			dir_dst = Storey.dir_right(dir_src)
		Action.RollRight:
			roll_dir_dst = MazeCrawl.rolldir_right(roll_dir)
		Action.RollLeft:
			roll_dir_dst = MazeCrawl.rolldir_left(roll_dir)
		Action.EnterStorey:
			var args = action_current[2]
			storey = args[0]
			pos_dst = args[1]
			storey_action_stats = MazeCrawl.new_action_stats_dict()
			action_per_second.set_randfn()
			animate_move_by_dur(0)
			animate_turn_by_dur(0)
	total_action_stats[action_current[0]] += 1
	storey_action_stats[action_current[0]] += 1
	return true

# return true on act end
func is_action_ended(ani_dur :float)->bool:
	return action_current[0] != Action.None && ani_dur > 1.0

func end_action()->void:
	dir_src = dir_dst
	pos_src = pos_dst
	action_current = [Action.None, 0,[]]
	roll_dir = roll_dir_dst
	snap_90()

func ai_action()->void:
	if auto_move && action_current[0] == Action.None && action_queue.size() == 0: # add new ai action
		make_ai_action()

func make_ai_action()->bool:
	# try right
	if can_move(Storey.dir_right(dir_src)):
		enqueue_action(Action.TurnRight)
		enqueue_action(Action.Forward)
		return true
	# try forward
	if can_move(dir_src):
		enqueue_action(Action.Forward)
		return true
	# try left
	if can_move(Storey.dir_left(dir_src)):
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.Forward)
		return true
	# try backward
	if can_move(Storey.dir_opposite(dir_src)):
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.Forward)
		return true
	return false

func can_move(dir :Storey.Dir)->bool:
	return storey.can_move(pos_src.x, pos_src.y, dir )

# return 0 - 1
func get_animation_progress()->float:
	return (Time.get_unix_time_from_system() - action_start_time)*action_current[1]

func animate_move_by_dur( dur :float)->void:
	var y = storey.storey_num*storey.storey_h+ storey.storey_h/2.0
	var p1 = storey.mazepos2storeypos(pos_src,y)
	var p2 = storey.mazepos2storeypos(pos_dst,y)
	position = p1.lerp(p2,dur)

func animate_move_storey_by_dur(dur :float, from :int, to :int)->void:
	var p1 = storey.mazepos2storeypos(pos_src,from*storey.storey_h+ storey.storey_h/2.0)
	var p2 = storey.mazepos2storeypos(pos_dst,to*storey.storey_h+ storey.storey_h/2.0)
	position = p1.lerp(p2,dur)

func animate_turn_by_dur(dur :float)->void:
	rotation.y = lerp_angle(Storey.dir2rad(dir_src), Storey.dir2rad(dir_dst), dur)

func animate_roll_by_dur(dur :float)->void:
	rotation.z = lerp_angle(MazeCrawl.rolldir2rad(roll_dir), MazeCrawl.rolldir2rad(roll_dir_dst), dur)

func snap_90()->void:
	for i in 3:
		rotation[i] = snapped(rotation[i], PI/2)

func info_str()->String:
	return "automove:%s, act %s /sec\nview roll:%s°, roll:%s" % [
		auto_move, action_per_second, roll_dir*90, rotation_degrees,
		]

func debug_str()->String:
	return "total:%s\nin storey:%s\n%s [%s]\n%s->%s (%d, %d)->(%d, %d)\nOpen: %s" % [
		MazeCrawl.act_stats_str(total_action_stats),
		MazeCrawl.act_stats_str(storey_action_stats),
		MazeCrawl.action2str(action_current[0]), queue_to_str(),
		Storey.dir2str(dir_src), Storey.dir2str(dir_dst),
		pos_src.x, pos_src.y, pos_dst.x, pos_dst.y,
		storey.maze_cells.open_dir_str(pos_src.x, pos_src.y),
		]
