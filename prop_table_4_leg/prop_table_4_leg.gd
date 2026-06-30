extends Node3D
class_name PropTable4Leg

## X-Z table, ie table top face Y axis
var aabb :AABB

func init(total_size :Vector3, top_thick :float, leg_x :float, leg_z :float, co_top :Color, co_leg :Color) -> PropTable4Leg:
	aabb = AABB(-total_size/2, total_size)
	var center := CSG.MakeDummyCenter()
	center = CSG.AddTableTop(center, total_size, top_thick, CSG.MakeColorMaterial(co_top))
	center = CSG.AddTableLeg(center,total_size,top_thick, leg_x,leg_z, CSG.MakeColorMaterial(co_leg))
	bake.call_deferred(center)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()
