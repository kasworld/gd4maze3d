extends Node3D

class_name Character

var storey :Storey

var ani_act_dur :float # sec
enum Act {None, Forward, TurnRight , TurnLeft, RotateCamera}
func act2str(a :Act)->String:
	return Act.keys()[a]

var act_queue :Array[Act]
func queue_to_str()->String:
	var rtn = ""
	for a in act_queue:
		rtn += "%s " % [ act2str(a) ]
	return rtn

var dir_old : Storey.Dir
var dir_new : Storey.Dir
var pos_old :Vector2i
var pos_new :Vector2i
var camera_up :bool

var act_start_time :float # unixtime sec
var act_current : Act

var auto_move :bool

func _ready() -> void:
	var mi3d = new_cylinder(0.4, 0.15, NamedColorList.color_list.pick_random()[0])
	add_child(mi3d)

func enter_storey(st :Storey, rndpos:bool)->void:
	ani_act_dur = randf_range(0.1,1.0)
	storey = st
	if rndpos :
		pos_old = storey.rand_pos()
		$SpotLight3D.visible = false
	else:
		pos_old = storey.start_pos
		$SpotLight3D.visible = true
	pos_new = pos_old
	dir_old = Storey.Dir.North
	dir_new = dir_old

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
		dir_old = dir_new
		pos_old = pos_new
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
			Act.Forward:
				if can_move(dir_old):
					pos_new = pos_old + Storey.Dir2Vt[dir_old]
				else :
					act_current = Act.None
			Act.TurnLeft:
				dir_new = Storey.dir_left(dir_old)
			Act.TurnRight:
				dir_new = Storey.dir_right(dir_old)
			Act.RotateCamera:
				camera_up = !camera_up
		return true
	return false

func info_str()->String:
	return "automove:%s\n%s [%s]\n%s->%s (%d, %d)->(%d, %d)\n[%s]" % [
		auto_move,
		act2str(act_current), queue_to_str(),
		Storey.dir2str(dir_old), Storey.dir2str(dir_new),
		pos_old.x, pos_old.y, pos_new.x, pos_new.y,
		storey.open_dir_str(pos_old.x, pos_old.y),
		]

func camera_current(b :bool)->void:
	$Camera3D.current = b

func make_ai_action()->bool:
	# try right
	if can_move(Storey.dir_right(dir_old)):
		act_queue.push_back(Act.TurnRight)
		act_queue.push_back(Act.Forward)
		return true
	# try forward
	if can_move(dir_old):
		act_queue.push_back(Act.Forward)
		return true
	# try left
	if can_move(Storey.dir_left(dir_old)):
		act_queue.push_back(Act.TurnLeft)
		act_queue.push_back(Act.Forward)
		return true
	# try backward
	if can_move(Storey.dir_opposite(dir_old)):
		act_queue.push_back(Act.TurnLeft)
		act_queue.push_back(Act.TurnLeft)
		act_queue.push_back(Act.Forward)
		return true
	return false

func can_move(dir :Storey.Dir)->bool:
	return storey.can_move(pos_old.x, pos_old.y, dir )

func calc_animate_forward_by_dur(dur :float)->Vector3:
	return Vector3(
		0.5+ lerpf(pos_old.x, pos_new.x, dur),
		storey.storey_h/2.0,
		0.5+ lerpf(pos_old.y, pos_new.y, dur),
	)

func calc_animate_turn_by_dur(dur :float)->float:
	return lerp_angle(Storey.dir2rad(dir_old), Storey.dir2rad(dir_new), dur)

func calc_animate_camera_rotate(dur :float)->float:
	if camera_up:
		return lerp_angle(0, PI, dur)
	else :
		return lerp_angle(PI, 0, dur)

func rotate_camera( rad :float)->void:
	$Camera3D.rotation.z = rad
