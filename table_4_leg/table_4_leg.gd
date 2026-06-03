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
	legs[0].position = Vector3(boundary.size.x/2-leg_size.x/2, -top_size.y/2, boundary.size.z/2-leg_size.z/2, )
	legs[1].position = Vector3(boundary.size.x/2-leg_size.x/2, -top_size.y/2, -boundary.size.z/2+leg_size.z/2, )
	legs[2].position = Vector3(-boundary.size.x/2+leg_size.x/2, -top_size.y/2, -boundary.size.z/2+leg_size.z/2, )
	legs[3].position = Vector3(-boundary.size.x/2+leg_size.x/2, -top_size.y/2, boundary.size.z/2-leg_size.z/2, )
	return self
