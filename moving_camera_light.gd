extends Node3D

class_name MovingCameraLight

@onready var camera = $Camera3D
@onready var light = $SpotLight3D

func snap_cameralight()->void:
	rotation.z = snapped(rotation.z, PI/2)

func rotate_camera( rad :float)->void:
	rotation.z = rad

func light_on(b :bool)->void:
	visible = b
