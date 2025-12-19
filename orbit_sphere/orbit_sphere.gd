extends Node3D
class_name OrbitSphere

@export var 공전시작각도 :float = 0
@export var 공전속도 :float = 1
@export var 공전축 :Vector3 = Vector3.UP
@export var 궤도반지름 :float = 10
func 궤도설정(반지름 :float, 속도 :float, 축 :Vector3, 시작각도 :float) -> OrbitSphere:
	궤도반지름 = 반지름
	$Orbit.mesh.inner_radius = 궤도반지름*0.999
	$Orbit.mesh.outer_radius = 궤도반지름*1.001
	공전시작각도 = 시작각도
	공전속도 = 속도
	공전축 = 축
	rotation = 공전축
	return self

@export var 자전속도 :float = 1
@export var 자전축 :Vector3 = Vector3.UP
@export var 구반지름 :float = 1
func 구설정(반지름 :float, 속도 :float, 축 :Vector3) -> OrbitSphere:
	구반지름 = 반지름
	자전속도 = 속도
	자전축 = 축
	$Sphere.mesh.radius = 구반지름
	$Sphere.mesh.height = 구반지름*2
	$Sphere/Axis.mesh.top_radius = 구반지름/50
	$Sphere/Axis.mesh.bottom_radius = 구반지름/50
	$Sphere/Axis.mesh.height = 구반지름*3
	$Sphere/Axis.rotation = 자전축
	return self

func 궤도재질설정(mat :Material) -> OrbitSphere:
	$Orbit.mesh.material = mat
	return self

func 궤도색설정(co :Color) -> OrbitSphere:
	$Orbit.mesh.material.albedo_color = co
	return self

func 구색설정(co :Color) -> OrbitSphere:
	$Sphere.mesh.material.albedo_color = co
	return self

func 구축색설정(co :Color) -> OrbitSphere:
	$Sphere/Axis.mesh.material.albedo_color = co
	return self

func 구재질설정(mat :Material) -> OrbitSphere:
	$Sphere.mesh.material = mat
	return self

func show_orbit(b :bool) -> OrbitSphere:
	$Orbit.visible = b
	return self

func show_sphere(b :bool) -> OrbitSphere:
	$Sphere.visible = b
	return self

func show_sphere_axis(b :bool) -> OrbitSphere:
	$Sphere/Axis.visible = b
	return self

func get_sphere() -> MeshInstance3D:
	return $Sphere

## now : Time.get_unix_time_from_system()
func animate_rotate(now :float, delta: float) -> void:
	var t := now *공전속도 + 공전시작각도
	var r := 궤도반지름
	$Sphere.position = Vector3( sin(t)*r, 0, cos(t)*r )
	$Sphere.rotate(자전축, delta*자전속도)

#func _process(delta: float) -> void:
	#var t := Time.get_unix_time_from_system() *공전속도 + 공전시작각도
