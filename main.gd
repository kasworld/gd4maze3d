extends Node3D

const ACT_DUR = 1.0 # sec
enum Act {Stop, Forward, Turn_Right , Turn_Left}
enum Dir {North, East, South, West}
var wall_scene = preload("res://wall_z.tscn")

var action :Act
var act_start_time :float # unixtime sec
var actor_dir_old : Dir
var actor_dir_new : Dir
var actor_pos_old :Vector2i
var actor_pos_new :Vector2i

var maze_size = Vector2i(100,100)
var maze_cells :Maze

func _ready() -> void:
	$Floor.position.x = maze_size.x/2
	$Floor.position.z = maze_size.y/2
	$Ceiling.position.x = maze_size.x/2
	$Ceiling.position.z = maze_size.y/2
	$TopViewCamera3D.position.x = maze_size.x/2
	$TopViewCamera3D.position.z = maze_size.y/2
	actor_pos_old = maze_size/2
	actor_pos_new = maze_size/2

	maze_cells = Maze.new(maze_size)
	maze_cells.make_random()
	make_wall_by_maze()
	act_start_time = Time.get_unix_time_from_system()

func _process(delta: float) -> void:
	var t = Time.get_unix_time_from_system()
	var dur = t - act_start_time
	if dur > ACT_DUR :
		actor_dir_old = actor_dir_new
		actor_pos_old = actor_pos_new
		act_start_time = t
		action = randi_range(0,3) as Act
		start_action(action)
		$Label.text = "%s (%d, %d) %s" % [Act.keys()[action], actor_pos_new.x, actor_pos_new.y , Dir.keys()[actor_dir_new] ]
	else:
		do_action(dur/ACT_DUR)

func set_top_view()->void:
	$PlayerCamera3D.current = false
	$Ceiling.visible = false
	$TopViewCamera3D.current = true

func set_player_view()->void:
	$PlayerCamera3D.current = true
	$Ceiling.visible = true
	$TopViewCamera3D.current = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_ENTER:
			set_top_view()
		elif event.keycode == KEY_SPACE:
			set_player_view()
		else:
			pass

	elif event is InputEventMouseButton and event.is_pressed():
		pass


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

func can_move(dir :Dir)->bool:
	match dir:
		Dir.North:
			return actor_pos_old.y > 0
		Dir.East:
			return actor_pos_old.x > 0
		Dir.South:
			return actor_pos_old.y < maze_size.y -1
		Dir.West:
			return actor_pos_old.x < maze_size.x -1
	return false

func start_action(a :Act)->void:
	match a:
		Act.Stop:
			pass
		Act.Forward:
			if not can_move(actor_dir_old):
				print_debug("act blocked %s" % [ Dir.keys()[actor_dir_old] ])
				return
			match actor_dir_old:
				Dir.North:
					actor_pos_new.y = actor_pos_old.y -1
				Dir.East:
					actor_pos_new.x = actor_pos_old.x -1
				Dir.South:
					actor_pos_new.y = actor_pos_old.y +1
				Dir.West:
					actor_pos_new.x = actor_pos_old.x +1
		Act.Turn_Left:
			actor_dir_new = (actor_dir_old +1)%4 as Dir
		Act.Turn_Right:
			actor_dir_new = (actor_dir_old -1+4)%4 as Dir


	#$Camera3D.rotate_y(delta/2)

func make_wall_by_maze()->void:
	for y in maze_size.y:
		for x in maze_size.x :
			var c = maze_cells.get_cell(x,y)
			var dirs = maze_cells.get_cell_dirs(c)
			if Maze.N in dirs:
				add_wall_at( x , y , false)
			if Maze.E in dirs:
				add_wall_at( x , y , true)

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
	$PlayerCamera3D.position = vt
# dur : 0 - 1 :second
func turn_right(dur :float)->void:
	var a = lerp_angle( deg_to_rad(actor_dir_old*90.0),deg_to_rad(actor_dir_new*90.0) , dur  )
	$PlayerCamera3D.rotation.y = a

# dur : 0 - 1 :second
func turn_left(dur :float)->void:
	var a = lerp_angle( deg_to_rad(actor_dir_old*90.0),deg_to_rad(actor_dir_new*90.0) , dur  )
	$PlayerCamera3D.rotation.y = a
