extends Node3D

class_name BarTree2

var tree_width :float = 3.0
var tree_height :float = 1.6
var bar_width :float = 3.0
var bar_count :int = 100
var bar_rotation :float = 5.0
var bar_rotation_begin :float = 0.0
var bar_shift_rate := 0.0
var auto_rotate_bar :bool
var use_color :bool
var color_from :Color
var color_to :Color

func init_common_params(
		tree_width_a: float, 
		tree_height_a :float, 
		bar_width_a :float, 
		bar_count_a:int, 
		bar_rotation_a :float, 
		bar_rotation_begin_a :float, 
		bar_shift_rate_a :float, 
		auto_rotate_bar_a:bool) -> BarTree2:
	tree_height = tree_height_a
	tree_width = tree_width_a
	bar_width = bar_width_a
	bar_count = bar_count_a
	bar_rotation = bar_rotation_a
	bar_rotation_begin = bar_rotation_begin_a
	bar_shift_rate = bar_shift_rate_a
	auto_rotate_bar = auto_rotate_bar_a
	return self	

func init_with_color(co1 :Color, co2:Color) -> BarTree2:
	use_color = true
	color_from = co1
	color_to = co2
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.vertex_color_use_as_albedo = true
	init_mesh_multi1(mat)
	$MultiMeshInstance3D.multimesh.use_colors = true # before set instance_count
	# Then resize (otherwise, changing the format is not allowed).
	init_mesh_multi2()
	update_bar_transform()
	update_bar_color()
	return self

func init_with_material(mat :Material) -> BarTree2:
	init_mesh_multi1(mat)
	# Then resize (otherwise, changing the format is not allowed).
	init_mesh_multi2()
	update_bar_transform()
	return self

func init_mesh_multi1(mat :Material) -> void:
	$MultiMeshInstance3D.multimesh.mesh.material = mat

func init_mesh_multi2() -> void:
	$MultiMeshInstance3D.multimesh.instance_count = bar_count
	$MultiMeshInstance3D.multimesh.visible_instance_count = bar_count

# also reset bar rotation
func update_bar_transform() -> void:
	# Set the transform of the instances.
	var bar_height = tree_height/bar_count
	for i in $MultiMeshInstance3D.multimesh.visible_instance_count:
		var rate = float(i)/bar_count
		var rev_rate = 1 - rate
		var bar_position = Vector3(0, i *bar_height +bar_height/2, tree_width * rev_rate /2 * bar_shift_rate)
		#var bar_position = Vector3(bar_width*rev_rate/2, i *bar_height +bar_height/2, tree_width * rev_rate /2 * bar_shift_rate)
		var bar_size = Vector3(bar_width * rev_rate, bar_height, tree_width * rev_rate )
		var bar_rot = bar_rotation * rate + bar_rotation_begin
		var t = Transform3D(Basis(), bar_position)
		t = t.rotated(Vector3(0,1,0), bar_rot)
		t = t.scaled_local( bar_size )
		$MultiMeshInstance3D.multimesh.set_instance_transform(i,t )

func update_bar_color() -> void:
	assert(use_color)
	for i in $MultiMeshInstance3D.multimesh.visible_instance_count:
		var rate = float(i)/bar_count
		$MultiMeshInstance3D.multimesh.set_instance_color(i,color_from.lerp(color_to,rate))
		
func set_visible_bar_count(bar_count_a :int) -> void:
	assert(bar_count_a >= 0)
	bar_count = bar_count_a
	assert($MultiMeshInstance3D.multimesh.instance_count >= bar_count)
	$MultiMeshInstance3D.multimesh.visible_instance_count = bar_count
	update_bar_transform()
	if use_color:
		update_bar_color()

func set_bar_color(co1 :Color, co2:Color) -> void:
	assert(use_color)
	use_color = true
	color_from = co1
	color_to = co2
	update_bar_color()

func _process(_delta: float) -> void:
	if auto_rotate_bar:
		bar_rotation_y()

func bar_rotation_y() -> void:
	for i in $MultiMeshInstance3D.multimesh.visible_instance_count:
		var t = $MultiMeshInstance3D.multimesh.get_instance_transform(i)
		var rate = float(i)/bar_count
		var bar_rot = rate * bar_rotation 
		t = t.rotated(Vector3(0,1,0), bar_rot)
		$MultiMeshInstance3D.multimesh.set_instance_transform(i,t )
