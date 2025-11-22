extends Node3D

class_name MovingCameraLight

static var SelfList :Array[MovingCameraLight]
static var CurrentNumber :int
static func NextCamera() -> void:
	CurrentNumber +=1
	CurrentNumber %= SelfList.size()
	SelfList[CurrentNumber].make_current()
static func GetCurrentCamera() -> MovingCameraLight:
	return SelfList[CurrentNumber]

var number :int
var fov_camera := ClampedFloat.new(75,1,179)
var fov_light := ClampedFloat.new(75,1,179)

func get_camera() -> Camera3D:
	return $Camera3D

func get_light() -> SpotLight3D:
	return $SpotLight3D

func _ready() -> void:
	number = SelfList.size()
	SelfList.append(self)
	fov_camera_reset()
	make_current()

func copy_position_rotation(n :Node3D) -> void:
	position = n.position
	rotation = n.rotation

func _to_string() -> String:
	return "MovingCameraLight%d[fov camera:%s, fov light:%s, rotation:%s]" % [number, fov_camera,fov_light, rotation_degrees ]

func fov_camera_inc() -> void:
	$Camera3D.fov = fov_camera.set_up()

func fov_camera_dec() -> void:
	$Camera3D.fov = fov_camera.set_down()

func fov_camera_reset() -> void:
	$Camera3D.fov = fov_camera.reset()

func fov_light_inc() -> void:
	$SpotLight3D.fov = fov_light.set_up()

func fov_light_dec() -> void:
	$SpotLight3D.fov = fov_light.set_down()

func fov_light_reset() -> void:
	$SpotLight3D.fov = fov_light.reset()

func move_around_y(center :Vector3, radius :float, height :float, spd :float = 2.3) -> void:
	var t := -Time.get_unix_time_from_system() /spd
	position = Vector3( sin(t)*radius, sin(t*1.3)*height, cos(t)*radius ) + center
	look_at(center)

func move_hober_around_z(center :Vector3, radius :float, height :float, spd :float = 2.3) -> void:
	var t := -Time.get_unix_time_from_system() /spd
	position = Vector3(sin(t)*radius, cos(t)*radius, height ) + center
	look_at(center)

func set_center_pos_far(center :Vector3, pos :Vector3, far :float) -> void:
	position = pos
	look_at(center)
	$Camera3D.far = far
	$SpotLight3D.spot_range = far

func make_current() -> void:
	CurrentNumber = number
	CurrentNumber %= SelfList.size()
	$Camera3D.current = true
