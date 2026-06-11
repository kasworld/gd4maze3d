extends Node3D
class_name ArchDoor

## face Z+ wall with door

var wall :CSGBox3D
func init(size :Vector3, co :Color) -> ArchDoor:
	wall = CSGBox3D.new()
	wall.size = size
	wall.material = color_material(co)
	var door_low := CSGBox3D.new()
	door_low.size = Vector3(size.x/2,size.y/2,size.z)
	door_low.material = color_material(co)
	door_low.operation = CSGShape3D.OPERATION_SUBTRACTION
	door_low.position.y = -size.y * 0.25
	var hole := CSGCylinder3D.new()
	hole.material = color_material(co)
	hole.radius = size.x/4
	hole.height = size.z *2
	hole.sides = 64
	hole.rotate_x(PI/2)
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION

	wall.add_child(door_low)
	wall.add_child(hole)
	#add_child(wall)
	bake.call_deferred()
	return self

func bake() -> void:
	$MeshInstance3D.mesh = wall.bake_static_mesh()

func color_material(co :Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = co
	return material
