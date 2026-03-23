extends Node3D
class_name Crawler

signal crawler_goal_reached(st :Storey, cr :Crawler)

var crawler_animation := SimpleAnimation.new()
func animation_ended(cr :Node3D, ani :Dictionary) -> void:
	if crawler_animation.is_empty():
		current_action.clear()
	match ani.Name:
		"ani_move":
			pos_src = pos_dst
			if cr.crawler_num == player_num:
				if storey.is_goal_pos(cr.pos_src):
					crawler_goal_reached.emit(storey, cr)
					return
				storey.놓인것들줍기(cr)
			storey.get_mini_map().update_obj_pos(cr, cr.crawler_num == player_num)
		"ani_turn":
			rotation = rotation.snappedf(PI/2)
			dir_src = Maze.RadianToDir(rotation.y)
		"ani_roll":
			pass
	act_character()

func start_move_animation(st :Storey, src :Vector2i, dst:Vector2i) -> void:
	var y := 0
	var p1 := st.maze3d.mazepos2storeypos(src, y)
	var p2 := st.maze3d.mazepos2storeypos(dst, y)
	crawler_animation.start_move("ani_move", self,
		p1, p2,
		1.0/current_action.APS)

func start_inter_storey_move_animation(from :Storey, to :Storey, src :Vector2i, dst:Vector2i) -> void:
	var diff := to.global_position - from.global_position
	var p1 := from.maze3d.mazepos2storeypos(src, 0) - diff
	var p2 := to.maze3d.mazepos2storeypos(dst, 0)
	crawler_animation.start_move("ani_move", self,
		p1, p2,
		1.0/current_action.APS)

# rotate y
func start_turn_animation(rad :float) -> void:
	crawler_animation.start_rotation("ani_turn", self,
		rotation, rotation + Vector3(0, rad, 0),
		1.0/current_action.APS)

# rotate z
func start_roll_animation(rad :float) -> void:
	crawler_animation.start_rotation("ani_roll", self,
		rotation, rotation + Vector3(0, 0, rad),
		1.0/current_action.APS)

func _process(_delta: float) -> void:
	crawler_animation.handle_animation()

var action_queue := ActionQueue.new()
var current_action : Dictionary # [Action, APS, Args]

var crawler_num :int
var player_num :int

var total_action_stats :Dictionary
var storey_action_stats :Dictionary
var storey :Storey
var pos_src :Vector2i
var pos_dst :Vector2i
var dir_src : Maze.Dir

func getCameraLight() -> MovingCameraLight:
	return $MovingCameraLight

func get_posi() -> Vector2i:
	return pos_src
func get_color() -> Color:
	return $MeshInstance3D.mesh.material.albedo_color

func init(walk_type :Walk, n :int, LaneW:float,co :Color, p_num :int=0) -> Crawler:
	auto_walk_type = walk_type
	total_action_stats = ActionQueue.new_stats()
	dir_src = Maze.Dir.North
	current_action.clear()
	crawler_num = n
	player_num = p_num
	$MeshInstance3D.mesh.material.albedo_color = co
	$MeshInstance3D.mesh.height = 0.2*LaneW
	$MeshInstance3D.mesh.top_radius = 0.01*LaneW
	$MeshInstance3D.mesh.bottom_radius = 0.07*LaneW
	$MeshInstance3D.rotation.x = -PI/2
	$MeshInstance3D.scale.x = 0.5
	#$MeshInstance3D.position.x = LaneW*0.1
	#$MeshInstance3D.position.z = -LaneW*0.1
	$Label3D.text = "%d" % [ crawler_num ] # for debug
	#$Label3D.position.x = LaneW*0.05
	#$MovingCameraLight.position.z = LaneW*0.3
	crawler_animation.animation_ended.connect(animation_ended)
	$MovingCameraLight.get_light().light_energy = 1
	return self

func enter_storey(oldstorye :Storey, st :Storey, pos :Vector2i) -> void:
	action_queue.clear()
	action_queue.enqueue_with_speed(ActionQueue.Action.EnterStorey ,1.0/2, {"FromStorey":oldstorye})
	storey = st
	pos_dst = pos
	pos_src = pos
	rotation.y = 0
	dir_src = Maze.RadianToDir(rotation.y)
	storey_action_stats = ActionQueue.new_stats()
	action_queue.rand_act_speed()
	rotation = rotation.snappedf(PI/2)
	act_character()

func act_character() -> void:
	if crawler_animation.is_empty() and not current_action.is_empty():
		print_debug("animation ended but current_action not cleared %s" %[ current_action ])
		current_action.clear()
	if current_action.is_empty() && action_queue.is_empty():
		enqueue_auto_walk_action_by_type()
	if current_action.is_empty() && not action_queue.is_empty():
		handle_action_in_queue()

# return true on new act
func handle_action_in_queue() -> bool:
	current_action = action_queue.pop_front()
	match current_action.Action :
		ActionQueue.Action.Forward:
			if can_move_to_dir(dir_src):
				pos_dst = pos_src + Maze.DirToVt2[dir_src]
				start_move_animation(storey, pos_src, pos_dst)
			else :
				return false # action ignored
		ActionQueue.Action.TurnLeft:
			start_turn_animation(PI/2)
		ActionQueue.Action.TurnRight:
			start_turn_animation(-PI/2)
		ActionQueue.Action.RollRight:
			start_roll_animation(PI/2)
		ActionQueue.Action.RollLeft:
			start_roll_animation(-PI/2)
		ActionQueue.Action.EnterStorey: # for animation only
			var from_storey :Storey = current_action.Args.FromStorey
			if from_storey == null:
				from_storey = storey
			start_inter_storey_move_animation(from_storey,storey, pos_src, pos_dst)

	# update action stats
	total_action_stats[current_action.Action ] += 1
	storey_action_stats[current_action.Action ] += 1
	return true

func _to_string() -> String:
	return "Crawler[autowalk:%s act %s /sec view roll:%s]" % [
		walk2str(auto_walk_type), action_queue.action_per_second, rotation_degrees,
		]

func debug_str() -> String:
	return "total:%s\nin storey:%s\n%s [%s]\n%s (%d, %d) -> (%d, %d)" % [
		ActionQueue.stats2str(total_action_stats),
		ActionQueue.stats2str(storey_action_stats),
		current_action, action_queue,
		rotation_degrees,
		pos_src.x, pos_src.y, pos_dst.x, pos_dst.y,
		]

func can_move_to_dir(dir :Maze.Dir) -> bool:
	return storey.get_maze_cells().is_open_flag_at(pos_src.x, pos_src.y, Maze.DirToFlag[dir] )

var auto_walk_type : Walk
func set_next_walk_type() -> Crawler:
	auto_walk_type = walk_next(auto_walk_type)
	return self
func set_auto_walk_type(t :Walk) -> void:
	auto_walk_type = t

enum Walk {Off, RightFirst, LeftFirst}
static func walk2str(a :Walk) -> String:
	return Walk.keys()[a]
static func walk_next(a :Walk) -> Walk:
	return (a +1) % Walk.keys().size() as Walk

func enqueue_auto_walk_action_by_type() -> void:
	match auto_walk_type:
		Walk.RightFirst:
			walk_right_first()
		Walk.LeftFirst:
			walk_left_first()
		Walk.Off:
			pass

func walk_right_first() -> bool:
	# try right
	if can_move_to_dir(Maze.DirTurnRight[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnRight)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return true
	# try forward
	if can_move_to_dir(dir_src):
		action_queue.enqueue(ActionQueue.Action.Forward)
		return true
	# try left
	if can_move_to_dir(Maze.DirTurnLeft[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnLeft)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return true
	# try backward
	if can_move_to_dir(Maze.DirOpppsite[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnLeft)
		action_queue.enqueue(ActionQueue.Action.TurnLeft)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return true
	assert(false)
	return false

func walk_left_first() -> bool:
	# try left
	if can_move_to_dir(Maze.DirTurnLeft[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnLeft)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return true
	# try forward
	if can_move_to_dir(dir_src):
		action_queue.enqueue(ActionQueue.Action.Forward)
		return true
	# try right
	if can_move_to_dir(Maze.DirTurnRight[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnRight)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return true
	# try backward
	if can_move_to_dir(Maze.DirOpppsite[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnRight)
		action_queue.enqueue(ActionQueue.Action.TurnRight)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return true
	assert(false)
	return false
