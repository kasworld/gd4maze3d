extends Node3D
class_name Capsule

func init(h :float, r :float, co:Color) -> Capsule:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = co
	var mesh = CapsuleMesh.new()
	mesh.height = h
	mesh.radius = r
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.rotate_x(PI/2)
	sp.rotation.x = randf_range(0, PI)
	sp.rotation.y = randf_range(0, 2*PI)
	add_child(sp)
	return self
