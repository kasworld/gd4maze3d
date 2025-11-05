extends Node3D

class_name MovingCameraLight

var fov = ClampedFloat.new(75,1,179)

func init() -> void:
	fov_reset()

func copy_position_rotation(n :Node3D) -> void:
	position = n.position
	rotation = n.rotation

func snap_90() -> void:
	for i in 3:
		rotation[i] = snapped(rotation[i], PI/2)

func _to_string() -> String:
	return "MovingCameraLight[FOV:%s, rotation:%s]" % [ fov, rotation_degrees ]

func fov_inc() -> void:
	$Camera3D.fov = fov.set_up()

func fov_dec() -> void:
	$Camera3D.fov = fov.set_down()

func fov_reset() -> void:
	$Camera3D.fov = fov.reset()

func move_camera_around(center :Vector3, radius :float, height :float) -> void:
	var t := -Time.get_unix_time_from_system() /2.3
	position = Vector3( sin(t)*radius, sin(t*1.3)*height, cos(t)*radius ) + center
	look_at(center)

func make_current() -> void:
	$Camera3D.current = true
