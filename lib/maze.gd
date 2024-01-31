class_name Maze

enum Dir {
	North = 1,
	South = 2,
	East = 4,
	West = 8,
}

const Opppsite = {
	Dir.North : Dir.South,
	Dir.South : Dir.North,
	Dir.East : Dir.West,
	Dir.West : Dir.East,
}

const DirList = [Dir.North,Dir.South,Dir.East,Dir.West]

const Dir2Vt = {
	Dir.North : Vector2i(0,-1),
	Dir.South : Vector2i(0, 1),
	Dir.East : Vector2i(-1,0),
	Dir.West : Vector2i( 1,0),
}

# opened dir NOT wall
var cells : Array[PackedInt32Array]
var maze_size : Vector2i
func _init(msize :Vector2i)->void:
	maze_size = msize
	cells.resize(maze_size.x)
	for cl in cells:
		cl.resize(maze_size.y)

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
		var rnddir = [Dir.North,Dir.South,Dir.East,Dir.West]
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

func is_in(x:int,y:int)->bool:
	return x >=0 && y>=0 && x < maze_size.x && y < maze_size.y

func is_open_dir_at(x :int, y :int, dir :Dir)->bool:
	return (cells[x][y] & dir) !=0

func get_open_dir_at(x :int, y :int)->Array:
	var rtn = []
	for d in DirList:
		if (cells[x][y] & d) !=0:
			rtn.append(d)
	return rtn
