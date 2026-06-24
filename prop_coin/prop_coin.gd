extends Node3D
class_name PropCoin

## face Z+
func init(radius :float, thick :float, co :Color, side :int = 64) -> PropCoin:
	var wall := MakeCoinMesh(radius, thick, MakeColorMaterial(co), side)
	bake.call_deferred(wall)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()

## face Z+
static func MakeCoinMesh(raidus :float, thick :float, mat :StandardMaterial3D, side :int = 64) -> CSGShape3D:
	var csg_main := CSGCylinder3D.new()
	csg_main.radius = raidus
	csg_main.height = thick
	csg_main.sides = side
	csg_main.material = mat

	var csg_front := CSGCylinder3D.new()
	csg_front.radius = raidus * 0.9
	csg_front.height = thick /2
	csg_front.sides = side
	csg_front.material = mat
	csg_front.position.y = thick /2
	csg_front.operation = CSGShape3D.OPERATION_SUBTRACTION
	csg_main.add_child(csg_front)

	var csg_back := CSGCylinder3D.new()
	csg_back.radius = raidus * 0.9
	csg_back.height = thick /2
	csg_back.sides = side
	csg_back.material = mat
	csg_back.position.y = -thick /2
	csg_back.operation = CSGShape3D.OPERATION_SUBTRACTION
	csg_main.add_child(csg_back)


	csg_main.rotate_x(PI/2)
	return csg_main

static func MakeColorMaterial(co :Color, transparent :bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = co
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent else BaseMaterial3D.TRANSPARENCY_DISABLED
	return material
