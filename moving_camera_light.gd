extends Node3D

class_name MovingCameraLight

func copy_position_rotation(n :Node3D)->void:
	position = n.position
	rotation = n.rotation
