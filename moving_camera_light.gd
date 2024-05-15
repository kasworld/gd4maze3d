extends Node3D

class_name MovingCameraLight

func copy_position_rotation(n :Node3D)->void:
	position = n.position
	rotation = n.rotation

func info_str()->String:
	return "FOV:%.1f" % [ $Camera3D.fov ]

func fov_inc()->void:
	$Camera3D.fov = clampf($Camera3D.fov *1.1 , 1, 179)

func fov_dec()->void:
	$Camera3D.fov = clampf($Camera3D.fov /1.1 , 1, 179)

func fov_reset()->void:
	$Camera3D.fov = 75
