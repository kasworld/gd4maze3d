class_name Maze

enum {
	N = 1,
	S = 2,
	E = 4,
	W = 8,
}

const Opppsite = {
	N : S,
	S : N,
	E : W,
	W : E,
}

const Dir2Vt = {
	N : Vector2i(0,-1),
	S : Vector2i(0, 1),
	E : Vector2i(-1,0),
	W : Vector2i( 1,0),
}

# opened dir NOT wall
var cells : Array[PackedInt32Array]
var maze_size : Vector2i
func _init(msize :Vector2i)->void:
	maze_size = msize
	cells.resize(maze_size.x)
	for cl in cells:
		cl.resize(maze_size.y)

func is_in(x:int,y:int)->bool:
	return x >=0 && y>=0 && x < maze_size.x && y < maze_size.y

# make random data
func make_random()->void:
	for x in maze_size.x :
		for y in maze_size.y:
			if randi_range(0,1)==0:
				cells[x][y] = N
			if randi_range(0,1)==0:
				cells[x][y] |= E
	nomalize()

var visted_pos : Array[Vector2i]
func select_visited()->int:
	if randi_range(0,1)==0:
		return visted_pos.size()-1
	else:
		return randi_range(0,visted_pos.size()-1)

func make_maze()->void:
	visted_pos =[]
	var pos = Vector2i( randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1),)
	visted_pos.append(pos)
	while visted_pos.size() > 0:
		var posidx = select_visited()
		pos = visted_pos[posidx]
		var delpos = true
		var rnddir = [N,S,E,W]
		rnddir.shuffle()
		for dir in rnddir:
			var npos = pos + Dir2Vt[dir]
			if is_in(npos.x,npos.y) && cells[npos.x][npos.y]==0:
				cells[pos.x][pos.y] |= dir
				cells[npos.x][npos.y] |= Opppsite[dir]
				visted_pos.append(npos)
				delpos = false
				break
		if delpos:
			visted_pos.remove_at(posidx)

func is_open_dir_at(x :int, y :int, dir :int)->bool:
	return (cells[x][y] & dir) !=0

func add_open_at(x :int, y :int, dir :int)->void:
	cells[x][y] |= dir

func set_open_at(x :int, y :int, dir :int)->void:
	cells[x][y] = dir

func add_Hline_open(x1:int, x2:int , y:int, dir :int)->void:
	for x in range(x1,x2):
		cells[x][y] |= dir

func add_Vline_open(y1:int, y2:int , x:int, dir :int)->void:
	for y in range(y1,y2):
		cells[x][y] |= dir

func set_Hline_open(x1:int, x2:int , y:int, dir :int)->void:
	for x in range(x1,x2):
		cells[x][y] = dir

func set_Vline_open(y1:int, y2:int , x:int, dir :int)->void:
	for y in range(y1,y2):
		cells[x][y] = dir

# fix open
func nomalize()->void:
	for x in maze_size.x-1:
		for y in maze_size.y-1:
			if is_open_dir_at(x,y,W):
				add_open_at(x+1,y, E)
			elif is_open_dir_at(x+1,y,E):
				add_open_at(x,y, W)
			if is_open_dir_at(x,y,S):
				add_open_at(x,y+1, N)
			elif is_open_dir_at(x,y+1,N):
				add_open_at(x,y, S)

