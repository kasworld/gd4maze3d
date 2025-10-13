extends Node3D
class_name Crawler

enum Action {None, EnterStorey, Forward, TurnRight , TurnLeft, RollRight, RollLeft}
static func action2str(a :Action) -> String:
	return Action.keys()[a]

# action stats == Dictionary
static func new_stats() -> Dictionary:
	var rtn = {}
	for k in Action.values():
		rtn[k]=0
	return rtn
static func stats2str(d:Dictionary) -> String:
	var rtn = ""
	for i in Action.values():
		rtn += " %s:%d" % [action2str(i), d[i]]
	return rtn

enum Walk {Off, RightFirst, LeftFirst}
static func walk2str(a :Walk) -> String:
	return Walk.keys()[a]

static func walk_next(a :Walk) -> Walk:
	return (a +1) % Walk.keys().size() as Walk

const QueueLimit = 10
var queue :Array
var action_per_second := ClampedFloat.new(1,0.5,3.0) # sec

func queue_init() -> Crawler:
	rand_act_speed()
	return self

func rand_act_speed() -> void:
	action_per_second.set_randfn()
	
func queue_clear() -> void:
	queue.resize(0)
	
func is_queue_empty() -> bool:
	return queue.size() == 0
	
func action_pop_front():
	return queue.pop_front()

func enqueue_action(a :Action, args :=[]) -> Crawler:
	queue.push_back(
		{
			"Action":a,
			"APS": action_per_second.get_value(), 
			"Args":args,
		})
	crop_queue()
	return self
	
func enqueue_action_with_speed(a :Action,s :float, args :=[]) -> Crawler:
	queue.push_back(
		{
			"Action":a,
			"APS":s, 
			"Args":args,
		})
	crop_queue()
	return self
	
func crop_queue() -> Crawler:
	if queue.size() > QueueLimit:
		queue = queue.slice(queue.size()-QueueLimit)
	return self

func queue2str() -> String:
	var rtn = "ActionQueue["
	for a in queue:
		rtn += "%s(%.1f)%s " % [ action2str(a.Action), a.APS, a.Args ]
	rtn += "]"
	return rtn

#var action_queue :ActionQueue
var action_start_time :float # unixtime sec
var action_current : Dictionary # [Action, APS, Args]

var serial :int
var color :Color

var roll_dir :EnumRoll.Dir
var roll_dir_dst :EnumRoll.Dir
var total_action_stats :Dictionary
var storey_action_stats :Dictionary
var storey :Storey
var dir_src : EnumDir.Dir
var dir_dst : EnumDir.Dir
var pos_src :Vector2i
var pos_dst :Vector2i

var auto_walk_type := Walk.RightFirst
func set_next_walk_type() -> Crawler:
	auto_walk_type = walk_next(auto_walk_type)
	return self
func set_auto_walk_type(t :Walk) -> void:
	auto_walk_type = t

func init(walk_type :Walk, n :int, LaneW:float,co :Color) -> Crawler:
	auto_walk_type = walk_type
	total_action_stats = new_stats()
	dir_src = EnumDir.Dir.North
	action_current = {
		"Action":Action.None, 
		"APS":0,
		"Args":[],
	}
	queue_init()
	serial = n
	color = co
	$MeshInstance3D.mesh.material.albedo_color = co
	$MeshInstance3D.mesh.height = 0.2*LaneW
	$MeshInstance3D.mesh.top_radius = 0.01*LaneW
	$MeshInstance3D.mesh.bottom_radius = 0.07*LaneW
	$MeshInstance3D.rotation.x = -PI/2
	$MeshInstance3D.scale.x = 0.5
	$MeshInstance3D.position.x = LaneW*0.2
	return self

# return true on new act
func start_new_action() -> bool:
	if action_current.Action  != Action.None || is_queue_empty():
		return false
	action_start_time = Time.get_unix_time_from_system()
	action_current = action_pop_front()
	match action_current.Action :
		Action.Forward:
			if can_move(dir_src):
				pos_dst = pos_src + EnumDir.Dir2Vt[dir_src]
			else :
				action_current = {
					"Action":Action.None, 
					"APS":0,
					"Args":[],
				}
		Action.TurnLeft:
			dir_dst = EnumDir.DirTurnLeft[dir_src]
		Action.TurnRight:
			dir_dst = EnumDir.DirTurnRight[dir_src]
		Action.RollRight:
			roll_dir_dst = EnumRoll.roll_right(roll_dir)
		Action.RollLeft:
			roll_dir_dst = EnumRoll.roll_left(roll_dir)
		Action.EnterStorey:
			var args = action_current.Args
			storey = args[0]
			pos_dst = args[1]
			storey_action_stats = new_stats()
			rand_act_speed()
			animate_move_by_dur(0, storey, storey)
			animate_turn_by_dur(0)
	total_action_stats[action_current.Action ] += 1
	storey_action_stats[action_current.Action ] += 1
	return true

# return true on act end
func is_action_ended(ani_dur :float) -> bool:
	return action_current.Action  != Action.None && ani_dur > 1.0

func end_action() -> void:
	dir_src = dir_dst
	pos_src = pos_dst
	action_current = {
		"Action":Action.None, 
		"APS":0,
		"Args":[],
	}
	roll_dir = roll_dir_dst
	snap_90()


func can_move(dir :EnumDir.Dir) -> bool:
	return storey.can_move(pos_src.x, pos_src.y, dir )

# return 0 - 1
func get_animation_progress() -> float:
	return (Time.get_unix_time_from_system() - action_start_time)*action_current.APS

func animate_move_by_dur(dur :float, from :Storey, to :Storey) -> void:
	var p1 = from.mazepos2storeypos(pos_src, from.storey_setting.StoryH/2) + from.position 
	var p2 = to.mazepos2storeypos(pos_dst, to.storey_setting.StoryH/2) + to.position 
	position = p1.lerp(p2,dur)

func animate_turn_by_dur(dur :float) -> void:
	rotation.y = lerp_angle(EnumDir.dir2rad(dir_src), EnumDir.dir2rad(dir_dst), dur)

func animate_roll_by_dur(dur :float) -> void:
	rotation.z = lerp_angle(EnumRoll.dir2rad(roll_dir), EnumRoll.dir2rad(roll_dir_dst), dur)

func snap_90() -> void:
	for i in 3:
		rotation[i] = snapped(rotation[i], PI/2)

func _to_string() -> String:
	return "Crawler[aiwalk:%s act %s /sec view roll:%s° roll:%s]" % [
		walk2str(auto_walk_type), action_per_second, roll_dir*90, rotation_degrees,
		]

func debug_str() -> String:
	return "total:%s\nin storey:%s\n%s [%s]\n%s->%s (%d, %d) -> (%d, %d)" % [
		stats2str(total_action_stats),
		stats2str(storey_action_stats),
		action2str(action_current.Action ), queue2str(),
		EnumDir.DirToStr[dir_src], EnumDir.DirToStr[dir_dst],
		pos_src.x, pos_src.y, pos_dst.x, pos_dst.y,
		]

func try_auto_walk() -> void:
	if action_current.Action == Action.None && is_queue_empty(): # add new ai action
		match auto_walk_type:
			Walk.RightFirst:
				walk_right_first()
			Walk.LeftFirst:
				walk_left_first()
			Walk.Off:
				pass

func walk_right_first() -> bool:
	# try right
	if can_move(EnumDir.DirTurnRight[dir_src]):
		enqueue_action(Action.TurnRight)
		enqueue_action(Action.Forward)
		return true
	# try forward
	if can_move(dir_src):
		enqueue_action(Action.Forward)
		return true
	# try left
	if can_move(EnumDir.DirTurnLeft[dir_src]):
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.Forward)
		return true
	# try backward
	if can_move(EnumDir.DirOpppsite[dir_src]):
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.Forward)
		return true
	return false

func walk_left_first() -> bool:
	# try left
	if can_move(EnumDir.DirTurnLeft[dir_src]):
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.Forward)
		return true
	# try forward
	if can_move(dir_src):
		enqueue_action(Action.Forward)
		return true
	# try right
	if can_move(EnumDir.DirTurnRight[dir_src]):
		enqueue_action(Action.TurnRight)
		enqueue_action(Action.Forward)
		return true
	# try backward
	if can_move(EnumDir.DirOpppsite[dir_src]):
		enqueue_action(Action.TurnRight)
		enqueue_action(Action.TurnRight)
		enqueue_action(Action.Forward)
		return true
	return false
