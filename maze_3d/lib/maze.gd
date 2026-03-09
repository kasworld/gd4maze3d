class_name Maze

# start enum ##################################

static func RadianToDir(rad :float) -> Dir:
	var dir := snappedi(rad *2/PI, 1)
	dir = ((dir%4)+4)%4
	var dir2dir := [
		Dir.North, # Vector2i(0,-1),
		Dir.West,  # Vector2i(-1,0),
		Dir.South, # Vector2i(0,1),
		Dir.East,  # Vector2i(1,0),
	]
	return dir2dir[dir]

enum Dir {
	North = 0,
	West = 1,
	South = 2,
	East = 3,
}
const DirList = [Dir.North,Dir.West,Dir.South,Dir.East]

const DirToStr = {
	Dir.North : "North",
	Dir.West : "West",
	Dir.South : "South",
	Dir.East : "East",
}
const StrToDir = {
	 "North" : Dir.North ,
	 "West" : Dir.West ,
	 "South" : Dir.South ,
	 "East" : Dir.East ,
}

const DirOpppsite = {
	Dir.North : Dir.South,
	Dir.West : Dir.East,
	Dir.South : Dir.North,
	Dir.East : Dir.West,
}
const DirTurnLeft = {
	Dir.North : Dir.West,
	Dir.West : Dir.South,
	Dir.South : Dir.East,
	Dir.East : Dir.North,
}
const DirTurnRight = {
	Dir.North : Dir.East,
	Dir.East : Dir.South,
	Dir.South : Dir.West,
	Dir.West : Dir.North,
}

const DirToVt2 = {
	Dir.North : Vector2i(0,-1),
	Dir.West : Vector2i(-1,0),
	Dir.South : Vector2i(0, 1),
	Dir.East : Vector2i(1,0),
}
const Vt2ToDir = {
	 Vector2i(0,-1) : Dir.North,
	 Vector2i(-1,0) : Dir.West,
	 Vector2i(0, 1) : Dir.South,
	 Vector2i(1,0) : Dir.East,
}

static func DirToRadian(d:Dir) -> float:
	return deg_to_rad(d *90.0)

enum Flag {
	North = 1 << Dir.North,
	West = 1 << Dir.West,
	South = 1 << Dir.South,
	East = 1 << Dir.East,
}
const FlagList = [Flag.North,Flag.West,Flag.South,Flag.East]

const FlagToDir = {
	Flag.North : Dir.North,
	Flag.West : Dir.West,
	Flag.South : Dir.South,
	Flag.East : Dir.East,
}
const DirToFlag = {
	Dir.North : Flag.North,
	Dir.West : Flag.West,
	Dir.South : Flag.South,
	Dir.East : Flag.East,
}
const FlagToStr = {
	Flag.North : "North",
	Flag.West : "West",
	Flag.South : "South",
	Flag.East : "East",
}
const StrToFlag = {
	 "North" : Flag.North ,
	 "West" : Flag.West ,
	 "South" : Flag.South ,
	 "East" : Flag.East ,
}

const FlagOpppsite = {
	Flag.North : Flag.South,
	Flag.West : Flag.East,
	Flag.South : Flag.North,
	Flag.East : Flag.West,
}
const FlagTurnLeft = {
	Flag.North : Flag.West,
	Flag.West : Flag.South,
	Flag.South : Flag.East,
	Flag.East : Flag.North,
}
const FlagTurnRight = {
	Flag.North : Flag.East,
	Flag.East : Flag.South,
	Flag.South : Flag.West,
	Flag.West : Flag.North,
}
const FlagToVt2 = {
	Flag.North : Vector2i(0,-1),
	Flag.West : Vector2i(-1,0),
	Flag.South : Vector2i(0, 1),
	Flag.East : Vector2i(1,0),
}
const Vt2ToFlag = {
	 Vector2i(0,-1) : Flag.North,
	 Vector2i(-1,0) : Flag.West,
	 Vector2i(0, 1) : Flag.South,
	 Vector2i(1,0) : Flag.East,
}

# end enum ###########################


# opened dir NOT wall
var _cells : PackedByteArray
var width :int
var height :int

func _select_visited(visted_pos :Array) -> int:
	if randi_range(0,1)==0:
		return visted_pos.size()-1
	else:
		return randi_range(0,visted_pos.size()-1)

func _open_dir_at(x:int,y:int, d :int) -> void:
	_cells[y*width+x] |= d

func _init(msize :Vector2i) -> void:
	width = msize.x
	height = msize.y
	_cells.resize(height*width)
	var visted_pos := []
	var pos := Vector2i( randi_range(0,width-1),randi_range(0,height-1),)
	visted_pos.append(pos)
	while visted_pos.size() > 0:
		var posidx := _select_visited(visted_pos)
		pos = visted_pos[posidx]
		var delpos := true
		var rnddir := Maze.FlagList.duplicate()
		rnddir.shuffle()
		for dir in rnddir:
			var npos :Vector2i = pos + Maze.FlagToVt2[dir]
			if is_in(npos.x,npos.y) && get_cell(npos.x,npos.y)==0:
				_open_dir_at(pos.x,pos.y, dir)
				_open_dir_at(npos.x,npos.y, Maze.FlagOpppsite[dir])
				visted_pos.append(npos)
				delpos = false
				break
		if delpos:
			visted_pos.remove_at(posidx)

func is_in(x:int,y:int) -> bool:
	return x >=0 && y>=0 && x < width && y < height

func get_cell(x :int, y:int) -> int:
	return _cells[y*width+x]

func is_open_dir_at(x :int, y :int, dir :Maze.Flag) -> bool:
	return (_cells[y*width+x] & dir) != 0

func get_open_dir_at(x :int, y :int) -> Array[Maze.Flag]:
	var rtn :Array[Maze.Flag] = []
	for d in Maze.FlagList:
		if is_open_dir_at(x,y,d):
			rtn.append(d)
	return rtn

func is_wall_dir_at(x :int, y :int, dir :Maze.Flag) -> bool:
	return (_cells[y*width+x] & dir) == 0

## enumdir order : North West South East
func get_wall_alldir_at(x :int, y :int) -> Array[bool]:
	var v := _cells[y*width+x]
	return [
		(v & Maze.Flag.North) == 0,
		(v & Maze.Flag.West) == 0,
		(v & Maze.Flag.South) == 0,
		(v & Maze.Flag.East) == 0,
	]

func get_wall_dir_at(x :int, y :int) -> Array[Maze.Flag]:
	var rtn :Array[Maze.Flag] = []
	for d in Maze.FlagList:
		if is_wall_dir_at(x,y,d):
			rtn.append(d)
	return rtn

func open_dir_str(x :int , y :int) -> String:
	var rtn := ""
	for d in get_open_dir_at(x,y):
		rtn += "%s " %[Maze.FlagToStr[d]]
	return rtn

# from_pos -> [ {"pos" : to_pos, "dir" : dir} ]
func make_move_graph() -> Dictionary:
	var rtn := {}
	for y in height:
		for x in width:
			var val := []
			var srcpos := Vector2i(x,y)
			for fdir in get_open_dir_at(x,y):
				var topos :Vector2i = srcpos + Maze.FlagToVt2[fdir]
				val.append({"pos":topos, "dir": Maze.FlagToStr[fdir] })
			rtn[srcpos] = val
	return rtn
