extends MultiMeshInstance3D
class_name MultiMeshShape

static func 집중선만들기(r :float, start:float, end:float, depth :float, count :int, co :Color) -> MultiMeshShape:
	var 구분선 := BoxMesh.new()
	var 길이 := r*(end-start)
	구분선.size = Vector3(길이, depth/10, depth )
	var cell각도 := 2.0*PI / count
	var radius := r-길이/2
	var mms :MultiMeshShape = preload("res://multi_mesh_shape/multi_mesh_shape.tscn").instantiate().init_with_color(
		구분선, Color.WHITE, count)
	for i in count:
		var rad := cell각도 *i + cell각도/2
		mms.set_inst_rotation(i, Vector3.BACK, rad)
		mms.set_inst_pos(i, Vector3(cos(rad) *radius,sin(rad) *radius, 0) )
		mms.set_inst_color(i, co)
	return mms

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

func set_visible_count(i :int) -> void:
	multimesh.visible_instance_count = i

func get_visible_count() -> int:
	return multimesh.visible_instance_count

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
