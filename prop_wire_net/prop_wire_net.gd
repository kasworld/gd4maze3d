extends Node3D
class_name PropWireNet

## x-y wire net, face z+

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

## add H wire
static func AddHWire(center :CSGShape3D, net_size :Vector2, grid_count :Vector2i, wire_width :float, wire_height :float, mat :StandardMaterial3D, rot := Vector3.ZERO) -> CSGShape3D:
	# make H wire
	var h_wire_size := Vector3(net_size.x,wire_width, wire_height)
	var unit_y := net_size.y/(grid_count.y-1) if grid_count.y > 1 else 0.0
	for i in grid_count.y:
		var pos := Vector3(0, -net_size.y/2 + unit_y *i, 0)
		var wire := make_csg_box(h_wire_size, mat)
		wire.operation = CSGShape3D.OPERATION_UNION
		wire.position = pos
		wire.rotation = rot
		center.add_child(wire)
	return center

## add V wire
static func AddVWire(center :CSGShape3D, net_size :Vector2, grid_count :Vector2i, wire_width :float, wire_height :float, mat :StandardMaterial3D, rot := Vector3.ZERO) -> CSGShape3D:
	# make V wire
	var v_wire_size := Vector3(wire_width, net_size.y, wire_height)
	var unit_x := net_size.x/(grid_count.x-1) if grid_count.x > 1 else 0.0
	for i in grid_count.x:
		var pos := Vector3(-net_size.x/2 + unit_x *i, 0, 0)
		var wire := make_csg_box(v_wire_size, mat)
		wire.operation = CSGShape3D.OPERATION_UNION
		wire.position = pos
		wire.rotation = rot
		center.add_child(wire)
	return center

func init(net_size :Vector2, grid_count :Vector2i, wire_width :float, wire_height :float, co :Color, transparent :bool = false) -> PropWireNet:
	var mat := MakeColorMaterial(co,transparent)
	var center := MakeDummyCenter()
	center = AddHWire(center, net_size,grid_count,wire_width, wire_height, mat)
	center = AddVWire(center, net_size,grid_count,wire_width, wire_height, mat)
	bake.call_deferred(center)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()
