extends MultiMeshShape
class_name MeshTrail

static func NewMeshByType(mesh_type , r :float) -> Mesh:
	var mesh :Mesh
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
			mesh.depth = r/6
			mesh.pixel_size = r / 6
			mesh.text = "%s" % mesh_type
	return mesh


enum ColorChange {OnBounce, MeshGradient, ByPosition }
var color_change_mode :ColorChange = ColorChange.OnBounce

func set_ColorChange_OnBounce() -> MeshTrail:
	color_change_mode = ColorChange.OnBounce
	return self

# for ColorChange.MeshGradient
var color_from :Color # or current color
var color_to :Color
var color_progress :int # 0 to inst_count-1
func get_color_MeshGradient() -> Color:
	color_progress += 1
	if color_progress >= multimesh.instance_count:
		color_from = color_to
		color_to = get_random_color_fn.call()
		color_progress = 0
	return lerp(color_from, color_to, float(color_progress)/float(multimesh.instance_count))

func set_ColorChange_MeshGradient() -> MeshTrail:
	color_change_mode = ColorChange.MeshGradient
	return self

var color_aabb :AABB
func set_ColorChange_ByPosition(c_aabb :AABB) -> MeshTrail:
	color_change_mode = ColorChange.ByPosition
	color_aabb = c_aabb
	return self

func set_ColorChange_ByPositionFn(fn :Callable) -> MeshTrail:
	color_change_mode = ColorChange.ByPosition
	get_color_ByPosition_fn = fn
	return self

var get_color_ByPosition_fn :Callable = get_color_ByPosition
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
	return Color(randf(),randf(),randf())

var head_velocity :Vector3
var bounce_fn :Callable
var radius :float
var speed_max :float
var speed_min :float
var obj_cursor :int
var current_rotation :float
var current_rotation_velocity :float
var rotation_velocity_deviation :float

func init(bounce_fn_a :Callable, radius_a :float, inst_count :int, mesh_type, initial_pos :Vector3, rotation_velocity_deviation_a :float = 4*PI) -> MeshTrail:
	radius = radius_a
	bounce_fn = bounce_fn_a
	rotation_velocity_deviation = rotation_velocity_deviation_a
	speed_max = radius * 40
	speed_min = radius * 20
	head_velocity = Vector3( (randf()-0.5)*speed_max, (randf()-0.5)*speed_max, (randf()-0.5)*speed_max)
	color_from = get_random_color_fn.call()
	color_to = get_random_color_fn.call()
	init_with_alpha(NewMeshByType(mesh_type,radius), inst_count, 1.0, initial_pos)
	return self

func set_speed(mins :float, maxs :float) -> MeshTrail:
	speed_max = maxs
	speed_min = mins
	return self

func set_color_by_mode(inst_index :int, pos :Vector3) -> void:
	var co :Color
	match color_change_mode:
		ColorChange.ByPosition:
			co = get_color_ByPosition_fn.call(pos)
		ColorChange.OnBounce:
			co = color_from
		ColorChange.MeshGradient:
			co = get_color_MeshGradient()
	multimesh.set_instance_color(inst_index, co)

func set_multi_pos_rot(i :int, pos :Vector3, axis :Vector3, rot :float) -> void:
	var t := Transform3D(Basis(), pos)
	t = t.rotated_local(axis, rot)
	multimesh.set_instance_transform(i,t )

func move(delta :float) -> void:
	var old_cursor := obj_cursor
	obj_cursor +=1
	obj_cursor %= multimesh.instance_count
	_move_trail(delta, old_cursor, obj_cursor)

func _move_trail(delta: float, oldi :int, newi:int) -> void:
	var oldpos :Vector3 = multimesh.get_instance_transform(oldi).origin
	var newpos :Vector3 = oldpos + head_velocity * delta
	var bn = bounce_fn.call(oldpos,newpos,radius)
	for i in 3:
		# change vel on bounce
		if bn.bounced[i] != 0 :
			head_velocity[i] = -randf_range(speed_min, speed_max)*bn.bounced[i]

	if bn.bounced != Vector3i.ZERO:
		if color_change_mode == ColorChange.OnBounce:
			color_from = get_random_color_fn.call()
		current_rotation_velocity =  randfn(0, rotation_velocity_deviation)
	current_rotation += current_rotation_velocity * delta

	set_multi_pos_rot(newi, bn.pos, head_velocity.normalized(), current_rotation)
	set_color_by_mode(newi, newpos)

	if head_velocity.length() > speed_max:
		head_velocity = head_velocity.normalized() * speed_max
	if head_velocity.length() < speed_min:
		head_velocity = head_velocity.normalized() * speed_min
