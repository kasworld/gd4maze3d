extends Node3D
class_name ValveHandle

var 팔길이 :float
var 높이 :float
var mat : StandardMaterial3D
func init(팔길이a :float, 높이a :float, 팔개수 :int = 4, 색 :Color = Color.GOLD) -> ValveHandle:
	팔길이 = 팔길이a
	높이 = 높이a

	mat = StandardMaterial3D.new()
	mat.albedo_color = 색

	$"중앙기둥".mesh.height = 높이
	$"중앙기둥".mesh.bottom_radius = 팔길이*0.1
	$"중앙기둥".mesh.top_radius = 팔길이*0.1
	$"중앙기둥".mesh.material = mat
	$"중앙기둥".position.y = 높이/2

	var sp = new_ball()
	add_child(sp)
	sp.position = Vector3(0, 높이 , 0)

	var rd = 2*PI/팔개수
	for i in 팔개수:
		var mesh := CylinderMesh.new()
		mesh.height = 팔길이
		mesh.bottom_radius = 팔길이*0.1
		mesh.top_radius = 팔길이*0.1
		mesh.material = mat
		sp = MeshInstance3D.new()
		sp.mesh = mesh
		sp.position = Vector3(sin(rd*i)*팔길이/2, 높이 , cos(rd*i)*팔길이/2)
		sp.rotate_x(PI/2)
		sp.rotate_y(rd*i)
		add_child(sp)

	for i in 팔개수:
		sp = new_ball()
		add_child(sp)
		sp.position = Vector3(sin(rd*i)*팔길이, 높이 , cos(rd*i)*팔길이)

	return self

func new_ball() -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 팔길이*0.2
	mesh.height = 팔길이*0.4
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	return sp

func 색바꾸기(색 :Color = Color.GOLD) -> void:
	mat.albedo_color = 색
