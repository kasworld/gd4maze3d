extends Node3D
class_name PropFocusLines

## x-y focus lines, face z+

enum Align {In,Mid,Out}

static func make_csg_box(box_size :Vector3, box_mat :StandardMaterial3D) -> CSGShape3D:
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
	var center := make_csg_box(Vector3.ONE/1000, MakeColorMaterial(Color(0,0,0,0), true) )
	return center

## add x-y focus lines, face z+
## rad_range : [start,end]
## bar_size.x == bar len
static func AddFocusLines(center :CSGShape3D, radius :float, bar_size :Vector3, align :Align, step_count :int, rad_range :Array, mat :StandardMaterial3D) -> CSGShape3D:
	var bar_position := Vector3.ZERO
	var rad_step :float = float(rad_range[1] - rad_range[0]) / step_count
	for i in step_count+1:
		var rad :float = rad_range[0] + rad_step * i
		var bar_center := Vector3(cos(rad)*radius, sin(rad)*radius,  0)
		match align:
			Align.In :
				bar_position = bar_center*(1 - bar_size.x/radius/2)
			Align.Mid :
				bar_position = bar_center
			Align.Out :
				bar_position = bar_center*(1 + bar_size.x/radius/2)
		var wire := make_csg_box(bar_size, mat)
		wire.operation = CSGShape3D.OPERATION_UNION
		wire.rotate_z(rad)
		wire.position = bar_position
		center.add_child(wire)
	return center

func init(radius :float, bar_size :Vector3, align :Align, step_count :int, rad_range :Array, co :Color, transparent :bool = false) -> PropFocusLines:
	var mat := MakeColorMaterial(co,transparent)
	var center := MakeDummyCenter()
	center = AddFocusLines(center, radius, bar_size, align, step_count, rad_range, mat)
	bake.call_deferred(center)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()
