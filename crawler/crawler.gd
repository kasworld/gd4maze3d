extends Node3D
class_name Crawler

enum Action {EnterStorey, Forward, TurnRight , TurnLeft, RollRight, RollLeft}
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
	
func clear_queue() -> void:
	queue.resize(0)
	
func is_queue_empty() -> bool:
	return queue.is_empty()
	
func action_pop_front() -> Dictionary:
	return queue.pop_front()

func enqueue_action(a :Action, args :={}) -> Crawler:
	return enqueue_action_with_speed(a, action_per_second.get_value(), args)

func enqueue_action_with_speed(a :Action,s :float, args :={}) -> Crawler:
	queue.push_back(make_action_dictionary(a,s,args))
	return crop_queue()

func make_action_dictionary(a :Action,s :float, args :={}) -> Dictionary:
	return {
		"Action":a,
		"APS":s, 
		"Args":args,
	}

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
var current_action : Dictionary # [Action, APS, Args]

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
	current_action = {}
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
	if not current_action.is_empty() || is_queue_empty():
		return false
	action_start_time = Time.get_unix_time_from_system()
	current_action = action_pop_front()
	match current_action.Action :
		Action.Forward:
			if can_move_to_dir(dir_src):
				pos_dst = pos_src + EnumDir.Dir2Vt[dir_src]
			else :
				end_action()
				return false
		Action.TurnLeft:
			dir_dst = EnumDir.DirTurnLeft[dir_src]
		Action.TurnRight:
			dir_dst = EnumDir.DirTurnRight[dir_src]
		Action.RollRight:
			roll_dir_dst = EnumRoll.roll_right(roll_dir)
		Action.RollLeft:
			roll_dir_dst = EnumRoll.roll_left(roll_dir)
		Action.EnterStorey: # for animation only
			pass
	total_action_stats[current_action.Action ] += 1
	storey_action_stats[current_action.Action ] += 1
	return true
	
func enter_storey(oldstorye :Storey, st :Storey, pos :Vector2i) -> void:
	clear_queue()
	current_action = make_action_dictionary(Action.EnterStorey ,1.0/2, {"FromStorey":oldstorye})
	action_start_time = Time.get_unix_time_from_system()
	storey = st
	pos_dst = pos
	storey_action_stats = new_stats()
	rand_act_speed()

func act_character() -> void:
	try_auto_walk()
	start_new_action()
	if not current_action.is_empty():
		animate_action()

func animate_action() -> void:
	match current_action.Action:
		Action.Forward:
			animate_move(storey, storey)
		Action.TurnLeft, Action.TurnRight:
			animate_turn()
		Action.RollRight,Action.RollLeft:
			animate_roll()
		Action.EnterStorey:
			var from_storey = current_action.Args.FromStorey
			if from_storey == null:
				from_storey = storey
			animate_move(from_storey, storey)

# return true on act end
func is_current_action_ended() -> bool:
	return not current_action.is_empty() && get_animation_progress() > 1.0

func end_action() -> void:
	dir_src = dir_dst
	pos_src = pos_dst
	current_action = {}
	roll_dir = roll_dir_dst
	snap_90()

# return 0 - 1
func get_animation_progress() -> float:
	if current_action.is_empty():
		return 0
	return (Time.get_unix_time_from_system() - action_start_time)*current_action.APS

func animate_move(from :Storey, to :Storey) -> void:
	var dur = get_animation_progress()
	var p1 = from.mazepos2storeypos(pos_src, from.storey_setting.StoryH/2) + from.position 
	var p2 = to.mazepos2storeypos(pos_dst, to.storey_setting.StoryH/2) + to.position 
	position = p1.lerp(p2,dur)
	#rotation += from.rotation.lerp(to.rotation,dur)

func animate_turn() -> void:
	var dur = get_animation_progress()
	rotation.y = lerp_angle(EnumDir.dir2rad(dir_src), EnumDir.dir2rad(dir_dst), dur)

func animate_roll() -> void:
	var dur = get_animation_progress()
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
		action2str(current_action.Action ), queue2str(),
		EnumDir.DirToStr[dir_src], EnumDir.DirToStr[dir_dst],
		pos_src.x, pos_src.y, pos_dst.x, pos_dst.y,
		]

func try_auto_walk() -> void:
	if current_action.is_empty() && is_queue_empty(): # add new ai action
		match auto_walk_type:
			Walk.RightFirst:
				walk_right_first()
			Walk.LeftFirst:
				walk_left_first()
			Walk.Off:
				pass

func can_move_to_dir(dir :EnumDir.Dir) -> bool:
	return storey.can_move(pos_src.x, pos_src.y, dir )

func walk_right_first() -> bool:
	# try right
	if can_move_to_dir(EnumDir.DirTurnRight[dir_src]):
		enqueue_action(Action.TurnRight)
		enqueue_action(Action.Forward)
		return true
	# try forward
	if can_move_to_dir(dir_src):
		enqueue_action(Action.Forward)
		return true
	# try left
	if can_move_to_dir(EnumDir.DirTurnLeft[dir_src]):
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.Forward)
		return true
	# try backward
	if can_move_to_dir(EnumDir.DirOpppsite[dir_src]):
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.Forward)
		return true
	return false

func walk_left_first() -> bool:
	# try left
	if can_move_to_dir(EnumDir.DirTurnLeft[dir_src]):
		enqueue_action(Action.TurnLeft)
		enqueue_action(Action.Forward)
		return true
	# try forward
	if can_move_to_dir(dir_src):
		enqueue_action(Action.Forward)
		return true
	# try right
	if can_move_to_dir(EnumDir.DirTurnRight[dir_src]):
		enqueue_action(Action.TurnRight)
		enqueue_action(Action.Forward)
		return true
	# try backward
	if can_move_to_dir(EnumDir.DirOpppsite[dir_src]):
		enqueue_action(Action.TurnRight)
		enqueue_action(Action.TurnRight)
		enqueue_action(Action.Forward)
		return true
	return false
