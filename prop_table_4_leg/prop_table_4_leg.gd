extends Node3D
class_name PropTable4Leg

## X-Z table, ie table top face Y axis
var aabb :AABB

func init(total_size :Vector3, top_thick :float, leg_x :float, leg_z :float, co_top :Color, co_leg :Color) -> PropTable4Leg:
	aabb = AABB(-total_size/2, total_size)
	var center := MakeDummyCenter()
	center = AddTableTop(center, total_size, top_thick, MakeColorMaterial(co_top))
	center = AddTableLeg(center,total_size,top_thick, leg_x,leg_z, MakeColorMaterial(co_leg))
	bake.call_deferred(center)
	return self

static func AddTableTop(center :CSGShape3D, total_size :Vector3, top_thick :float, mat_top :StandardMaterial3D) -> CSGShape3D:
	var top := MakeCSGBox(Vector3(total_size.x,top_thick,total_size.z),mat_top)
	top.position = Vector3(0,total_size.y/2-top_thick/2,0)
	top.operation = CSGShape3D.OPERATION_UNION
	center.add_child(top)
	return center

static func AddTableLeg(center :CSGShape3D, total_size :Vector3, top_thick :float, leg_x :float, leg_z :float, mat_leg :StandardMaterial3D) -> CSGShape3D:
	var leg_size := Vector3(leg_x, total_size.y-top_thick, leg_z)
	var y := -top_thick/2
	var x :=  total_size.x/2 - leg_x/2
	var z :=  total_size.z/2 - leg_z/2
	for pos in [Vector3(x, y, z), Vector3(x, y,-z), Vector3(-x, y, z), Vector3(-x, y,-z)]:
		var leg := MakeCSGBox(leg_size,mat_leg)
		leg.operation = CSGShape3D.OPERATION_UNION
		leg.position = pos
		center.add_child(leg)
	return center

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()

static func MakeCSGBox(box_size :Vector3, box_mat :StandardMaterial3D) -> CSGShape3D:
	var box := CSGBox3D.new()
	box.size = box_size
	box.material = box_mat
	return box

static func MakeColorMaterial(co :Color, transparent :bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = co
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent else BaseMaterial3D.TRANSPARENCY_DISABLED
	return material

## make dummy center
static func MakeDummyCenter() -> CSGShape3D:
	var center := MakeCSGBox(Vector3.ONE/1000, MakeColorMaterial(Color(0,0,0,0), true) )
	return center
