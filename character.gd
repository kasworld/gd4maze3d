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

enum Act {None, EnterStorey, Forward, TurnRight , TurnLeft, RotateCameraRight, RotateCameraLeft}
func act2str(a :Act)->String:
	return Act.keys()[a]

var total_act_stats :Dictionary
var storey_act_stats :Dictionary
func new_act_stats_dict()->Dictionary:
	var rtn = {}
	for k in Act.values():
		rtn[k]=0
	return rtn
func act_stats_str(d:Dictionary)->String:
	var rtn = ""
	for i in Act.values():
		rtn += " %s:%d" % [act2str(i), d[i]]
	return rtn

var act_queue :Array[Act]
func queue_act(a :Act)->void:
	act_queue.push_back(a)
func queue_to_str()->String:
	var rtn = ""
	for a in act_queue:
		rtn += "%s " % [ act2str(a) ]
	return rtn

var storey :Storey
var sec_per_animate_act :float # sec

var dir_src : Storey.Dir
var dir_dst : Storey.Dir
var pos_src :Vector2i
var pos_dst :Vector2i
var view_dir :ViewDir
var view_dir_dst :ViewDir

var act_start_time :float # unixtime sec
var act_current : Act

var is_player :bool
var auto_move :bool

func init(lane_w:float, pl:bool, auto :bool)->void:
	var mi3d = new_cylinder(0.4*lane_w, 0.15*lane_w, NamedColorList.color_list.pick_random()[0])
	add_child(mi3d)
	is_player = pl
	auto_move = auto
	if is_player:
		light_on(true)
	total_act_stats = new_act_stats_dict()
	dir_src = Storey.Dir.North

func enter_storey(st :Storey)->void:
	sec_per_animate_act = randf_range(0.1,1.0)
	storey = st
	if is_player :
		pos_dst = storey.start_pos
	else:
		pos_dst = storey.rand_pos()
	storey_act_stats = new_act_stats_dict()
	act_queue.resize(0)
	act_queue.append(Act.EnterStorey)

# return 0 - 1
func get_animate_progress()->float:
	return (Time.get_unix_time_from_system() - act_start_time)/sec_per_animate_act

# success when act ended
func set_sec_per_animate_act(v :float)->bool:
	if is_act_ended(get_animate_progress()):
		sec_per_animate_act = v
		return true
	return false

# return true on act end
func is_act_ended(ani_dur :float)->bool:
	if act_current != Act.None && ani_dur > 1.0: # action ended
		dir_src = dir_dst
		pos_src = pos_dst
		view_dir = view_dir_dst
		act_current = Act.None
		$Camera3D.rotation.z = snapped($Camera3D.rotation.z, PI/2)
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
			Act.None:
				pass
			Act.Forward:
				if can_move(dir_src):
					pos_dst = pos_src + Storey.Dir2Vt[dir_src]
				else :
					act_current = Act.None
			Act.TurnLeft:
				dir_dst = Storey.dir_left(dir_src)
			Act.TurnRight:
				dir_dst = Storey.dir_right(dir_src)
			Act.RotateCameraRight:
				view_dir_dst = Character.viewdir_right(view_dir)
			Act.RotateCameraLeft:
				view_dir_dst = Character.viewdir_left(view_dir)
			Act.EnterStorey:
				pass
		total_act_stats[act_current] += 1
		storey_act_stats[act_current] += 1
		return true
	return false

func make_ai_action()->bool:
	# try right
	if can_move(Storey.dir_right(dir_src)):
		queue_act(Act.TurnRight)
		queue_act(Act.Forward)
		return true
	# try forward
	if can_move(dir_src):
		queue_act(Act.Forward)
		return true
	# try left
	if can_move(Storey.dir_left(dir_src)):
		queue_act(Act.TurnLeft)
		queue_act(Act.Forward)
		return true
	# try backward
	if can_move(Storey.dir_opposite(dir_src)):
		queue_act(Act.TurnLeft)
		queue_act(Act.TurnLeft)
		queue_act(Act.Forward)
		return true
	return false

func can_move(dir :Storey.Dir)->bool:
	return storey.can_move(pos_src.x, pos_src.y, dir )

func calc_animate_move_by_dur(dur :float)->Vector3:
	var p1 = storey.mazepos2storeypos(pos_src,storey.storey_num*storey.storey_h+ storey.storey_h/2.0)
	var p2 = storey.mazepos2storeypos(pos_dst,storey.storey_num*storey.storey_h+ storey.storey_h/2.0)
	return p1.lerp(p2,dur)

func calc_animate_move_storey_by_dur(dur :float, stn :int)->Vector3:
	var p1 = storey.mazepos2storeypos(pos_src,stn*storey.storey_h+ storey.storey_h/2.0)
	var p2 = storey.mazepos2storeypos(pos_dst,storey.storey_num*storey.storey_h+ storey.storey_h/2.0)
	return p1.lerp(p2,dur)

func calc_animate_turn_by_dur(dur :float)->float:
	return lerp_angle(Storey.dir2rad(dir_src), Storey.dir2rad(dir_dst), dur)

func calc_animate_camera_rotate(dur :float)->float:
	return lerp_angle(Character.viewdir2rad(view_dir), Character.viewdir2rad(view_dir_dst), dur)

func rotate_camera( rad :float)->void:
	$Camera3D.rotation.z = rad

func light_on(b :bool)->void:
	$SpotLight3D.visible = b
	#$OmniLight3D.visible = b
	$Camera3D.visible = b
	$Camera3D.current = b

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
		auto_move, view_dir*90, 1.0/sec_per_animate_act,
		]

func debug_str()->String:
	return "total:%s\nin storey:%s\n%s [%s]\n%s->%s (%d, %d)->(%d, %d)\nOpen: %s" % [
		act_stats_str(total_act_stats),
		act_stats_str(storey_act_stats),
		act2str(act_current), queue_to_str(),
		Storey.dir2str(dir_src), Storey.dir2str(dir_dst),
		pos_src.x, pos_src.y, pos_dst.x, pos_dst.y,
		storey.maze_cells.open_dir_str(pos_src.x, pos_src.y),
		]
