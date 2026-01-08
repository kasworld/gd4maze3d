extends MultiMeshInstance3D
class_name MultiMeshShape

# example usage ################################################################

func init_집중선(r :float, start:float, end:float, depth :float, count :int, co :Color, alpha :float = 1.0) -> MultiMeshShape:
	var 구분선 := BoxMesh.new()
	var 길이 := r*(end-start)
	구분선.size = Vector3(길이, depth/10, depth )
	var cell각도 := 2.0*PI / count
	var radius := r-길이/2
	구분선.material = make_color_material(alpha)
	init_with_color_mesh(구분선, count)
	for i in count:
		var rad := cell각도 *i + cell각도/2
		set_inst_rotation(i, Vector3.BACK, rad)
		set_inst_position(i, Vector3(cos(rad) *radius,sin(rad) *radius, 0) )
		set_inst_color(i, co)
	return self

func init_wire_net(net_size :Vector2, grid_count :Vector2i, wire_radius :float, co :Color, alpha :float = 1.0) -> MultiMeshShape:
	var wire_count := Vector2i(grid_count.x +1, grid_count.y +1)
	var pos_shift := -Vector3(net_size.x, net_size.y, 0)/2
	var 선 := BoxMesh.new()
	var count := wire_count.x + wire_count.y
	선.material = make_color_material(alpha)
	init_with_color_mesh(선, count)
	for i in count:
		multimesh.set_instance_color(i,co)
		if i < wire_count.x:
			var pos := Vector3( net_size.x/(wire_count.x-1)* i, net_size.y/2, 0) + pos_shift
			var t := Transform3D(Basis(), pos)
			#t = t.rotated(Vector3(0,1,0), bar_rot)
			t = t.scaled_local( Vector3(wire_radius,net_size.y,wire_radius) )
			multimesh.set_instance_transform(i,t)
		else:
			var pos := Vector3(net_size.x/2, net_size.y/(wire_count.y-1)* (i-wire_count.x), 0) + pos_shift
			var t := Transform3D(Basis(), pos)
			#t = t.rotated(Vector3(0,1,0), bar_rot)
			t = t.scaled_local( Vector3(net_size.x,wire_radius,wire_radius) )
			multimesh.set_instance_transform(i,t)
	return self

func init_bar_gauge_y(count :int, sz :Vector3, co1 :Color, co2 :Color, alpha :float = 1.0, gaprate :float = 0.1) -> MultiMeshShape:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(sz.x, sz.y / count * (1-gaprate) , sz.z)
	mesh.material = make_color_material(alpha)
	init_with_color_mesh(mesh, count)
	for i in count:
		var rate := (i as float) / (count as float)
		var pos3d := Vector3(0,rate*sz.y,0) # grow upward
		set_inst_position(i, pos3d)
		set_inst_color(i, lerp(co1, co2, rate) )
	return self

func init_wire_box(box_size :Vector3, wire_width :float, co :Color, alpha :float = 1.0) -> MultiMeshShape:
	var mesh := BoxMesh.new()
	mesh.material = make_color_material(alpha)
	init_with_color_mesh(mesh, 12, false)
	set_color_all(co)
	var wire_scale := Vector3(wire_width, wire_width, box_size.z)
	var i := 0
	for pos in [
		Vector3( box_size.x/2,  box_size.y/2,0),
		Vector3( -box_size.x/2,  box_size.y/2,0),
		Vector3( box_size.x/2,  -box_size.y/2,0),
		Vector3( -box_size.x/2,  -box_size.y/2,0),
		]:
			multimesh.set_instance_transform(i, Transform3D(Basis(), pos).scaled_local( wire_scale ))
			i += 1
	wire_scale = Vector3(box_size.x, wire_width, wire_width)
	for pos in [
		Vector3(0, box_size.y/2,  box_size.z/2),
		Vector3(0, -box_size.y/2,  box_size.z/2),
		Vector3(0, box_size.y/2,  -box_size.z/2),
		Vector3(0, -box_size.y/2,  -box_size.z/2),
		]:
			multimesh.set_instance_transform(i, Transform3D(Basis(), pos).scaled_local( wire_scale ))
			i += 1
	wire_scale = Vector3(wire_width, box_size.y,  wire_width)
	for pos in [
		Vector3( box_size.x/2, 0,  box_size.z/2),
		Vector3( -box_size.x/2, 0,  box_size.z/2),
		Vector3( box_size.x/2, 0,  -box_size.z/2),
		Vector3( -box_size.x/2, 0,  -box_size.z/2),
		]:
			multimesh.set_instance_transform(i, Transform3D(Basis(), pos).scaled_local( wire_scale ))
			i += 1
	return self

func init_spheres_by_point_list(point_list :Array, point_radius :float, co :Color, alpha :float = 1.0) -> MultiMeshShape:
	var sp_mesh := SphereMesh.new()
	sp_mesh.material = make_color_material(alpha)
	sp_mesh.radius = point_radius
	sp_mesh.height = point_radius*2
	return init_meshs_by_point_list(sp_mesh, point_list, co)

func init_meshs_by_point_list(mesh :Mesh, point_list :Array, co :Color) -> MultiMeshShape:
	init_with_color_mesh(mesh, point_list.size(), false)
	set_color_all(co)
	for i in point_list.size():
		multimesh.set_instance_transform(i, Transform3D(Basis(), point_list[i]))
	return self

func multi_line_by_pos(pos_list:Array, wire_width :float, co :Color, alpha :float = 1.0) -> MultiMeshShape:
	var mesh := BoxMesh.new()
	mesh.material = make_color_material(alpha)
	return multi_mesh_line_by_pos(mesh, pos_list, wire_width, co)

func multi_mesh_line_by_pos(mesh :Mesh, pos_list:Array, wire_width :float, co :Color) -> MultiMeshShape:
	init_with_color_mesh(mesh, pos_list.size(), false)
	set_color_all(co)
	for i in pos_list.size():
		var p1 :Vector3 = pos_list[i][0]
		var p2 :Vector3 = pos_list[i][1]
		var center := (p1+p2)/2
		var l := p1.distance_to(p2)
		var wire_scale := Vector3(wire_width, wire_width, l)
		var t := Transform3D(Basis(), center)
		t = t.looking_at(p2)
		t = t.scaled_local(wire_scale)
		multimesh.set_instance_transform(i,t)
	return self

# end example ##################################################################

static func make_color_material(alpha :float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	# draw call 이 TRANSPARENCY_ALPHA 인 경우만 줄어든다. 버그인가?
	if alpha >= 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	else:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(Color.WHITE,alpha)
	mat.vertex_color_use_as_albedo = true

	#mat.metallic = 1.0
	##mat.roughness = 0.5
	#mat.clearcoat_enabled = true
	#mat.refraction_enabled = true
	#mat.rim_enabled = true
	return mat


func _set_count(count :int) -> void:
	multimesh.instance_count = count
	multimesh.visible_instance_count = count


func _init_multimesh(mesh :Mesh) -> void:
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D

func init_with_mesh( mesh :Mesh, count :int,
		callinit_transform :bool = true,
		pos :Vector3 = Vector3.ZERO ) -> MultiMeshShape:
	_init_multimesh(mesh)
	# Then resize (otherwise, changing the format is not allowed).
	_set_count(count)
	if callinit_transform:
		init_position_all(pos)
	return self

func init_with_color_mesh( mesh :Mesh, count :int,
		callinit_transform :bool = true,
		pos :Vector3 = Vector3.ZERO) -> MultiMeshShape:
	_init_multimesh(mesh)
	multimesh.use_colors = true # before set instance_count
	# Then resize (otherwise, changing the format is not allowed).
	_set_count(count)
	if callinit_transform:
		init_position_all(pos)
	return self

#func init_with_alpha( mesh :Mesh, count :int,
		#alpha :float = 1.0,
		#callinit_transform :bool = true,
		#pos :Vector3 = Vector3.ZERO) -> MultiMeshShape:
	#if alpha == 1.0:
		#mesh.material = make_color_material( Color.WHITE )
	#else:
		#mesh.material = make_color_material( Color(Color.WHITE,alpha) )
	#_init_multimesh(mesh)
	#multimesh.use_colors = true # before set instance_count
	## Then resize (otherwise, changing the format is not allowed).
	#_set_count(count)
	#if callinit_transform:
		#init_position_all(pos)
	#return self


func init_position_all(pos :Vector3 = Vector3.ZERO) -> void:
	if pos == Vector3.ZERO:
		for i in multimesh.visible_instance_count:
			multimesh.set_instance_transform(i,Transform3D())
	else:
		for i in multimesh.visible_instance_count:
			var t = Transform3D(Basis(), pos)
			multimesh.set_instance_transform(i,t)

func set_position_all(pos :Vector3) -> MultiMeshShape:
	for i in multimesh.visible_instance_count:
		var t := multimesh.get_instance_transform(i)
		t.origin = pos
		multimesh.set_instance_transform(i,t)
	return self

func set_color_all(color :Color) -> MultiMeshShape:
	for i in multimesh.visible_instance_count:
		multimesh.set_instance_color(i,color)
	return self

func set_gradient_color_all(color_from :Color, color_to:Color) -> MultiMeshShape:
	var count :int = multimesh.visible_instance_count
	for i in count:
		var rate = float(i)/(count-1)
		multimesh.set_instance_color(i,color_from.lerp(color_to,rate))
	return self

func color_used() -> bool:
	return multimesh.use_colors

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
	multimesh.set_instance_transform(i, t)

func set_inst_scale(i :int, scale_a :Vector3) -> void:
	var t := multimesh.get_instance_transform(i)
	t = t.scaled_local(scale_a)
	multimesh.set_instance_transform(i, t)

func set_inst_position(i :int, pos :Vector3) -> void:
	var t := multimesh.get_instance_transform(i)
	t.origin = pos
	multimesh.set_instance_transform(i, t)

func set_inst_color(i, co :Color) -> void:
	multimesh.set_instance_color(i,co)

func set_inst_position_rotation(i :int, pos :Vector3, axis :Vector3, rot :float) -> void:
	var t := Transform3D(Basis(), pos)
	t = t.rotated_local(axis, rot)
	multimesh.set_instance_transform(i, t)
