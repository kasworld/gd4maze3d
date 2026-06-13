extends Node3D
class_name ArchDoor

## face Z+ wall with door

func init(size :Vector3, co :Color) -> ArchDoor:
	var wall := MakeArchDoorMesh(size,co)
	bake.call_deferred(wall)
	return self

func bake(wall_mesh :CSGShape3D) -> void:
	$MeshInstance3D.mesh = wall_mesh.bake_static_mesh()

static func MakeArchDoorMesh(size :Vector3, co :Color) -> CSGShape3D:
	var wall := CSGBox3D.new()
	wall.size = size
	wall.material = MakeColorMaterial(co)
	var door_low := CSGBox3D.new()
	door_low.size = Vector3(size.x/2,size.y/2,size.z)
	door_low.material = MakeColorMaterial(co)
	door_low.operation = CSGShape3D.OPERATION_SUBTRACTION
	door_low.position.y = -size.y * 0.25
	var hole := CSGCylinder3D.new()
	hole.material = MakeColorMaterial(co)
	hole.radius = size.x/4
	hole.height = size.z *2
	hole.sides = 64
	hole.rotate_x(PI/2)
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	wall.add_child(door_low)
	wall.add_child(hole)
	return wall

static func MakeColorMaterial(co :Color, transparent :bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = co
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent else BaseMaterial3D.TRANSPARENCY_DISABLED
	return material
