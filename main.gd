extends Node3D

const ACT_DUR = 1.0 # sec
enum Act {Stop, Forward, Turn_Right , Turn_Left}

var action :Act
var act_start_time :float # unixtime sec
var actor_dir_old : Maze.Dir
var actor_dir_new : Maze.Dir
var actor_pos_old :Vector2i
var actor_pos_new :Vector2i

var maze_size = Vector2i(32,32)

func _ready() -> void:
	$MazeStorey.init(maze_size)
	actor_pos_old = maze_size/2
	actor_pos_new = maze_size/2
	actor_dir_old = Maze.Dir.North
	actor_dir_new = Maze.Dir.North
	move_forward(0)
	act_start_time = Time.get_unix_time_from_system()

func _process(delta: float) -> void:
	var t = Time.get_unix_time_from_system()
	var dur = t - act_start_time
	if dur > ACT_DUR :
		actor_dir_old = actor_dir_new
		actor_pos_old = actor_pos_new
		act_start_time = t
		act_random()
		$Label.text = "%s (%d, %d) %s" % [Act.keys()[action], actor_pos_new.x, actor_pos_new.y , Maze.Dir2Str[actor_dir_new] ]
	else:
		do_action(dur/ACT_DUR)

func act_random()->void:
	if randi_range(0,1)==0:
		action = Act.Forward
	elif randi_range(0,1)==0:
		action = Act.Turn_Left
	else:
		action = Act.Turn_Right
	start_action(action)


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

func can_move(dir :Maze.Dir)->bool:
	return $MazeStorey.can_move(actor_pos_old.x,actor_pos_old.y, dir)

func start_action(a :Act)->void:
	match a:
		Act.Stop:
			pass
		Act.Forward:
			if not can_move(actor_dir_old):
				print_debug("act blocked %s" % [ Maze.Dir2Str[actor_dir_old] ])
				return
			actor_pos_new = actor_pos_old + Maze.Dir2Vt[actor_dir_old]
		Act.Turn_Left:
			actor_dir_new = Maze.TurnLeft[actor_dir_old]
		Act.Turn_Right:
			actor_dir_new = Maze.TurnRight[actor_dir_old]


# dur : 0 - 1 :second
func move_forward(dur :float)->void:
	var vt = Vector3(
		0.5+ lerpf(actor_pos_old.x , actor_pos_new.x , dur ) ,
		1,
		0.5+ lerpf(actor_pos_old.y , actor_pos_new.y , dur ) ,
	)
	$PlayerCamera3D.position = vt

# dur : 0 - 1 :second
func turn_right(dur :float)->void:
	var a = lerp_angle( deg_to_rad(actor_dir_old*90.0),deg_to_rad(actor_dir_new*90.0) , dur  )
	$PlayerCamera3D.rotation.y = a

# dur : 0 - 1 :second
func turn_left(dur :float)->void:
	var a = lerp_angle( deg_to_rad(actor_dir_old*90.0),deg_to_rad(actor_dir_new*90.0) , dur  )
	$PlayerCamera3D.rotation.y = a

func set_top_view()->void:
	$PlayerCamera3D.current = false
	$MazeStorey.set_top_view(true)

func set_player_view()->void:
	$PlayerCamera3D.current = true
	$MazeStorey.set_top_view(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_1:
			set_top_view()
		elif event.keycode == KEY_2:
			set_player_view()
		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass

