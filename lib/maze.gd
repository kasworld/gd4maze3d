class_name Maze

enum {
	N = 1,
	S = 2,
	E = 4,
	W = 8,
}

const Dir2Vt = {
	N : Vector2i.UP,
	S : Vector2i.DOWN,
	E : Vector2i.RIGHT,
	W : Vector2i.LEFT,
}

var cells : Array[PackedInt32Array]
var maze_size : Vector2i
func _init(msize :Vector2i)->void:
	maze_size = msize
	cells.resize(maze_size.x)
	for cl in cells:
		cl.resize(maze_size.y)

# make random data
func make_random()->void:
	for x in maze_size.x :
		for y in maze_size.y:
			if randi_range(0,1)==0:
				cells[x][y] = N
			if randi_range(0,1)==0:
				cells[x][y] |= E

	add_Hline_wall(0,maze_size.x,0, N)
	add_Hline_wall(0,maze_size.x,maze_size.y-1, S)
	add_Vline_wall(0,maze_size.y,0, E)
	add_Vline_wall(0,maze_size.y,maze_size.x-1, W)
	nomalize()

func get_wall_at(x :int, y :int)->Array:
	var rtn = []
	for k in Dir2Vt.keys():
		if cells[x][y] & k != 0 :
			rtn.append(k)
	return rtn

func add_wall_at(x :int, y :int, dir :int)->void:
	cells[x][y] |= dir

func set_wall_at(x :int, y :int, dir :int)->void:
	cells[x][y] = dir

func add_Hline_wall(x1:int, x2:int , y:int, dir :int)->void:
	for x in range(x1,x2):
		cells[x][y] |= dir

func add_Vline_wall(y1:int, y2:int , x:int, dir :int)->void:
	for y in range(y1,y2):
		cells[x][y] |= dir

func set_Hline_wall(x1:int, x2:int , y:int, dir :int)->void:
	for x in range(x1,x2):
		cells[x][y] = dir

func set_Vline_wall(y1:int, y2:int , x:int, dir :int)->void:
	for y in range(y1,y2):
		cells[x][y] = dir

# fix wall
func nomalize()->void:
	for x in maze_size.x-1:
		for y in maze_size.y-1:
			if W in get_wall_at(x,y):
				add_wall_at(x+1,y, E)
			elif E in get_wall_at(x+1,y):
				add_wall_at(x,y, W)
			if S in get_wall_at(x,y):
				add_wall_at(x,y+1, N)
			elif N in get_wall_at(x,y+1):
				add_wall_at(x,y, S)

