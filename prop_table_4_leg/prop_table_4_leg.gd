extends Node3D
class_name PropTable4Leg

## X-Z table, ie table top face Y axis

var aabb :AABB
static func calc_aabb(top_size :Vector3, leg_size :Vector3) -> AABB:
	var total_size := top_size
	total_size.y += leg_size.y
	return AABB(-total_size/2,total_size)

func init(top_size :Vector3, leg_size :Vector3, co_top :Color, co_leg :Color) -> PropTable4Leg:
	aabb = calc_aabb(top_size, leg_size)
	$MeshInstance3D.position = Vector3(0,leg_size.y/2-top_size.y/2,0)
	var wall := MakeTableMesh(top_size, leg_size, MakeColorMaterial(co_top), MakeColorMaterial(co_leg))
	bake.call_deferred(wall)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()

static func make_box(box_size :Vector3, box_mat :StandardMaterial3D) -> CSGShape3D:
	var box := CSGBox3D.new()
	box.size = box_size
	box.material = box_mat
	return box

static func MakeTableMesh(top_size :Vector3, leg_size :Vector3, mat_top :StandardMaterial3D, mat_leg :StandardMaterial3D) -> CSGShape3D:
	var top := make_box(top_size,mat_top)
	var y := -leg_size.y/2 - top_size.y/2
	var x :=  top_size.x/2 - leg_size.x/2
	var z :=  top_size.z/2 - leg_size.z/2
	for pos in [Vector3(x, y, z), Vector3(x, y,-z), Vector3(-x, y, z), Vector3(-x, y,-z)]:
		var leg := make_box(leg_size,mat_leg)
		leg.operation = CSGShape3D.OPERATION_UNION
		leg.position = pos
		top.add_child(leg)
	return top

static func MakeColorMaterial(co :Color, transparent :bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = co
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent else BaseMaterial3D.TRANSPARENCY_DISABLED
	return material
