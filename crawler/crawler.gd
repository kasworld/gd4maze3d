extends Node3D
class_name Crawler

signal crawler_goal_reached(st :Storey, cr :Crawler)

var crawler_animation := SimpleAnimation.new()

# rotate y
func start_turn_animation(rad :float) -> void:
	crawler_animation.start_rotation("ani_turn", self,
		rotation, rotation + Vector3(0, rad, 0),
		current_action.Second)

# rotate z
func start_roll_animation(rad :float) -> void:
	crawler_animation.start_rotation("ani_roll", self,
		rotation, rotation + Vector3(0, 0, rad),
		current_action.Second)

func _process(_delta: float) -> void:
	crawler_animation.handle_animation()

var action_queue :ActionQueue
var current_action : Dictionary # [Action, Second, Data]

var crawler_num :int
var player_num :int

var total_action_stats :Dictionary
var storey_action_stats :Dictionary
var storey :Storey
var pos_src :Vector2i
var dir_src : Maze.Dir

func getCameraLight() -> MovingCameraLight:
	return $MovingCameraLight

func get_minimap_posi() -> Vector2i:
	return pos_src
func get_color() -> Color:
	return $MeshInstance3D.mesh.material.albedo_color

func init(walk :Walk, n :int, LaneW:float,co :Color, p_num :int=0) -> Crawler:
	walk_mode = walk
	total_action_stats = ActionQueue.new_stats()
	dir_src = Maze.Dir.North
	current_action.clear()
	if n == p_num:
		action_queue = ActionQueue.new(0.1,2.0)
	else :
		action_queue = ActionQueue.new(0.2,3.0)
	crawler_num = n
	player_num = p_num
	$MeshInstance3D.mesh.material.albedo_color = co
	$MeshInstance3D.mesh.height = 0.2*LaneW
	$MeshInstance3D.mesh.top_radius = 0.01*LaneW
	$MeshInstance3D.mesh.bottom_radius = 0.07*LaneW
	$MeshInstance3D.rotation.x = -PI/2
	$MeshInstance3D.scale.x = 0.5
	$Label3D.text = "%d" % [ crawler_num ] # for debug
	crawler_animation.animation_ended.connect(animation_ended)
	$MovingCameraLight.get_light().light_energy = 1
	return self

func reset_scale() -> void:
	$MeshInstance3D.scale = Vector3(0.5,1,1)

func enter_storey(oldstorye :Storey, st :Storey, pos :Vector2i) -> void:
	action_queue.clear()
	action_queue.enqueue_with_second(ActionQueue.Action.EnterStorey, 1.0,
		{"From":oldstorye, "To":st, "src_v2i":pos,"dst_v2i":pos})
	storey = st
	pos_src = pos
	rotation.y = 0
	dir_src = Maze.RadianToDir(rotation.y)
	storey_action_stats = ActionQueue.new_stats()
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
				#start_move_animation(storey, pos_src, pos_src + Maze.DirToVt2[dir_src])
				var dst := pos_src + Maze.DirToVt2[dir_src]
				crawler_animation.add_animation(SimpleAnimation.MakeAnimation(
					"ani_move", self, "position",
					storey.maze3d.mazepos2storeypos(pos_src, 0),
					storey.maze3d.mazepos2storeypos(dst, 0),
					current_action.Second, {"src_v2i":pos_src, "dst_v2i" :dst} ))

			else :
				return false # action ignored
		ActionQueue.Action.TurnLeft:
			start_turn_animation(PI/2)
		ActionQueue.Action.TurnRight:
			start_turn_animation(-PI/2)
		ActionQueue.Action.TurnLeft2:
			start_turn_animation(PI)
		ActionQueue.Action.TurnRight2:
			start_turn_animation(-PI)
		ActionQueue.Action.RollRight:
			start_roll_animation(PI/2)
		ActionQueue.Action.RollLeft:
			start_roll_animation(-PI/2)
		ActionQueue.Action.RollRight2:
			start_roll_animation(PI)
		ActionQueue.Action.RollLeft2:
			start_roll_animation(-PI)
		ActionQueue.Action.EnterStorey: # for animation only
			var from_storey :Storey = current_action.Data.From if current_action.Data.From != null else current_action.Data.To
			start_inter_storey_move_animation(from_storey, current_action.Data.To, current_action.Data.src_v2i, current_action.Data.dst_v2i)
			astar_path_id.clear()

	# update action stats
	total_action_stats[current_action.Action ] += 1
	storey_action_stats[current_action.Action ] += 1
	return true

func start_inter_storey_move_animation(from :Storey, to :Storey, src :Vector2i, dst:Vector2i) -> void:
	var p2 := to.maze3d.mazepos2storeypos(dst, 0)
	var p1 :=  from.maze3d.mazepos2storeypos(src, 0) + from.global_position - to.global_position
	crawler_animation.add_animation(SimpleAnimation.MakeAnimation(
		"ani_move", self, "position", p1, p2, current_action.Second, {"src_v2i":src, "dst_v2i" :dst} ))

func animation_ended(cr :Node3D, ani :Dictionary) -> void:
	if crawler_animation.is_empty():
		current_action.clear()
	match ani.Name:
		"ani_move":
			pos_src = ani.Data.dst_v2i
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

func _to_string() -> String:
	return "Crawler[walk:%s action %ssec view roll:%s]" % [
		walk2str(walk_mode), action_queue.action_second, rotation_degrees,
		]

func debug_str() -> String:
	return "total:%s\nin storey:%s\n%s [%s]\n%s (%d, %d)" % [
		ActionQueue.stats2str(total_action_stats),
		ActionQueue.stats2str(storey_action_stats),
		current_action, action_queue,
		rotation_degrees,
		pos_src.x, pos_src.y,
		]

func can_move_to_dir(dir :Maze.Dir) -> bool:
	return storey.get_maze_cells().is_open_flag_at(pos_src.x, pos_src.y, Maze.DirToFlag[dir] )

var walk_mode : Walk
func set_next_walk_mode() -> Crawler:
	walk_mode = walk_next(walk_mode)
	return self
func set_walk_mode(t :Walk) -> void:
	walk_mode = t

enum Walk {Manual, RightFirst, LeftFirst, AStar}
static func walk2str(a :Walk) -> String:
	return Walk.keys()[a]
static func walk_next(a :Walk) -> Walk:
	return (a +1) % Walk.keys().size() as Walk

func enqueue_auto_walk_action_by_type() -> void:
	match walk_mode:
		Walk.RightFirst:
			walk_right_first()
		Walk.LeftFirst:
			walk_left_first()
		Walk.AStar:
			walk_astar()
		Walk.Manual:
			pass

var astar_path_id :PackedInt64Array
func walk_astar() -> void:
	var maze2d := storey.maze3d.maze_cells
	var cur_id := maze2d.posi_to_astar_id(pos_src.x, pos_src.y)
	if astar_path_id.is_empty() or astar_path_id[0] != cur_id:
		var goal_id := maze2d.posi_to_astar_id(storey.goal_posi.x, storey.goal_posi.y)
		astar_path_id = maze2d.astar.get_id_path(cur_id,goal_id)
	if astar_path_id.size() <= 1:
		return
	var pos_next := maze2d.astar_id_to_posi(astar_path_id[1])
	var dir_next := Maze.Vt2ToDir[pos_next-pos_src]
	if dir_src != dir_next:
		var dir_diff := (dir_next - dir_src +4 ) % 4
		match dir_diff:
			1:
				action_queue.enqueue(ActionQueue.Action.TurnLeft)
			2:
				action_queue.enqueue(ActionQueue.Action.TurnRight2)
			3:
				action_queue.enqueue(ActionQueue.Action.TurnRight)
			_:
				print_debug("dir_src %s dir_next %s dir_diff %s" % [dir_src, dir_next, dir_diff])
				assert(false) # something wrong
	action_queue.enqueue(ActionQueue.Action.Forward)
	return

func walk_right_first() -> void:
	# try right
	if can_move_to_dir(Maze.DirTurnRight[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnRight)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return
	# try forward
	if can_move_to_dir(dir_src):
		action_queue.enqueue(ActionQueue.Action.Forward)
		return
	# try left
	if can_move_to_dir(Maze.DirTurnLeft[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnLeft)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return
	# try backward
	if can_move_to_dir(Maze.DirOpppsite[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnLeft2)
		action_queue.enqueue(ActionQueue.Action.Forward)

func walk_left_first() -> void:
	# try left
	if can_move_to_dir(Maze.DirTurnLeft[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnLeft)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return
	# try forward
	if can_move_to_dir(dir_src):
		action_queue.enqueue(ActionQueue.Action.Forward)
		return
	# try right
	if can_move_to_dir(Maze.DirTurnRight[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnRight)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return
	# try backward
	if can_move_to_dir(Maze.DirOpppsite[dir_src]):
		action_queue.enqueue(ActionQueue.Action.TurnRight2)
		action_queue.enqueue(ActionQueue.Action.Forward)
		return
