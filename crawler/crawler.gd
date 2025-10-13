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


var action_queue :ActionQueue
var action_start_time :float # unixtime sec
var action_current : Array # [Action, action_per_second.value]

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

var ai_walk_type := EnumWalk.Walk.RightFirst
func set_next_walk_type() -> Crawler:
	ai_walk_type = EnumWalk.next(ai_walk_type)
	return self
func set_ai_walk_type(t :EnumWalk.Walk) -> void:
	ai_walk_type = t

func init(walk_type :EnumWalk.Walk, n :int, LaneW:float,co :Color) -> Crawler:
	ai_walk_type = walk_type
	total_action_stats = Crawler.new_stats()
	dir_src = EnumDir.Dir.North
	action_current = [Crawler.Action.None, 0,[]]
	action_queue = ActionQueue.new().init()
	add_shape(n,LaneW,co)
	return self

func add_shape(n :int, LaneW:float,co :Color) -> Crawler:
	serial = n
	color = co
	var mat = StandardMaterial3D.new()
	mat.albedo_color = co
	var mesh = CylinderMesh.new()
	mesh.height = 0.2*LaneW
	mesh.top_radius = 0.01*LaneW
	mesh.bottom_radius = 0.07*LaneW
	mesh.radial_segments = 5
	mesh.material = mat
	var mi3d = MeshInstance3D.new()
	mi3d.mesh = mesh
	mi3d.rotation.x = -PI/2
	mi3d.scale.x = 0.5
	mi3d.position.x = LaneW*0.2
	add_child(mi3d)
	return self

# return true on new act
func start_new_action() -> bool:
	if action_current[0] != Crawler.Action.None || action_queue.is_empty():
		return false
	action_start_time = Time.get_unix_time_from_system()
	action_current = action_queue.pop_front()
	match action_current[0]:
		Crawler.Action.Forward:
			if can_move(dir_src):
				pos_dst = pos_src + EnumDir.Dir2Vt[dir_src]
			else :
				action_current = [Crawler.Action.None, 0,[]]
		Crawler.Action.TurnLeft:
			dir_dst = EnumDir.DirTurnLeft[dir_src]
		Crawler.Action.TurnRight:
			dir_dst = EnumDir.DirTurnRight[dir_src]
		Crawler.Action.RollRight:
			roll_dir_dst = EnumRoll.roll_right(roll_dir)
		Crawler.Action.RollLeft:
			roll_dir_dst = EnumRoll.roll_left(roll_dir)
		Crawler.Action.EnterStorey:
			var args = action_current[2]
			storey = args[0]
			pos_dst = args[1]
			storey_action_stats = Crawler.new_stats()
			action_queue.rand_act_speed()
			animate_move_by_dur(0, storey, storey)
			animate_turn_by_dur(0)
	total_action_stats[action_current[0]] += 1
	storey_action_stats[action_current[0]] += 1
	return true

# return true on act end
func is_action_ended(ani_dur :float) -> bool:
	return action_current[0] != Crawler.Action.None && ani_dur > 1.0

func end_action() -> void:
	dir_src = dir_dst
	pos_src = pos_dst
	action_current = [Crawler.Action.None, 0,[]]
	roll_dir = roll_dir_dst
	snap_90()

func ai_action() -> void:
	if action_current[0] == Crawler.Action.None && action_queue.is_empty(): # add new ai action
		match ai_walk_type:
			EnumWalk.Walk.RightFirst:
				walk_right_first()
			EnumWalk.Walk.LeftFirst:
				walk_left_first()
			EnumWalk.Walk.Off:
				pass

func walk_right_first() -> bool:
	# try right
	if can_move(EnumDir.DirTurnRight[dir_src]):
		action_queue.enqueue_action(Crawler.Action.TurnRight)
		action_queue.enqueue_action(Crawler.Action.Forward)
		return true
	# try forward
	if can_move(dir_src):
		action_queue.enqueue_action(Crawler.Action.Forward)
		return true
	# try left
	if can_move(EnumDir.DirTurnLeft[dir_src]):
		action_queue.enqueue_action(Crawler.Action.TurnLeft)
		action_queue.enqueue_action(Crawler.Action.Forward)
		return true
	# try backward
	if can_move(EnumDir.DirOpppsite[dir_src]):
		action_queue.enqueue_action(Crawler.Action.TurnLeft)
		action_queue.enqueue_action(Crawler.Action.TurnLeft)
		action_queue.enqueue_action(Crawler.Action.Forward)
		return true
	return false

func walk_left_first() -> bool:
	# try left
	if can_move(EnumDir.DirTurnLeft[dir_src]):
		action_queue.enqueue_action(Crawler.Action.TurnLeft)
		action_queue.enqueue_action(Crawler.Action.Forward)
		return true
	# try forward
	if can_move(dir_src):
		action_queue.enqueue_action(Crawler.Action.Forward)
		return true
	# try right
	if can_move(EnumDir.DirTurnRight[dir_src]):
		action_queue.enqueue_action(Crawler.Action.TurnRight)
		action_queue.enqueue_action(Crawler.Action.Forward)
		return true
	# try backward
	if can_move(EnumDir.DirOpppsite[dir_src]):
		action_queue.enqueue_action(Crawler.Action.TurnRight)
		action_queue.enqueue_action(Crawler.Action.TurnRight)
		action_queue.enqueue_action(Crawler.Action.Forward)
		return true
	return false

func can_move(dir :EnumDir.Dir) -> bool:
	return storey.can_move(pos_src.x, pos_src.y, dir )

# return 0 - 1
func get_animation_progress() -> float:
	return (Time.get_unix_time_from_system() - action_start_time)*action_current[1]

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
		EnumWalk.walk2str(ai_walk_type), action_queue.action_per_second, roll_dir*90, rotation_degrees,
		]

func debug_str() -> String:
	return "total:%s\nin storey:%s\n%s [%s]\n%s->%s (%d, %d) -> (%d, %d)" % [
		Crawler.stats2str(total_action_stats),
		Crawler.stats2str(storey_action_stats),
		Crawler.action2str(action_current[0]), action_queue,
		EnumDir.DirToStr[dir_src], EnumDir.DirToStr[dir_dst],
		pos_src.x, pos_src.y, pos_dst.x, pos_dst.y,
		]
