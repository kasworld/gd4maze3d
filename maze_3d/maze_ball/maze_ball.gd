extends MeshInstance3D
class_name MazeBall

var velocity :Vector3
func init(co :Color, radius :float) -> MazeBall:
	mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius *2
	mesh.material = MultiMeshShape.make_color_material()
	mesh.material.albedo_color = co
	velocity = Vector3(randf(),randf(),randf()) * 10
	return self
