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
	var aabb := calc_aabb(top_size, leg_size)
	var top := make_box(top_size,mat_top)
	var legs := []
	for i in 4:
		var leg := make_box(leg_size,mat_leg)
		leg.operation = CSGShape3D.OPERATION_UNION
		legs.append(leg)
		top.add_child(leg)
	var pos_adj := -Vector3(0,leg_size.y/2,0)
	legs[0].position = Vector3(CalcAxisAlignInner(aabb, leg_size, 0, -1), CalcAxisAlignInner(aabb, leg_size, 1, -1), CalcAxisAlignInner(aabb, leg_size, 2, -1)) + pos_adj
	legs[1].position = Vector3(CalcAxisAlignInner(aabb, leg_size, 0, -1), CalcAxisAlignInner(aabb, leg_size, 1, -1), CalcAxisAlignInner(aabb, leg_size, 2, 1)) + pos_adj
	legs[2].position = Vector3(CalcAxisAlignInner(aabb, leg_size, 0, 1), CalcAxisAlignInner(aabb, leg_size, 1, -1), CalcAxisAlignInner(aabb, leg_size, 2, 1)) + pos_adj
	legs[3].position = Vector3(CalcAxisAlignInner(aabb, leg_size, 0, 1), CalcAxisAlignInner(aabb, leg_size, 1, -1), CalcAxisAlignInner(aabb, leg_size, 2, -1)) + pos_adj
	return top

static func MakeColorMaterial(co :Color, transparent :bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = co
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent else BaseMaterial3D.TRANSPARENCY_DISABLED
	return material

## axis : x:0, y:1, z:2, axis_sign : 1,0,-1
static func CalcAxisAlignInner(out_aabb :AABB, inner_box_size :Vector3, axis :int, dir :int) -> float:
	match dir:
		-1: # align -
			return out_aabb.position[axis] + inner_box_size[axis]/2
		1: # align +
			return out_aabb.end[axis] - inner_box_size[axis]/2
		_: # align center
			return out_aabb.get_center()[axis]
