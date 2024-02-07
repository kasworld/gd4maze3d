class_name Maze

enum Dir {
	North = 1,
	West = 2,
	South = 4,
	East = 8,
}
const DirList = [Dir.North,Dir.West,Dir.South,Dir.East]
const Dir2Str = {
	Dir.North : "North",
	Dir.South : "South",
	Dir.East : "East",
	Dir.West : "West",
}
const Opppsite = {
	Dir.North : Dir.South,
	Dir.South : Dir.North,
	Dir.East : Dir.West,
	Dir.West : Dir.East,
}
const TurnLeft = {
	Dir.North : Dir.West,
	Dir.West : Dir.South,
	Dir.South : Dir.East,
	Dir.East : Dir.North,
}
const TurnRight = {
	Dir.North : Dir.East,
	Dir.East : Dir.South,
	Dir.South : Dir.West,
	Dir.West : Dir.North,
}
const Dir2Vt = {
	Dir.North : Vector2i(0,-1),
	Dir.South : Vector2i(0, 1),
	Dir.East : Vector2i(1,0),
	Dir.West : Vector2i(-1,0),
}

# opened dir NOT wall
var _cells : Array[PackedInt32Array]
var _maze_size : Vector2i
func _init(msize :Vector2i)->void:
	_maze_size = msize
	_cells.resize(_maze_size.y)
	for cl in _cells:
		cl.resize(_maze_size.x)

var visted_pos : Array[Vector2i]
func select_visited()->int:
	if randi_range(0,1)==0:
		return visted_pos.size()-1
	else:
		return randi_range(0,visted_pos.size()-1)

func make_maze()->void:
	visted_pos =[]
	var pos = Vector2i( randi_range(0,_maze_size.x-1),randi_range(0,_maze_size.y-1),)
	visted_pos.append(pos)
	while visted_pos.size() > 0:
		var posidx = select_visited()
		pos = visted_pos[posidx]
		var delpos = true
		var rnddir = [Dir.North,Dir.South,Dir.East,Dir.West]
		rnddir.shuffle()
		for dir in rnddir:
			var npos = pos + Dir2Vt[dir]
			if is_in(npos.x,npos.y) && get_cell(npos.x,npos.y)==0:
				or_cell(pos.x,pos.y, dir)
				or_cell(npos.x,npos.y, Opppsite[dir])
				visted_pos.append(npos)
				delpos = false
				break
		if delpos:
			visted_pos.remove_at(posidx)

func is_in(x:int,y:int)->bool:
	return x >=0 && y>=0 && x < _maze_size.x && y < _maze_size.y

func get_cell(x :int, y:int)->int:
	return _cells[y][x]

func or_cell(x:int,y:int, d :int)->void:
	_cells[y][x] |= d

func is_open_dir_at(x :int, y :int, dir :Dir)->bool:
	return (_cells[y][x] & dir) !=0

func get_open_dir_at(x :int, y :int)->Array:
	var rtn = []
	for d in DirList:
		if (_cells[y][x] & d) !=0:
			rtn.append(d)
	return rtn
