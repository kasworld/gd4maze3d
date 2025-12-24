extends Node3D
class_name MovingCameraLight

static var SelfList :Array[MovingCameraLight]
static var CurrentIndex :int
static func NextCamera() -> void:
	CurrentIndex +=1
	CurrentIndex %= SelfList.size()
	SelfList[CurrentIndex].make_current()
static func GetCurrentCamera() -> MovingCameraLight:
	return SelfList[CurrentIndex]
static func FindCameraIndexByID(idx :int) -> int:
	for i in SelfList.size():
		if SelfList[i].id == idx:
			return i
	assert(false)
	return -1

var id :int # not serial if some deleted
var fov_camera := ClampedFloat.new(75,1,179)
var fov_light := ClampedFloat.new(75,1,179)

func get_camera() -> Camera3D:
	return $Camera3D

func get_light() -> SpotLight3D:
	return $SpotLight3D

func _ready() -> void:
	if SelfList.size() > 0:
		id = SelfList[-1].id+1
	else :
		id = 0
	SelfList.append(self)
	fov_camera_reset()
	make_current()

func copy_position_rotation(n :Node3D) -> void:
	position = n.position
	rotation = n.rotation

func _to_string() -> String:
	return "MovingCameraLight%d[fov camera:%s, fov light:%s, rotation:%s, position:%s]" % [
		id, fov_camera,fov_light, rotation_degrees, position ]

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

func move_wave_around_y(t :float,  center :Vector3, radius :float, height :float) -> void:
	position = Vector3( sin(t)*radius, sin(t*1.3)*height, cos(t)*radius ) + center
	look_at(center)

func move_hober_around_x(t :float,  center :Vector3, radius :float, height :float) -> void:
	position = Vector3( height, sin(t)*radius, cos(t)*radius ) + center
	look_at(center)

func move_hober_around_y(t :float,  center :Vector3, radius :float, height :float) -> void:
	position = Vector3( sin(t)*radius, height, cos(t)*radius ) + center
	look_at(center)

func move_hober_around_z(t :float, center :Vector3, radius :float, height :float) -> void:
	position = Vector3( sin(t)*radius, cos(t)*radius, height ) + center
	look_at(center)

func bounce_within_aabb(delta :float, bounce_area :AABB, velocity :Vector3, center :Vector3, radius :float) -> Vector3:
	position += velocity * delta
	var bn = Bounce.v3f(position, bounce_area, radius)
	for i in 3:
		# change vel on bounce
		if bn.bounced[i] != 0 :
			velocity[i] = -bn.bounced[i] * abs(velocity[i])
	position = bn.pos
	look_at(center)
	return velocity

func set_center_pos_far(center :Vector3, pos :Vector3, far :float) -> void:
	position = pos
	#look_at(center)
	look_at_from_position(position, center)
	$Camera3D.far = far
	$SpotLight3D.spot_range = far

func make_current() -> void:
	var idx := FindCameraIndexByID(id)
	CurrentIndex = idx
	CurrentIndex %= SelfList.size()
	$Camera3D.current = true

func is_current_camera() -> bool:
	return $Camera3D.current
