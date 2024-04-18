extends Node3D

class_name BarTree2

var tree_width :float = 3.0
var tree_height :float = 1.6
var bar_width :float = 3.0
var bar_count :int = 100
var bar_rotation :float = 5.0
var auto_rotate_bar :bool
var multi_bar :MultiMeshInstance3D
var multimesh :MultiMesh

func init_with_color(co1 :Color, co2:Color,
		w: float, h :float, bar_w :float, b_count:int, rot_vel :float, autorot:bool)->void:
	tree_height = h
	tree_width = w
	bar_width = bar_w
	bar_count = b_count
	bar_rotation = rot_vel
	auto_rotate_bar = autorot
	make_color_multi(co1,co2)

func init_with_material(mat :Material,
		w: float, h :float, bar_w :float, b_count:int, rot_vel :float, autorot:bool)->void:
	tree_height = h
	tree_width = w
	bar_width = bar_w
	bar_count = b_count
	bar_rotation = rot_vel
	auto_rotate_bar = autorot
	make_mat_multi(mat)

func make_color_multi(co1 :Color, co2:Color):
	var mat = get_color_mat(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1,1,1)
	mesh.material = mat

	multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true # before set instance_count
	# Then resize (otherwise, changing the format is not allowed).
	multimesh.instance_count = bar_count
	multimesh.visible_instance_count = bar_count

	# Set the transform of the instances.
	var bar_height = tree_height/bar_count
	for i in multimesh.visible_instance_count:
		var rate = float(i)/bar_count
		var rev_rate = 1 - rate

		multimesh.set_instance_color(i,co1.lerp(co2,rate))
		var bar_position = Vector3(0,i *bar_height,0)
		var bar_size = Vector3(bar_width * rev_rate, bar_height, tree_width * rev_rate )
		var bar_rot = bar_rotation * rate

		var t = Transform3D(Basis(), bar_position)
		t = t.rotated_local(Vector3(0,1,0), bar_rot)
		t = t.scaled_local( bar_size )
		multimesh.set_instance_transform(i,t )

	multi_bar = MultiMeshInstance3D.new()
	multi_bar.multimesh = multimesh
	add_child(multi_bar)

func make_mat_multi(mat :Material):
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1,1,1)
	mesh.material = mat

	multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Then resize (otherwise, changing the format is not allowed).
	multimesh.instance_count = bar_count
	multimesh.visible_instance_count = bar_count

	# Set the transform of the instances.
	var bar_height = tree_height/bar_count
	for i in multimesh.visible_instance_count:
		var rate = float(i)/bar_count
		var rev_rate = 1 - rate

		var bar_position = Vector3(0,i *bar_height,0)
		var bar_size = Vector3(bar_width * rev_rate, bar_height, tree_width * rev_rate )
		var bar_rot = bar_rotation * rate

		var t = Transform3D(Basis(), bar_position)
		t = t.rotated_local(Vector3(0,1,0), bar_rot)
		t = t.scaled_local( bar_size )
		multimesh.set_instance_transform(i,t )

	multi_bar = MultiMeshInstance3D.new()
	multi_bar.multimesh = multimesh
	add_child(multi_bar)

func _process(delta: float) -> void:
	if auto_rotate_bar:
		bar_rotation_y()

func reset_bar_rotation()->void:
	for i in multimesh.visible_instance_count:
		var t = multimesh.get_instance_transform(i)
		t = t.rotated_local(Vector3(0,1,0), 0)
		multimesh.set_instance_transform(i,t )

func bar_rotation_y()->void:
	for i in multimesh.visible_instance_count:
		var t = multimesh.get_instance_transform(i)
		var rate = float(i)/bar_count
		var bar_rot = rate * bar_rotation
		t = t.rotated(Vector3(0,1,0), bar_rot)
		multimesh.set_instance_transform(i,t )

func get_color_mat(co: Color)->Material:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = co
	mat.metallic = 1
	mat.clearcoat = true
	return mat

