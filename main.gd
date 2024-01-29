extends Node3D

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
	maze_cells = Maze.new(maze_size)
	maze_cells.make_random()
	make_wall_by_maze()
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
		$Label.text = "%s (%d, %d) %s" % [Act.keys()[action], actor_pos_new.x, actor_pos_new.y , Dir.keys()[actor_dir_new] ]
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
				Dir.North:
					actor_pos_new.y = actor_pos_old.y -1
				Dir.East:
					actor_pos_new.x = actor_pos_old.x -1
				Dir.South:
					actor_pos_new.y = actor_pos_old.y +1
				Dir.West:
					actor_pos_new.x = actor_pos_old.x +1
		Act.Turn_Left:
			actor_dir_new = (actor_dir_old +1)%4
		Act.Turn_Right:
			actor_dir_new = (actor_dir_old -1+4)%4


	#$Camera3D.rotate_y(delta/2)

func make_wall_by_maze()->void:
	for y in maze_size.y:
		for x in maze_size.x :
			var c = maze_cells.get_cell(x,y)
			var dirs = maze_cells.get_cell_dirs(c)
			if Maze.N in dirs:
				add_wall_at( x - maze_size.x/2, y - maze_size.y/2, false)
			if Maze.E in dirs:
				add_wall_at( x - maze_size.x/2, y - maze_size.y/2, true)

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
