extends Node3D

class_name Character

enum ViewDir {Up,Right,Down,Left}
static func viewdir2str(vd :ViewDir)->String:
	return ViewDir.keys()[vd]
static func viewdir_left(d:ViewDir)->ViewDir:
	return (d+1)%4 as ViewDir
static func viewdir_right(d:ViewDir)->ViewDir:
	return (d-1+4)%4 as ViewDir
static func viewdir_opposite(d:ViewDir)->ViewDir:
	return (d+2)%4 as ViewDir
static func viewdir2rad(d:ViewDir)->float:
	return deg_to_rad(d*90.0)

enum Action {None, EnterStorey, Forward, TurnRight , TurnLeft, RotateCameraRight, RotateCameraLeft}
static func action2str(a :Action)->String:
	return Action.keys()[a]

var total_action_stats :Dictionary
var storey_action_stats :Dictionary
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

var action_queue :Array[Action]
func enqueue_action(a :Action)->void:
	action_queue.push_back(a)
func queue_to_str()->String:
	var rtn = ""
	for a in action_queue:
		rtn += "%s " % [ Character.action2str(a) ]
	return rtn

var storey :Storey
var sec_per_action :float # sec

var dir_src : Storey.Dir
var dir_dst : Storey.Dir
var pos_src :Vector2i
var pos_dst :Vector2i
var view_dir :ViewDir
var view_dir_dst :ViewDir

var action_start_time :float # unixtime sec
var action_current : Action

var serial :int
var auto_move :bool

func init(n :int, lane_w:float, auto :bool)->void:
	var mi3d = new_cylinder(0.4*lane_w, 0.15*lane_w, NamedColorList.color_list.pick_random()[0])
	add_child(mi3d)
	serial = n
	auto_move = auto
	total_action_stats = Character.new_action_stats_dict()
	dir_src = Storey.Dir.North

func enter_storey(st :Storey, start_at:bool)->void:
	sec_per_action = randf_range(0.1,1.0)
	storey = st
	if start_at :
		pos_dst = storey.start_pos
	else:
		pos_dst = storey.rand_pos()
	storey_action_stats = Character.new_action_stats_dict()
	action_queue.resize(0)
	action_queue.append(Action.EnterStorey)

# return 0 - 1
func get_animation_progress()->float:
	return (Time.get_unix_time_from_system() - action_start_time)/sec_per_action

# success when act ended
func set_sec_per_action(v :float)->bool:
	if is_action_ended(get_animation_progress()):
		sec_per_action = v
		return true
	return false

# return true on act end
func is_action_ended(ani_dur :float)->bool:
	if action_current != Action.None && ani_dur > 1.0: # action ended
		dir_src = dir_dst
		pos_src = pos_dst
		view_dir = view_dir_dst
		action_current = Action.None
		return true
	return false

func ai_action()->void:
	if auto_move && action_current == Action.None && action_queue.size() == 0: # add new ai action
		make_ai_action()

# return true on new act
func start_new_action()->bool:
	if action_current == Action.None && action_queue.size() > 0: # start new action
		action_start_time = Time.get_unix_time_from_system()
		action_current = action_queue.pop_front()
		match action_current:
			Action.None:
				pass
			Action.Forward:
				if can_move(dir_src):
					pos_dst = pos_src + Storey.Dir2Vt[dir_src]
				else :
					action_current = Action.None
			Action.TurnLeft:
				dir_dst = Storey.dir_left(dir_src)
			Action.TurnRight:
				dir_dst = Storey.dir_right(dir_src)
			Action.RotateCameraRight:
				view_dir_dst = Character.viewdir_right(view_dir)
			Action.RotateCameraLeft:
				view_dir_dst = Character.viewdir_left(view_dir)
			Action.EnterStorey:
				pass
		total_action_stats[action_current] += 1
		storey_action_stats[action_current] += 1
		return true
	return false

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

func calc_animation_move_by_dur(dur :float)->Vector3:
	var p1 = storey.mazepos2storeypos(pos_src,storey.storey_num*storey.storey_h+ storey.storey_h/2.0)
	var p2 = storey.mazepos2storeypos(pos_dst,storey.storey_num*storey.storey_h+ storey.storey_h/2.0)
	return p1.lerp(p2,dur)

func calc_animation_move_storey_by_dur(dur :float, stn :int)->Vector3:
	var p1 = storey.mazepos2storeypos(pos_src,stn*storey.storey_h+ storey.storey_h/2.0)
	var p2 = storey.mazepos2storeypos(pos_dst,storey.storey_num*storey.storey_h+ storey.storey_h/2.0)
	return p1.lerp(p2,dur)

func calc_animation_turn_by_dur(dur :float)->float:
	return lerp_angle(Storey.dir2rad(dir_src), Storey.dir2rad(dir_dst), dur)

func calc_animation_camera_rotate(dur :float)->float:
	return lerp_angle(Character.viewdir2rad(view_dir), Character.viewdir2rad(view_dir_dst), dur)

func new_cylinder(h :float, r :float, co :Color)->MeshInstance3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = co
	#mat.metallic = 1
	#mat.clearcoat = true
	var mesh = CylinderMesh.new()
	mesh.height = h
	mesh.bottom_radius = r
	mesh.top_radius = 0
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.rotation.x = -PI/2
	return sp

func info_str()->String:
	return "automove:%s, view rotate:%s°, act %.1f /sec" % [
		auto_move, view_dir*90, 1.0/sec_per_action,
		]

func debug_str()->String:
	return "total:%s\nin storey:%s\n%s [%s]\n%s->%s (%d, %d)->(%d, %d)\nOpen: %s" % [
		Character.act_stats_str(total_action_stats),
		Character.act_stats_str(storey_action_stats),
		Character.action2str(action_current), queue_to_str(),
		Storey.dir2str(dir_src), Storey.dir2str(dir_dst),
		pos_src.x, pos_src.y, pos_dst.x, pos_dst.y,
		storey.maze_cells.open_dir_str(pos_src.x, pos_src.y),
		]
