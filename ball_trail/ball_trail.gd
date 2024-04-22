extends Node3D

class_name BallTrail

var velocity :Vector3
var bounce_area :AABB
var radius :float
var speed_max :float
var speed_min :float
var obj_count :int
var obj_list = []
var obj_cursor :int
var current_mat :Material
var current_rot :Vector3
var current_rot_accel :Vector3

func init(ba :AABB, r :float, count :int, t:int)->void:
	radius = r
	bounce_area = ba
	obj_count = count
	speed_max = radius * 300
	speed_min = radius * 120
	velocity = Vector3( (randf()-0.5)*speed_max,(randf()-0.5)*speed_max,(randf()-0.5)*speed_max)
	current_mat = Global3d.get_color_mat(NamedColorList.color_list.pick_random()[0] )
	current_rot_accel = Vector3(rand_rad(),rand_rad(),rand_rad())
	for i in obj_count:
		var sp = MeshInstance3D.new()
		sp.mesh = new_mesh_by_type(t,radius,current_mat)
		add_child(sp)
		obj_list.append(sp)

func set_aabb(ba :AABB)->void:
	bounce_area = ba

func _process(delta: float) -> void:
	move(delta)

func move(delta :float)->void:
	var old_obj = obj_list[obj_cursor%obj_count]
	obj_cursor +=1
	obj_list[obj_cursor%obj_count].position = old_obj.position
	move_ball(delta, obj_list[obj_cursor%obj_count])

func move_ball(delta: float, sp :Node3D) -> void:
	sp.position += velocity * delta
	var bn = Bounce.bounce3d(sp.position,velocity,bounce_area,radius)
	sp.position = bn.position
	velocity = bn.velocity
	var bounced = false
	for i in 3:
		# change vel on bounce
		if bn.bounced[i] != 0 :
			velocity[i] = -random_positive(speed_max/2)*bn.bounced[i]
			bounced = true

	if bounced :
		current_mat = Global3d.get_color_mat(NamedColorList.color_list.pick_random()[0] )
		current_rot_accel = Vector3(rand_rad(),rand_rad(),rand_rad())
	sp.mesh.material = current_mat
	current_rot += current_rot_accel
	sp.rotation = current_rot

	if velocity.length() > speed_max:
		velocity = velocity.normalized() * speed_max
	if velocity.length() < speed_min:
		velocity = velocity.normalized() * speed_min

func new_mesh_by_type(t :int, r :float, mat :Material)->Mesh:
	var mesh:Mesh
	match t%7:
		0:
			mesh = SphereMesh.new()
			mesh.radius = r
		1:
			mesh = BoxMesh.new()
			mesh.size = Vector3(r,r,r)*1.5
		2:
			mesh = PrismMesh.new()
			mesh.size = Vector3(r,r,r)*1.5
		3:
			mesh = TextMesh.new()
			mesh.depth = r/4
			mesh.pixel_size = r / 10
			mesh.font_size = r*50
			mesh.text = "A"
		4:
			mesh = TorusMesh.new()
			mesh.inner_radius = r/2
			mesh.outer_radius = r
		5:
			mesh = CapsuleMesh.new()
			mesh.height = r*3
			mesh.radius = r*0.75
		6:
			mesh = CylinderMesh.new()
			mesh.height = r*2
			mesh.bottom_radius = r
			mesh.top_radius = 0
	mesh.material = mat
	return mesh

func rand_rad()->float:
	return randf_range(-PI,PI)/10

func random_positive(w :float)->float:
	return randf_range(w/10,w)

