extends Node3D
class_name Table4Leg

## X-Z table, ie table top face Y axis

static func make_box(box_size :Vector3, box_co :Color) -> MeshInstance3D:
	var box := MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	box.mesh.size = box_size
	box.mesh.material = StandardMaterial3D.new()
	box.mesh.material.albedo_color = box_co
	return box

## center ZERO
var boundary :AABB

var top :MeshInstance3D
var legs :Array[MeshInstance3D]

func init(top_size :Vector3, leg_size :Vector3, co_top :Color, co_leg :Color) -> Table4Leg:
	var total_size := top_size
	total_size.y += leg_size.y
	boundary = AABB(-total_size/2,total_size)
	top = make_box(top_size,co_top)
	top.position.y = boundary.size.y/2 - top_size.y/2
	add_child(top)
	for i in 4:
		var leg := make_box(leg_size,co_leg)
		legs.append(leg)
		add_child(leg)
	legs[0].position = Vector3(CalcAxisAlignInner(boundary, leg_size, 0, -1), CalcAxisAlignInner(boundary, leg_size, 1, -1), CalcAxisAlignInner(boundary, leg_size, 2, -1),)
	legs[1].position = Vector3(CalcAxisAlignInner(boundary, leg_size, 0, -1), CalcAxisAlignInner(boundary, leg_size, 1, -1), CalcAxisAlignInner(boundary, leg_size, 2, 1),)
	legs[2].position = Vector3(CalcAxisAlignInner(boundary, leg_size, 0, 1), CalcAxisAlignInner(boundary, leg_size, 1, -1), CalcAxisAlignInner(boundary, leg_size, 2, 1),)
	legs[3].position = Vector3(CalcAxisAlignInner(boundary, leg_size, 0, 1), CalcAxisAlignInner(boundary, leg_size, 1, -1), CalcAxisAlignInner(boundary, leg_size, 2, -1),)
	return self

## axis : x:0, y:1, z:2, axis_sign : 1,0,-1
static func CalcAxisAlignInner(aabb :AABB, inner_box_size :Vector3, axis :int, dir :int) -> float:
	match dir:
		-1: # align -
			return aabb.position[axis] + inner_box_size[axis]/2
		1: # align +
			return aabb.end[axis] - inner_box_size[axis]/2
		_: # align center
			return aabb.get_center()[axis]
