extends Node3D

class_name MovingCameraLight

enum RollDir {Up,Right,Down,Left}
static func rolldir2str(vd :RollDir)->String:
	return RollDir.keys()[vd]
static func rolldir_left(d:RollDir)->RollDir:
	return (d+1)%4 as RollDir
static func rolldir_right(d:RollDir)->RollDir:
	return (d-1+4)%4 as RollDir
static func rolldir_opposite(d:RollDir)->RollDir:
	return (d+2)%4 as RollDir
static func rolldir2rad(d:RollDir)->float:
	return deg_to_rad(d*90.0)

@onready var camera = $Camera3D
@onready var light = $SpotLight3D

var roll_dir :RollDir
var roll_dir_dst :RollDir

func end_action()->void:
	roll_dir = roll_dir_dst
	snap_90()

func start_action(act :Character.Action)->void:
	match act:
		Character.Action.RollCameraRight:
			roll_dir_dst = rolldir_right(roll_dir)
		Character.Action.RollCameraLeft:
			roll_dir_dst = rolldir_left(roll_dir)

func animate_roll_by_dur(dur :float)->void:
	roll(calc_animation_roll(dur))

func calc_animation_roll(dur :float)->float:
	return lerp_angle(rolldir2rad(roll_dir), rolldir2rad(roll_dir_dst), dur)

func snap_90()->void:
	for i in 3:
		rotation[i] = snapped(rotation[i], PI/2)

func roll( rad :float)->void:
	rotation.z = rad

func info_str()->String:
	return "view roll:%s°, roll:%s" % [
		roll_dir*90, rotation,
		]
