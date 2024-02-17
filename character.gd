extends Node3D

class_name Character

var storey :Storey

var ani_act_dur :float # sec
enum Act {None, EnterStorey, Forward, TurnRight , TurnLeft, RotateCamera}
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

var dir_src : Storey.Dir
var dir_dst : Storey.Dir
var pos_src :Vector2i
var pos_dst :Vector2i
var camera_up :bool

var act_start_time :float # unixtime sec
var act_current : Act

var auto_move :bool

func _ready() -> void:
	var mi3d = new_cylinder(0.4, 0.15, NamedColorList.color_list.pick_random()[0])
	add_child(mi3d)
	total_act_stats = new_act_stats_dict()

func enter_storey(st :Storey, rndpos:bool)->void:
	ani_act_dur = randf_range(0.1,1.0)
	storey = st
	if rndpos :
		pos_dst = storey.rand_pos()
	else:
		pos_dst = storey.start_pos
	dir_src = Storey.Dir.North
	storey_act_stats = new_act_stats_dict()
	act_queue.resize(0)
	act_queue.append(Act.EnterStorey)

func light_on(b :bool)->void:
	$SpotLight3D.visible = b
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

# return 0 - 1
func get_ani_dur()->float:
	return (Time.get_unix_time_from_system() - act_start_time)/ani_act_dur

# return true on act end
func act_end(ani_dur :float)->bool:
	if act_current != Act.None && ani_dur > 1.0: # action ended
		dir_src = dir_dst
		pos_src = pos_dst
		act_current = Act.None
		$Camera3D.rotation.z = snapped($Camera3D.rotation.z, PI)
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
			Act.RotateCamera:
				camera_up = !camera_up
			Act.EnterStorey:
				pass
		total_act_stats[act_current] += 1
		storey_act_stats[act_current] += 1
		return true
	return false

func info_str()->String:
	return "total:%s\nin storey:%s\nautomove:%s\n%s [%s]\n%s->%s (%d, %d)->(%d, %d)\n[%s]" % [
		act_stats_str(total_act_stats), act_stats_str(storey_act_stats),
		auto_move,
		act2str(act_current), queue_to_str(),
		Storey.dir2str(dir_src), Storey.dir2str(dir_dst),
		pos_src.x, pos_src.y, pos_dst.x, pos_dst.y,
		storey.open_dir_str(pos_src.x, pos_src.y),
		]

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
	return Vector3(
		0.5+ lerpf(pos_src.x, pos_dst.x, dur),
		storey.storey_h/2.0,
		0.5+ lerpf(pos_src.y, pos_dst.y, dur),
	)

func calc_animate_turn_by_dur(dur :float)->float:
	return lerp_angle(Storey.dir2rad(dir_src), Storey.dir2rad(dir_dst), dur)

func calc_animate_camera_rotate(dur :float)->float:
	if camera_up:
		return lerp_angle(0, PI, dur)
	else :
		return lerp_angle(PI, 0, dur)

func rotate_camera( rad :float)->void:
	$Camera3D.rotation.z = rad
