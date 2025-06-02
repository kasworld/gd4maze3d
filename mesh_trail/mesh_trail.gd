extends Node3D

class_name MeshTrail

var velocity :Vector3
var bounce_fn :Callable
var radius :float
var speed_max :float
var speed_min :float
var obj_cursor :int
var current_color :Color
var current_rot :float
var current_rot_accel :float
var mesh_trail :MultiMeshInstance3D
var multimesh :MultiMesh

func init(bnfn :Callable, r :float, count :int, mesh_type, pos :Vector3) -> MeshTrail:
	radius = r
	bounce_fn = bnfn
	speed_max = radius * 120
	speed_min = radius * 80
	velocity = Vector3( (randf()-0.5)*speed_max,(randf()-0.5)*speed_max,(randf()-0.5)*speed_max)
	current_color = NamedColorList.color_list.pick_random()[0]
	make_mat_multi(new_mesh_by_type(mesh_type,radius), count, pos)
	return self

func make_mat_multi(mesh :Mesh,count :int, pos:Vector3):
	var mat = Global3d.get_color_mat(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true # before set instance_count
	# Then resize (otherwise, changing the format is not allowed).
	multimesh.instance_count = count
	multimesh.visible_instance_count = count
	mesh_trail = MultiMeshInstance3D.new()
	mesh_trail.multimesh = multimesh
	add_child(mesh_trail)

	for i in multimesh.visible_instance_count:
		multimesh.set_instance_color(i,current_color)
		var ball_position = pos
		var t = Transform3D(Basis(), ball_position)
		multimesh.set_instance_transform(i,t)

func set_multi_pos_rot(i :int, pos :Vector3, axis :Vector3, rot :float) -> void:
	var t = Transform3D(Basis(), pos)
	t = t.rotated_local(axis, rot)
	multimesh.set_instance_transform(i,t )

func set_multi_color(i, co :Color) -> void:
	multimesh.set_instance_color(i,co)

func _process(delta: float) -> void:
	move(delta)

func move(delta :float) -> void:
	var old_cursor = obj_cursor
	obj_cursor +=1
	obj_cursor %= multimesh.instance_count
	move_trail(delta, old_cursor, obj_cursor)

func move_trail(delta: float, oldi :int, newi:int) -> void:
	var oldpos = multimesh.get_instance_transform(oldi).origin
	var newpos = oldpos + velocity * delta
	var bn = bounce_fn.call(oldpos,newpos,radius)
	for i in 3:
		# change vel on bounce
		if bn.bounced[i] != 0 :
			velocity[i] = -random_positive(speed_max/2)*bn.bounced[i]

	if bn.bounced != Vector3i.ZERO:
		current_color = NamedColorList.color_list.pick_random()[0]
		current_rot_accel =  randfn(0, PI/4)
	current_rot += current_rot_accel
	set_multi_pos_rot(newi, bn.pos, velocity.normalized(), current_rot)
	set_multi_color(newi, current_color)

	if velocity.length() > speed_max:
		velocity = velocity.normalized() * speed_max
	if velocity.length() < speed_min:
		velocity = velocity.normalized() * speed_min

func new_mesh_by_type(mesh_type , r :float) -> Mesh:
	var mesh:Mesh
	match mesh_type:
		0:
			mesh = SphereMesh.new()
			mesh.radius = r
			mesh.height = r
		1:
			mesh = BoxMesh.new()
			mesh.size = Vector3(r,r,r)*1.5
		2:
			mesh = PrismMesh.new()
			mesh.size = Vector3(r,r,r)*1.5
		3:
			mesh = TorusMesh.new()
			mesh.inner_radius = r/2
			mesh.outer_radius = r
		4:
			mesh = CapsuleMesh.new()
			mesh.height = r*2
			mesh.radius = r*0.5
		5:
			mesh = CylinderMesh.new()
			mesh.height = r*2
			mesh.bottom_radius = r
			mesh.top_radius = 0
		_:
			mesh = TextMesh.new()
			mesh.depth = r/4
			mesh.pixel_size = r / 10
			mesh.font_size = r*200
			mesh.text = "%s" % mesh_type
	return mesh

func random_positive(w :float) -> float:
	return randf_range(w/10,w)
