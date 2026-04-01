extends Node3D
class_name WireNet

func get_wire_H() -> MultiMeshShape:
	return $WireH
func get_wire_V() -> MultiMeshShape:
	return $WireV

func set_color_H(co :Color) -> void:
	$WireH.set_color_all(co)

func set_color_V(co :Color) -> void:
	$WireV.set_color_all(co)

## for animation
var wire_H_rotation_x :float:
	set(rad):
		for i in h_count:
			$WireH.set_inst_rotation(i, Vector3.RIGHT, rad)

var wire_V_rotation_y :float:
	set(rad):
		for i in v_count:
			$WireV.set_inst_rotation(i, Vector3.UP, rad)

func make_ani_rotate(aniname :String, hv :int, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(
		aniname, self,
		["wire_H_rotation_x", "wire_V_rotation_y"][hv],
		from , to, dur_sec
	)

func make_ani_H_rotate_x(aniname :String, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(aniname, self, "wire_H_rotation_x", from , to, dur_sec)

func start_V_rotate_y(aniname :String, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(aniname, self, "wire_V_rotation_y", from , to, dur_sec)

var h_count :int
var v_count :int

func init(net_size :Vector2, grid_count :Vector2i, wire_width :float, wire_height :float, co :Color, alpha :float = 1.0) -> WireNet:
	init_wire_H(net_size,grid_count,wire_width,wire_height,co,alpha)
	init_wire_V(net_size,grid_count,wire_width,wire_height,co,alpha)
	return self

func init_wire_H(net_size :Vector2, grid_count :Vector2i, wire_width :float, wire_height :float, co :Color, alpha :float = 1.0) -> WireNet:
	h_count = grid_count.y
	var mesh := BoxMesh.new()
	mesh.size = Vector3(net_size.x, wire_width, wire_height)
	mesh.material = MultiMeshShape.MakeMultiMeshColorMaterial(alpha)
	$WireH.init_with_color_mesh(mesh, h_count)
	var pos_shift := -Vector3(net_size.x, net_size.y, 0)/2
	for i in h_count:
		var pos := Vector3(net_size.x/2, net_size.y/(h_count-1)* i, 0) + pos_shift
		var t := Transform3D(Basis(), pos)
		$WireH.multimesh.set_instance_transform(i,t)
	set_color_H(co)
	$WireH.visible = true
	return self


func init_wire_V(net_size :Vector2, grid_count :Vector2i, wire_width :float, wire_height :float, co :Color, alpha :float = 1.0) -> WireNet:
	v_count = grid_count.x
	var mesh := BoxMesh.new()
	mesh.size = Vector3(wire_width, net_size.y, wire_height)
	mesh.material = MultiMeshShape.MakeMultiMeshColorMaterial(alpha)
	$WireV.init_with_color_mesh(mesh, v_count)
	var pos_shift := -Vector3(net_size.x, net_size.y, 0)/2
	for i in v_count:
		var pos := Vector3( net_size.x/(v_count-1)* i, net_size.y/2, 0) + pos_shift
		var t := Transform3D(Basis(), pos)
		$WireV.multimesh.set_instance_transform(i,t)
	set_color_V(co)
	$WireV.visible = true
	return self
