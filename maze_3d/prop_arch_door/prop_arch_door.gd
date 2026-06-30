extends Node3D
class_name PropArchDoor

## face Z+ wall with door
func init(size :Vector3, co :Color) -> PropArchDoor:
	var wall := MakeArchDoorMeshH(size,CSG.MakeColorMaterial(co,false))
	bake.call_deferred(wall)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()

## face Z+ wall with door
static func MakeArchDoorMeshH(size :Vector3, mat :StandardMaterial3D) -> CSGShape3D:
	var wall := CSG.MakeCSGBox(size,mat)
	var door_low := CSG.MakeCSGBox(Vector3(size.x/2,size.y/2,size.z),mat)
	door_low.operation = CSGShape3D.OPERATION_SUBTRACTION
	door_low.position.y = -size.y * 0.25
	var hole := CSG.MakeCSGCylinder(size.x/4,size.z *2,mat,64)
	hole.rotate_x(PI/2)
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	wall.add_child(door_low)
	wall.add_child(hole)
	return wall

## face X+ wall with door
static func MakeArchDoorMeshV(size :Vector3, mat :StandardMaterial3D) -> CSGShape3D:
	var wall := CSG.MakeCSGBox(size,mat)
	var door_low := CSG.MakeCSGBox(Vector3(size.x,size.y/2,size.z/2),mat)
	door_low.operation = CSGShape3D.OPERATION_SUBTRACTION
	door_low.position.y = -size.y * 0.25
	var hole := CSG.MakeCSGCylinder(size.z/4,size.x *2,mat,64)
	hole.rotate_z(PI/2)
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	wall.add_child(door_low)
	wall.add_child(hole)
	return wall
