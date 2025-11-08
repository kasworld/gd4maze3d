extends Node3D
class_name Crawler

var crawler_animation := Animation3D.new()
signal crawler_animation_ended(cr :Crawler, ani :Dictionary)
func animation_ended(st :Node3D, ani :Dictionary) -> void:
	dir_src = dir_dst
	pos_src = pos_dst
	current_action = {}
	roll_dir = roll_dir_dst
	snap_90()
	crawler_animation_ended.emit(st as Crawler, ani)

func start_move_animation(from :Storey, to :Storey) -> void:
	var p1 := from.maze3d_setting.mazepos2storeypos(pos_src, from.maze3d_setting.StoryH/2) + from.position
	var p2 := to.maze3d_setting.mazepos2storeypos(pos_dst, to.maze3d_setting.StoryH/2) + to.position
	crawler_animation.start_move("ani_move", self,
		p1, p2,
		1.0/current_action.APS)

func start_turn_animation(from :EnumDir.Dir, to :EnumDir.Dir) -> void:
	crawler_animation.start_rotate("ani_turn", self,
		Vector3(0, EnumDir.dir2rad(from), 0),
		Vector3(0, EnumDir.dir2rad(to), 0),
		1.0/current_action.APS)

func start_roll_animation(from :EnumRoll.Dir, to :EnumRoll.Dir) -> void:
	crawler_animation.start_rotate("ani_roll", self,
		Vector3(0, EnumRoll.dir2rad(from), 0),
		Vector3(0, EnumRoll.dir2rad(to), 0),
		1.0/current_action.APS)

func _process(_delta: float) -> void:
	crawler_animation.handle_animation()

var action_queue := ActionQueue.new()
var current_action : Dictionary # [Action, APS, Args]

var crawler_num :int
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


var auto_walk_type : Walk
func set_next_walk_type() -> Crawler:
	auto_walk_type = walk_next(auto_walk_type)
	return self
func set_auto_walk_type(t :Walk) -> void:
	auto_walk_type = t

func getCameraLight() -> MovingCameraLight:
	return $MovingCameraLight

func init(walk_type :Walk, n :int, LaneW:float,co :Color) -> Crawler:
	auto_walk_type = walk_type
	total_action_stats = ActionQueue.new_stats()
	dir_src = EnumDir.Dir.North
	current_action = {}
	action_queue.queue_init()
	crawler_num = n
	color = co
	$MovingCameraLight.init(n+1)
	$MeshInstance3D.mesh.material.albedo_color = co
	$MeshInstance3D.mesh.height = 0.2*LaneW
	$MeshInstance3D.mesh.top_radius = 0.01*LaneW
	$MeshInstance3D.mesh.bottom_radius = 0.07*LaneW
	$MeshInstance3D.rotation.x = -PI/2
	$MeshInstance3D.scale.x = 0.5
	$MeshInstance3D.position.x = LaneW*0.2
	$Label3D.text = "%d" % [ crawler_num ] # for debug
	crawler_animation.animation_ended.connect(animation_ended)
	return self

func enter_storey(oldstorye :Storey, st :Storey, pos :Vector2i) -> void:
	action_queue.clear_queue()
	current_action = ActionQueue.make_action_dictionary(ActionQueue.Action.EnterStorey ,1.0/2, {"FromStorey":oldstorye})
	storey = st
	pos_dst = pos
	storey_action_stats = ActionQueue.new_stats()
	action_queue.rand_act_speed()

func act_character() -> void:
	try_auto_walk()
	start_new_action()

func try_auto_walk() -> void:
	if current_action.is_empty() && action_queue.is_queue_empty(): # add new ai action
		match auto_walk_type:
			Walk.RightFirst:
				walk_right_first()
			Walk.LeftFirst:
				walk_left_first()
			Walk.Off:
				pass

# return true on new act
func start_new_action() -> bool:
	if not current_action.is_empty() || action_queue.is_queue_empty():
		return false
	#action_start_time = Time.get_unix_time_from_system()
	current_action = action_queue.action_pop_front()
	match current_action.Action :
		ActionQueue.Action.Forward:
			if can_move_to_dir(dir_src):
				pos_dst = pos_src + EnumDir.Dir2Vt[dir_src]
				start_move_animation(storey,storey)
			else :
				#end_action()
				return false
		ActionQueue.Action.TurnLeft:
			dir_dst = EnumDir.DirTurnLeft[dir_src]
			start_turn_animation(dir_src, dir_dst)
		ActionQueue.Action.TurnRight:
			dir_dst = EnumDir.DirTurnRight[dir_src]
			start_turn_animation(dir_src, dir_dst)
		ActionQueue.Action.RollRight:
			roll_dir_dst = EnumRoll.roll_right(roll_dir)
			start_roll_animation(roll_dir, roll_dir_dst)
		ActionQueue.Action.RollLeft:
			roll_dir_dst = EnumRoll.roll_left(roll_dir)
			start_roll_animation(roll_dir, roll_dir_dst)
		ActionQueue.Action.EnterStorey: # for animation only
			var from_storey :Storey = current_action.Args.FromStorey
			if from_storey == null:
				from_storey = storey
			start_move_animation(from_storey,storey)

	total_action_stats[current_action.Action ] += 1
	storey_action_stats[current_action.Action ] += 1
	return true

func snap_90() -> void:
	for i in 3:
		rotation[i] = snapped(rotation[i], PI/2)

func _to_string() -> String:
	return "Crawler[autowalk:%s act %s /sec view roll:%s° roll:%s]" % [
		walk2str(auto_walk_type), action_queue.action_per_second, roll_dir*90, rotation_degrees,
		]

func debug_str() -> String:
	return "total:%s\nin storey:%s\n%s [%s]\n%s->%s (%d, %d) -> (%d, %d)" % [
		ActionQueue.stats2str(total_action_stats),
		ActionQueue.stats2str(storey_action_stats),
		ActionQueue.action2str(current_action.Action), action_queue.queue2str(),
		EnumDir.Dir2Str[dir_src], EnumDir.Dir2Str[dir_dst],
		pos_src.x, pos_src.y, pos_dst.x, pos_dst.y,
		]

func can_move_to_dir(dir :EnumDir.Dir) -> bool:
	return storey.can_move(pos_src.x, pos_src.y, dir )

enum Walk {Off, RightFirst, LeftFirst}
static func walk2str(a :Walk) -> String:
	return Walk.keys()[a]
static func walk_next(a :Walk) -> Walk:
	return (a +1) % Walk.keys().size() as Walk

func walk_right_first() -> bool:
	# try right
	if can_move_to_dir(EnumDir.DirTurnRight[dir_src]):
		action_queue.enqueue_action(ActionQueue.Action.TurnRight)
		action_queue.enqueue_action(ActionQueue.Action.Forward)
		return true
	# try forward
	if can_move_to_dir(dir_src):
		action_queue.enqueue_action(ActionQueue.Action.Forward)
		return true
	# try left
	if can_move_to_dir(EnumDir.DirTurnLeft[dir_src]):
		action_queue.enqueue_action(ActionQueue.Action.TurnLeft)
		action_queue.enqueue_action(ActionQueue.Action.Forward)
		return true
	# try backward
	if can_move_to_dir(EnumDir.DirOpppsite[dir_src]):
		action_queue.enqueue_action(ActionQueue.Action.TurnLeft)
		action_queue.enqueue_action(ActionQueue.Action.TurnLeft)
		action_queue.enqueue_action(ActionQueue.Action.Forward)
		return true
	assert(false)
	return false

func walk_left_first() -> bool:
	# try left
	if can_move_to_dir(EnumDir.DirTurnLeft[dir_src]):
		action_queue.enqueue_action(ActionQueue.Action.TurnLeft)
		action_queue.enqueue_action(ActionQueue.Action.Forward)
		return true
	# try forward
	if can_move_to_dir(dir_src):
		action_queue.enqueue_action(ActionQueue.Action.Forward)
		return true
	# try right
	if can_move_to_dir(EnumDir.DirTurnRight[dir_src]):
		action_queue.enqueue_action(ActionQueue.Action.TurnRight)
		action_queue.enqueue_action(ActionQueue.Action.Forward)
		return true
	# try backward
	if can_move_to_dir(EnumDir.DirOpppsite[dir_src]):
		action_queue.enqueue_action(ActionQueue.Action.TurnRight)
		action_queue.enqueue_action(ActionQueue.Action.TurnRight)
		action_queue.enqueue_action(ActionQueue.Action.Forward)
		return true
	assert(false)
	return false
