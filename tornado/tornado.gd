extends Node3D
class_name Tornado

static func scale_1(_rate :float) -> Vector3:
	return Vector3(1,1,1)

static func scale_cos(rate :float) -> Vector3:
	var s := (cos(rate*PI*2)+3)/4
	return Vector3(s,1,s)

static func shift_zero(_rate :float) -> Vector3:
	return Vector3.ZERO


func init_sample(count :int, radius :float, ring_height :float, co1 :Color, co2 :Color) -> Tornado:
	init_basic(count, radius, ring_height)
	set_transform_all(scale_1, shift_zero)
	set_color_all(co1,co2)
	return self

func init_basic(count :int, radius :float, ring_height :float) -> Tornado:
	_init_rings($RingsOut, count, radius, ring_height, false)
	_init_rings($RingsIn, count, radius, ring_height, true)
	return self

func _init_rings(rings :MultiMeshShape, count :int, radius :float, ring_height :float, flip_faces :bool) -> void:
	var ring_mesh := CylinderMesh.new()
	ring_mesh.material = MultiMeshShape.make_color_material(0.9)
	ring_mesh.cap_bottom = false
	ring_mesh.cap_top = false
	ring_mesh.top_radius = radius
	ring_mesh.bottom_radius = radius
	ring_mesh.height = ring_height
	ring_mesh.flip_faces = flip_faces
	rings.init_with_color_mesh(ring_mesh, count, false)

func set_transform_all(scale_fn :Callable,shift_fn :Callable) -> Tornado:
	var count :int = $RingsOut.multimesh.visible_instance_count
	var ring_height :float = $RingsOut.multimesh.mesh.height
	for i in count:
		var rate := float(i)/float(count-1)
		var scaled_size :Vector3 = scale_fn.call(rate)
		var ring_pos := Vector3(0, i*ring_height, 0)
		var t = Transform3D(Basis(), ring_pos + shift_fn.call(rate))
		t = t.scaled_local(scaled_size)
		#t = t.rotated_local(Vector3.RIGHT, PI/2)
		$RingsOut.multimesh.set_instance_transform(i, t)
		$RingsIn.multimesh.set_instance_transform(i, t)
	return self

func set_color_all(co1 :Color, co2 :Color) -> Tornado:
	var count :int = $RingsOut.multimesh.visible_instance_count
	for i in count:
		var rate := float(i)/float(count-1)
		var co := co1.lerp(co2, rate)
		$RingsOut.multimesh.set_instance_color(i,co)
		$RingsIn.multimesh.set_instance_color(i,co)
	return self

func set_inst_color(i:int, co :Color) -> void:
	$RingsOut.multimesh.set_instance_color(i,co)
	$RingsIn.multimesh.set_instance_color(i,co)
