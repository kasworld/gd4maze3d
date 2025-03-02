extends Node3D
class_name Donut

func init(r1 :float, r2 :float, co:Color) -> Donut:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = co
	var mesh = TorusMesh.new()
	mesh.outer_radius = r1
	mesh.inner_radius = r2
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.rotate_x(PI/2)
	sp.rotation.x = randf_range(0, PI)
	sp.rotation.y = randf_range(0, 2*PI)
	add_child(sp)
	return self
