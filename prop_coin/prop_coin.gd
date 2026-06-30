extends Node3D
class_name PropCoin

const RRate := 0.95

## face Y+
func init(radius :float, thick :float, co :Color, side :int = 64, front :String ="", back :String="") -> PropCoin:
	var center := CSG.MakeDummyCenter()
	center = CSG.AddCoinCSG(center, radius, thick, CSG.MakeColorMaterial(co), side)
	center = CSG.SubCoinCSG(center, radius*RRate, thick/2, CSG.MakeColorMaterial(co), side)
	center = CSG.AddTextCSG(center, radius, thick/2, CSG.MakeColorMaterial(co), front, back)
	bake.call_deferred(center)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()
