extends Node3D
class_name PropWireNet

## x-y wire net, face z+

func init(net_size :Vector2, grid_count :Vector2i, wire_width :float, wire_height :float, co :Color, transparent :bool = false) -> PropWireNet:
	var mat := CSG.MakeColorMaterial(co,transparent)
	var center := CSG.MakeDummyCenter()
	center = CSG.AddHWire(center, net_size,grid_count,wire_width, wire_height, mat)
	center = CSG.AddVWire(center, net_size,grid_count,wire_width, wire_height, mat)
	bake.call_deferred(center)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()
