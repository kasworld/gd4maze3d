extends Node3D
class_name MeshTrail

enum ColorMode {OnBounce, MeshGradient, ByPosition }
var color_mode :ColorMode = ColorMode.OnBounce

func init_OnBounce() -> MeshTrail:
	color_mode = ColorMode.OnBounce
	return self

# for ColorMode.MeshGradient 
var color_from :Color # or current color
var color_to :Color
var color_progress :int # 0 to mesh_count-1
func get_color_MeshGradient() -> Color:
	color_progress += 1
	if color_progress >= multimesh.instance_count:
		color_from = color_to
		color_to = get_random_color_fn.call()
		color_progress = 0
	return lerp(color_from, color_to, float(color_progress)/float(multimesh.instance_count))

func init_MeshGradient() -> MeshTrail:
	color_mode = ColorMode.MeshGradient
	return self

var color_aabb :AABB
func init_ByPosition(c_aabb :AABB) -> MeshTrail:
	color_mode = ColorMode.ByPosition
	color_aabb = c_aabb
	return self

func init_ByPositionFn(fn :Callable) -> MeshTrail:
	color_mode = ColorMode.ByPosition
	get_color_ByPosition_fn = fn
	return self
	
var get_color_ByPosition_fn = get_color_ByPosition
func get_color_ByPosition(pos :Vector3) -> Color:
	var co :Color
	for i in 3:
		co[i] = (pos[i] - color_aabb.position[i]) / color_aabb.size[i]
	return co

var get_random_color_fn :Callable = get_random_color
func set_get_random_color_fn(fn :Callable) -> MeshTrail:
	get_random_color_fn = fn
	return self
func get_random_color() -> Color:
	#return NamedColorList.color_list.pick_random()[0]
	return Color(randf(),randf(),randf())

var velocity :Vector3
var bounce_fn :Callable
var radius :float
var speed_max :float
var speed_min :float
var obj_cursor :int
var current_rotation :float
var current_rotation_velocity :float
var rotation_velocity_deviation :float
var mesh_trail :MultiMeshInstance3D
var multimesh :MultiMesh

func init(bounce_fn_a :Callable, radius_a :float, mesh_count :int, mesh_type, initial_pos :Vector3, rotation_velocity_deviation_a :float = 4*PI) -> MeshTrail:
	radius = radius_a
	bounce_fn = bounce_fn_a
	rotation_velocity_deviation = rotation_velocity_deviation_a
	speed_max = radius * 120
	speed_min = radius * 80
	velocity = Vector3( (randf()-0.5)*speed_max,(randf()-0.5)*speed_max,(randf()-0.5)*speed_max)
	color_from = get_random_color_fn.call()
	color_to = get_random_color_fn.call()
	make_mat_multi(new_mesh_by_type(mesh_type,radius), mesh_count, initial_pos)
	return self

func make_mat_multi(mesh :Mesh,count :int, initial_pos:Vector3):
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
		set_color_by_mode(i, initial_pos)
		var t = Transform3D(Basis(), initial_pos)
		multimesh.set_instance_transform(i,t)

func set_color_by_mode(mesh_index :int, pos :Vector3) -> void:
	var co :Color
	match color_mode:
		ColorMode.ByPosition:
			co = get_color_ByPosition_fn.call(pos)
		ColorMode.OnBounce:
			co = color_from
		ColorMode.MeshGradient:
			co = get_color_MeshGradient()
	multimesh.set_instance_color(mesh_index, co)
	
func set_multi_pos_rot(i :int, pos :Vector3, axis :Vector3, rot :float) -> void:
	var t = Transform3D(Basis(), pos)
	t = t.rotated_local(axis, rot)
	multimesh.set_instance_transform(i,t )

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
		if color_mode == ColorMode.OnBounce:
			color_from = get_random_color_fn.call()
		current_rotation_velocity =  randfn(0, rotation_velocity_deviation)
	current_rotation += current_rotation_velocity * delta

	set_multi_pos_rot(newi, bn.pos, velocity.normalized(), current_rotation)
	set_color_by_mode(newi, newpos)

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
