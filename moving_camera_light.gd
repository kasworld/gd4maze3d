extends Node3D

class_name MovingCameraLight

var fov = ClampedFloat.new(75,1,179)

func init()->void:
	fov_reset()

func copy_position_rotation(n :Node3D)->void:
	position = n.position
	rotation = n.rotation

func info_str()->String:
	return "FOV:%s" % [ fov ]

func fov_inc()->void:
	$Camera3D.fov = fov.set_up()

func fov_dec()->void:
	$Camera3D.fov = fov.set_down()

func fov_reset()->void:
	$Camera3D.fov = fov.reset()
