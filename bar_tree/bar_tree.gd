extends Node3D
class_name BarTree

var tree_width :float = 3.0
var tree_height :float = 1.6
var bar_width_base_rate :float = 3.0
var bar_count :int = 100
var bar_rotation_base_velocity :float = 5.0

var bar_height :float = tree_height/bar_count
var bar_list :Array
var auto_rotate_bar :float


func init_with_color(co1 :Color, co2:Color, emission :bool,
		w: float, h :float, bar_w :float, b_count:int, rot_vel :float, autorot :float = 1.0/60.0)->void:
	tree_height = h
	tree_width = w
	bar_width_base_rate = bar_w
	bar_count = b_count
	bar_height = tree_height/bar_count

	bar_rotation_base_velocity = rot_vel
	auto_rotate_bar = autorot
	clear_bar_list()
	for i in bar_count:
		var rate = float(i)/bar_count
		var bar_color = co1.lerp(co2,rate)
		var mat = get_color_mat(bar_color)
		if emission:
			mat.emission_enabled = true
			mat.emission = bar_color
		var sp = new_bar_inst3d(i,mat)
		bar_list.append(sp)
		add_child(sp)

func init_with_material(mat :Material,
		w: float, h :float, bar_w :float, b_count:int, rot_vel :float, autorot :float = 1.0/60.0)->void:
	tree_height = h
	tree_width = w
	bar_width_base_rate = bar_w
	bar_count = b_count
	bar_height = tree_height/bar_count

	bar_rotation_base_velocity = rot_vel
	auto_rotate_bar = autorot
	clear_bar_list()
	for i in bar_count:
		var sp = new_bar_inst3d(i,mat)
		bar_list.append(sp)
		add_child(sp)

func clear_bar_list()->void:
	for sp in bar_list:
		remove_child(sp)
	bar_list.clear()

func _process(delta: float) -> void:
	if auto_rotate_bar != 0.0:
		bar_rotate_y(auto_rotate_bar)

func get_color_mat(co: Color)->Material:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = co
	mat.metallic = 1
	mat.clearcoat = true
	return mat

func new_bar_inst3d(i :int, mat :Material)->MeshInstance3D:
	var pos_rev = float(bar_count-i)
	var pos_rev_rate = pos_rev / float(bar_count)
	var y = float(i) * bar_height
	var l = pos_rev / bar_count * tree_width
	var bar_width = bar_height * tree_width * bar_width_base_rate * pos_rev_rate
	var bar_size = Vector3(bar_width, bar_height, l)
	var mesh = BoxMesh.new()
	mesh.size = bar_size
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	sp.position.y = y
	return sp

func reset_bar_rotation()->void:
	for sp in bar_list:
		sp.rotation = Vector3.ZERO

func bar_rotation_y(delta:float)->void:
	for i in bar_list.size():
		bar_list[i].rotation.y =  delta * (bar_rotation_base_velocity * float(i)*PI/bar_count)

func bar_rotate_y(delta:float)->void:
	for i in bar_list.size():
		bar_list[i].rotate_y( delta * (bar_rotation_base_velocity * float(i)*PI/bar_count) )
