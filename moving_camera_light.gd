extends Node3D

class_name MovingCameraLight

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


@onready var camera = $Camera3D
@onready var light = $SpotLight3D

var view_dir :ViewDir
var view_dir_dst :ViewDir

func end_action()->void:
	view_dir = view_dir_dst

func start_camera_action(act :Character.Action)->void:
	match act:
		Character.Action.RotateCameraRight:
			view_dir_dst = viewdir_right(view_dir)
		Character.Action.RotateCameraLeft:
			view_dir_dst = viewdir_left(view_dir)

func animate_rotate_camera_by_dur(dur :float)->void:
	rotate_camera(calc_animation_camera_rotate(dur))

func calc_animation_camera_rotate(dur :float)->float:
	return lerp_angle(viewdir2rad(view_dir), viewdir2rad(view_dir_dst), dur)

func snap_cameralight()->void:
	rotation.z = snapped(rotation.z, PI/2)

func rotate_camera( rad :float)->void:
	rotation.z = rad

func light_on(b :bool)->void:
	visible = b

func info_str()->String:
	return "view rotate:%s°" % [
		view_dir*90,
		]
