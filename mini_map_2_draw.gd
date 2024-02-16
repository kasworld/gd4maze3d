extends Node2D

class_name MiniMap2Draw

const Scale = 20
var storey :Storey
func get_width()->int:
	return storey.maze_size.x * Scale
func get_height()->int:
	return storey.maze_size.y * Scale

# cell wall[y*2+1][x*2+1]
# wall wall[y*2][x*2]
var walls : Array[PackedByteArray]
func calc_wall_pos(x :int, y:int, dir :Storey.Dir)->Vector2i:
	return Vector2i(x*2+1,y*2+1) + Storey.Dir2Vt[dir]
func is_wall_at(x :int, y:int, dir :Storey.Dir)->bool:
	var wpos = calc_wall_pos(x,y,dir)
	return walls[wpos.y][wpos.x] != 0
func set_wall_at(x :int, y:int, dir :Storey.Dir):
	var wpos = calc_wall_pos(x,y,dir)
	walls[wpos.y][wpos.x] = 1

var player :Line2D
func move_player(x:int, y:int)->void:
	player.position = Vector2(x,y)*Scale

func init(st :Storey)->void:
	storey = st
	add_point_at(storey.goal_pos.x,storey.goal_pos.y, Color.RED)
	add_point_at(storey.start_pos.x,storey.start_pos.y, Color.YELLOW)
	player = add_point_at(storey.start_pos.x,storey.start_pos.y, Color.GREEN)
	walls.resize(storey.maze_size.y*2+1)
	for cl in walls:
		cl.resize(storey.maze_size.x*2+1)

func add_wall_at(x:int,y :int, dir :Storey.Dir)->void:
	if is_wall_at(x,y,dir):
		return
	set_wall_at(x,y,dir)
	var ln :Line2D
	match dir:
		Storey.Dir.North:
			ln = new_line( 2, Color.WHITE, [Vector2(x,y)*Scale,Vector2(x+1,y)*Scale])
		Storey.Dir.West:
			ln = new_line( 2, Color.WHITE, [Vector2(x,y)*Scale,Vector2(x,y+1)*Scale])
		Storey.Dir.South:
			ln = new_line( 2, Color.WHITE, [Vector2(x,y+1)*Scale,Vector2(x+1,y+1)*Scale])
		Storey.Dir.East:
			ln = new_line( 2, Color.WHITE, [Vector2(x+1,y)*Scale,Vector2(x+1,y+1)*Scale])
	add_child(ln)

# between wall
func add_point_at(x:int,y :int, co:Color)->Line2D:
	var ln = new_line(Scale*0.8 , co, [Vector2(0.1,0.5)*Scale,Vector2(0.9,0.5)*Scale] )
	add_child(ln)
	ln.position = Vector2(x,y)*Scale
	return ln

func new_line(w :float, co:Color, pos_list :PackedVector2Array)->Line2D:
	var ln = Line2D.new()
	ln.points = pos_list
	ln.default_color = co
	ln.width = w
	return ln
