extends Node3D

enum Act {Stop, Forward, Turn_Right , Turn_Left}
enum Dir {Up, Right, Down, Left}
var wall_scene = preload("res://wall_z.tscn")

var action :Act
var act_start_time :float # unixtime sec
var actor_dir_old : Dir
var actor_dir_new : Dir
var actor_pos_old :Vector2i
var actor_pos_new :Vector2i

func _ready() -> void:
	for i in 3000:
		add_wall_at(randi_range(-50,50), randi_range(-50,50), randi_range(0,1) == 0)
	act_start_time = Time.get_unix_time_from_system()

func _process(delta: float) -> void:
	var t = Time.get_unix_time_from_system()
	var dur = t - act_start_time
	if dur > 1 :
		actor_dir_old = actor_dir_new
		actor_pos_old = actor_pos_new
		act_start_time = t
		action = randi_range(0,3)
		start_action(action)
	else:
		do_action(dur)

func do_action(dur :float)->void:
	match action:
		Act.Stop:
			pass
		Act.Forward:
			move_forward(dur)
		Act.Turn_Left:
			turn_left(dur)
		Act.Turn_Right:
			turn_right(dur)

func start_action(a :Act)->void:
	match a:
		Act.Stop:
			pass
		Act.Forward:
			match actor_dir_old:
				Dir.Up:
					actor_pos_new.y = actor_pos_old.y -1
				Dir.Right:
					actor_pos_new.x = actor_pos_old.x -1
				Dir.Down:
					actor_pos_new.y = actor_pos_old.y +1
				Dir.Left:
					actor_pos_new.x = actor_pos_old.x +1
		Act.Turn_Left:
			actor_dir_new = (actor_dir_old -1+4)%4
		Act.Turn_Right:
			actor_dir_new = (actor_dir_old +1)%4


	#$Camera3D.rotate_y(delta/2)

func add_wall_at(x:int,y :int, face_x :bool)->void:
	var w = wall_scene.instantiate()
	w.position = Vector3(x,0 , y)
	if face_x:
		w.rotate_y(-PI/2)
	add_child(w)

# dur : 0 - 1 :second
func move_forward(dur :float)->void:
	var vt = Vector3(
		0.5+ lerpf(actor_pos_old.x , actor_pos_new.x , dur ) ,
		1,
		0.5+ lerpf(actor_pos_old.y , actor_pos_new.y , dur ) ,
	)
	$Camera3D.position = vt
# dur : 0 - 1 :second
func turn_right(dur :float)->void:
	var a = lerp_angle( deg_to_rad(actor_dir_old*90.0),deg_to_rad(actor_dir_new*90.0) , dur  )
	$Camera3D.rotation.y = a

# dur : 0 - 1 :second
func turn_left(dur :float)->void:
	var a = lerp_angle( deg_to_rad(actor_dir_old*90.0),deg_to_rad(actor_dir_new*90.0) , dur  )
	$Camera3D.rotation.y = a
