extends MultiMeshInstance3D
class_name MultiMeshShape

# example usage

func init_집중선(r :float, start:float, end:float, depth :float, count :int, co :Color) -> MultiMeshShape:
	var 구분선 := BoxMesh.new()
	var 길이 := r*(end-start)
	구분선.size = Vector3(길이, depth/10, depth )
	var cell각도 := 2.0*PI / count
	var radius := r-길이/2
	init_with_color(구분선, Color.WHITE, count)
	for i in count:
		var rad := cell각도 *i + cell각도/2
		set_inst_rotation(i, Vector3.BACK, rad)
		set_inst_pos(i, Vector3(cos(rad) *radius,sin(rad) *radius, 0) )
		set_inst_color(i, co)
	return self

func init_wire_net(net_size :Vector2, wire_count :Vector2i, wire_radius :float, co :Color) -> MultiMeshShape:
	var 선 := BoxMesh.new()
	var count := wire_count.x + wire_count.y
	init_with_color(선, Color.WHITE, count)
	for i in count:
		multimesh.set_instance_color(i,co)
		if i < wire_count.x:
			var pos := Vector3( net_size.x/(wire_count.x-1)* i, net_size.y/2, 0)
			var t := Transform3D(Basis(), pos)
			#t = t.rotated(Vector3(0,1,0), bar_rot)
			t = t.scaled_local( Vector3(wire_radius,net_size.y,wire_radius) )
			multimesh.set_instance_transform(i,t)
		else:
			var pos := Vector3(net_size.x/2, net_size.y/(wire_count.y-1)* (i-wire_count.x), 0)
			var t := Transform3D(Basis(), pos)
			#t = t.rotated(Vector3(0,1,0), bar_rot)
			t = t.scaled_local( Vector3(net_size.x,wire_radius,wire_radius) )
			multimesh.set_instance_transform(i,t)
	return self

func init_bar_gauge_y(count :int, sz :Vector3, co1 :Color, co2 :Color, alpha :float = 1.0 , gaprate :float = 0.1) -> MultiMeshShape:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(sz.x, sz.y / count * (1-gaprate) , sz.z)
	init_with_color(mesh, Color(Color.WHITE, alpha), count)
	for i in count:
		var rate := (i as float) / (count as float)
		var pos3d := Vector3(0,rate*sz.y,0) # grow upward
		set_inst_pos(i, pos3d)
		set_inst_color(i, lerp(co1, co2, rate) )
	return self

# end example


func _init_multimesh(mesh :Mesh, mat :Material) -> void:
	mesh.material = mat
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D

func _set_count(count :int) -> void:
	multimesh.instance_count = count
	multimesh.visible_instance_count = count

func make_color_material(co :Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	# draw call 이 TRANSPARENCY_ALPHA 인 경우만 줄어든다. 버그인가?
	if co.a >= 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	else:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = co
	mat.vertex_color_use_as_albedo = true
	return mat

func _init_transform() -> void:
	for i in multimesh.visible_instance_count:
		multimesh.set_instance_transform(i,Transform3D())

func init_with_color(mesh :Mesh, co :Color, count :int) -> MultiMeshShape:
	_init_multimesh(mesh, make_color_material(co))
	multimesh.use_colors = true # before set instance_count
	# Then resize (otherwise, changing the format is not allowed).
	_set_count(count)
	_init_transform()
	return self

func init_with_material(mesh :Mesh, mat :Material, count :int) -> MultiMeshShape:
	_init_multimesh(mesh, mat)
	# Then resize (otherwise, changing the format is not allowed).
	_set_count(count)
	_init_transform()
	return self

func color_used() -> bool:
	return multimesh.use_colors

func set_gradient_color(color_from :Color, color_to:Color) -> void:
	var count :int = get_visible_count()
	for i in count:
		var rate = float(i)/(count-1)
		multimesh.set_instance_color(i,color_from.lerp(color_to,rate))

func get_total_count() -> int:
	return multimesh.instance_count

func normalize_visible_count() -> int:
	if multimesh.visible_instance_count <= 0:
		multimesh.visible_instance_count = 0
		return -1
	elif multimesh.visible_instance_count >= multimesh.instance_count:
		multimesh.visible_instance_count = multimesh.instance_count
		return 1
	return 0

func get_visible_count() -> int:
	return multimesh.visible_instance_count

func set_visible_count( i :int) -> int:
	multimesh.visible_instance_count = i
	return normalize_visible_count()

func inc_visible_count( n :int = 1 ) -> int:
	multimesh.visible_instance_count += n
	return normalize_visible_count()

func dec_visible_count( n :int = 1 ) -> int:
	multimesh.visible_instance_count -= n
	return normalize_visible_count()

func set_visible_rate( v :float) -> int:
	multimesh.visible_instance_count = int(v * multimesh.instance_count)
	return normalize_visible_count()

func calc_visible_rate() -> float:
	return float(multimesh.visible_instance_count) / float(multimesh.instance_count)

func set_inst_rotation(i :int, axis :Vector3, rot :float) -> void:
	var t := multimesh.get_instance_transform(i)
	t = t.rotated_local(axis, rot)
	multimesh.set_instance_transform(i,t )

func set_inst_pos(i :int, pos :Vector3) -> void:
	var t := multimesh.get_instance_transform(i)
	t.origin = pos
	multimesh.set_instance_transform(i,t )

func set_inst_color(i, co :Color) -> void:
	multimesh.set_instance_color(i,co)
