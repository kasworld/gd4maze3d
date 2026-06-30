extends Node3D
class_name PropFocusLines

## x-y focus lines, face z+

func init(radius :float, bar_size :Vector3, align :CSG.Align, step_count :int, rad_range :Array, co :Color, transparent :bool = false) -> PropFocusLines:
	var mat := CSG.MakeColorMaterial(co,transparent)
	var center := CSG.MakeDummyCenter()
	center = CSG.AddFocusLines(center, radius, bar_size, align, step_count, rad_range, mat)
	bake.call_deferred(center)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()
