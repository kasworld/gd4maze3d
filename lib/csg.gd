class_name CSG

## add H wire
static func AddHWire(center :CSGShape3D, net_size :Vector2, grid_count :Vector2i, wire_width :float, wire_height :float, mat :StandardMaterial3D, rot := Vector3.ZERO) -> CSGShape3D:
	# make H wire
	var h_wire_size := Vector3(net_size.x,wire_width, wire_height)
	var unit_y := net_size.y/(grid_count.y-1) if grid_count.y > 1 else 0.0
	for i in grid_count.y:
		var pos := Vector3(0, -net_size.y/2 + unit_y *i, 0)
		var wire := MakeCSGBox(h_wire_size, mat)
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
		var wire := MakeCSGBox(v_wire_size, mat)
		wire.operation = CSGShape3D.OPERATION_UNION
		wire.position = pos
		wire.rotation = rot
		center.add_child(wire)
	return center

enum Align {In,Mid,Out}

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
		var wire := MakeCSGBox(bar_size, mat)
		wire.operation = CSGShape3D.OPERATION_UNION
		wire.rotate_z(rad)
		wire.position = bar_position
		center.add_child(wire)
	return center

static func AddTableTop(center :CSGShape3D, total_size :Vector3, top_thick :float, mat_top :StandardMaterial3D) -> CSGShape3D:
	var top := MakeCSGBox(Vector3(total_size.x,top_thick,total_size.z),mat_top)
	top.position = Vector3(0,total_size.y/2-top_thick/2,0)
	top.operation = CSGShape3D.OPERATION_UNION
	center.add_child(top)
	return center

static func AddTableLeg(center :CSGShape3D, total_size :Vector3, top_thick :float, leg_x :float, leg_z :float, mat_leg :StandardMaterial3D) -> CSGShape3D:
	var leg_size := Vector3(leg_x, total_size.y-top_thick, leg_z)
	var y := -top_thick/2
	var x :=  total_size.x/2 - leg_x/2
	var z :=  total_size.z/2 - leg_z/2
	for pos in [Vector3(x, y, z), Vector3(x, y,-z), Vector3(-x, y, z), Vector3(-x, y,-z)]:
		var leg := MakeCSGBox(leg_size,mat_leg)
		leg.operation = CSGShape3D.OPERATION_UNION
		leg.position = pos
		center.add_child(leg)
	return center


## face Y+
static func AddCoinCSG(center :CSGShape3D, raidus :float, thick :float, mat :StandardMaterial3D, side :int = 64) -> CSGShape3D:
	var csg_main := MakeCSGCylinder(raidus, thick, mat, side)
	center.add_child(csg_main)
	#csg_main.rotate_x(PI/2)
	return center

## face Y+
static func SubCoinCSG(center :CSGShape3D, raidus :float, thick :float, mat :StandardMaterial3D, side :int = 64) -> CSGShape3D:
	var csg_front := MakeCSGCylinder(raidus, thick, mat, side)
	csg_front.position.y = thick
	csg_front.operation = CSGShape3D.OPERATION_SUBTRACTION
	center.add_child(csg_front)
	var csg_back := MakeCSGCylinder(raidus, thick, mat, side)
	csg_back.position.y = -thick
	csg_back.operation = CSGShape3D.OPERATION_SUBTRACTION
	center.add_child(csg_back)
	return center

## face Y+
static func AddTextCSG(center :CSGShape3D, raidus :float, thick :float, mat :StandardMaterial3D, front :String ="", back :String="") -> CSGShape3D:
	if not front.is_empty():
		var front_text := CSGMesh3D.new()
		front_text.mesh = MakeTextMesh(raidus*1.5/back.length(), thick, mat, front)
		front_text.material = mat
		front_text.operation = CSGShape3D.OPERATION_UNION
		front_text.rotate_x(-PI/2)
		front_text.position.y = thick/2
		center.add_child(front_text)
	if not back.is_empty():
		var back_text := CSGMesh3D.new()
		back_text.mesh = MakeTextMesh(raidus*1.5/back.length(), thick, mat, back)
		back_text.material = mat
		back_text.operation = CSGShape3D.OPERATION_UNION
		back_text.rotate_x(PI/2)
		back_text.position.y = -thick/2
		center.add_child(back_text)
	return center

static var font := preload("res://font/HakgyoansimBareondotumR.ttf")
static func MakeTextMesh(fsize :float, fdepth :float, mat :Material, text :String) -> Mesh:
	var mesh := TextMesh.new()
	mesh.font = font
	mesh.depth = fdepth
	mesh.pixel_size = fsize / 16
	mesh.text = text
	mesh.material = mat
	return mesh

static func MakeCSGCylinder(raidus :float, thick :float, mat :StandardMaterial3D, side :int = 64) -> CSGShape3D:
	var csg := CSGCylinder3D.new()
	csg.radius = raidus
	csg.height = thick
	csg.sides = side
	csg.material = mat
	return csg

static func MakeCSGBox(box_size :Vector3, box_mat :StandardMaterial3D) -> CSGShape3D:
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
	var center := MakeCSGBox(Vector3.ONE/1000, MakeColorMaterial(Color(0,0,0,0), true) )
	return center
