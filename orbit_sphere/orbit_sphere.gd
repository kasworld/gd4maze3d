extends Node3D
class_name OrbitSphere

var 공전시작각도 :float
var 공전속도 :float
var 공전축 :Vector3
var 공전축기울기 :float
var 궤도반지름 :float
func 궤도설정(반지름 :float, 속도 :float, 축 :Vector3, 기울기 :float, 시작각도 :float) -> OrbitSphere:
	궤도반지름 = 반지름
	$Orbit.mesh.inner_radius = 궤도반지름*0.999
	$Orbit.mesh.outer_radius = 궤도반지름*1.001
	공전시작각도 = 시작각도
	공전속도 = 속도
	공전축 = 축
	공전축기울기 = 기울기
	rotation = Vector3.UP.rotated(공전축, 공전축기울기)
	return self

func 궤도재질설정(mat :Material) -> OrbitSphere:
	$Orbit.mesh.material = mat
	return self

func 구재질설정(mat :Material) -> OrbitSphere:
	$Sphere.mesh.material = mat
	return self

var 자전속도 :float
var 자전축 :Vector3
var 자전축기울기 :float
var 구반지름 :float
func 구설정(반지름 :float, 속도 :float, 축 :Vector3, 기울기 :float) -> OrbitSphere:
	구반지름 = 반지름
	$Sphere.mesh.radius = 구반지름
	$Sphere.mesh.height = 구반지름*2
	자전속도 = 속도
	자전축 = 축
	자전축기울기 = 기울기
	return self

func _process(delta: float) -> void:
	var t = Time.get_unix_time_from_system() /공전속도 + 공전시작각도
	var r = 궤도반지름
	$Sphere.position = Vector3( sin(t)*r, 0, cos(t)*r )
	$Sphere.rotate(자전축, delta*자전속도)
