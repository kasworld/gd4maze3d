class_name Maze

# start enum ##################################

static func RadianToDir(rad :float) -> Dir:
	var dir := snappedi(rad *2/PI, 1)
	dir = ((dir%4)+4)%4
	const dir2dir :Array[Dir]= [
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
const DirList :Array[Dir] = [Dir.North,Dir.West,Dir.South,Dir.East]

const DirToStr :Dictionary[Dir,String] = {
	Dir.North : "North",
	Dir.West : "West",
	Dir.South : "South",
	Dir.East : "East",
}
const StrToDir :Dictionary[String,Dir] = {
	 "North" : Dir.North ,
	 "West" : Dir.West ,
	 "South" : Dir.South ,
	 "East" : Dir.East ,
}

const DirOpppsite :Dictionary[Dir,Dir] = {
	Dir.North : Dir.South,
	Dir.West : Dir.East,
	Dir.South : Dir.North,
	Dir.East : Dir.West,
}
const DirTurnLeft :Dictionary[Dir,Dir] = {
	Dir.North : Dir.West,
	Dir.West : Dir.South,
	Dir.South : Dir.East,
	Dir.East : Dir.North,
}
const DirTurnRight :Dictionary[Dir,Dir] = {
	Dir.North : Dir.East,
	Dir.East : Dir.South,
	Dir.South : Dir.West,
	Dir.West : Dir.North,
}

const DirToVt2 :Dictionary[Dir,Vector2i] = {
	Dir.North : Vector2i(0,-1),
	Dir.West : Vector2i(-1,0),
	Dir.South : Vector2i(0, 1),
	Dir.East : Vector2i(1,0),
}
const Vt2ToDir :Dictionary[Vector2i,Dir] = {
	 Vector2i(0,-1) : Dir.North,
	 Vector2i(-1,0) : Dir.West,
	 Vector2i(0, 1) : Dir.South,
	 Vector2i(1,0) : Dir.East,
}

static func DirToRadian(d:Dir) -> float:
	return deg_to_rad(d *90.0)

enum Flag {
	North = 1 << Dir.North,	## 0b0001
	West = 1 << Dir.West,	## 0b0010
	South = 1 << Dir.South,	## 0b0100
	East = 1 << Dir.East,	## 0b1000
}
const FlagList :Array[Flag] = [Flag.North,Flag.West,Flag.South,Flag.East]

const FlagToDir :Dictionary[Flag,Dir] = {
	Flag.North : Dir.North,
	Flag.West : Dir.West,
	Flag.South : Dir.South,
	Flag.East : Dir.East,
}
const DirToFlag :Dictionary[Dir,Flag] = {
	Dir.North : Flag.North,
	Dir.West : Flag.West,
	Dir.South : Flag.South,
	Dir.East : Flag.East,
}
const FlagToStr :Dictionary[Flag,String] = {
	Flag.North : "North",
	Flag.West : "West",
	Flag.South : "South",
	Flag.East : "East",
}
const StrToFlag :Dictionary[String,Flag] = {
	 "North" : Flag.North ,
	 "West" : Flag.West ,
	 "South" : Flag.South ,
	 "East" : Flag.East ,
}

const FlagOpppsite :Dictionary[Flag,Flag] = {
	Flag.North : Flag.South,
	Flag.West : Flag.East,
	Flag.South : Flag.North,
	Flag.East : Flag.West,
}
const FlagTurnLeft :Dictionary[Flag,Flag] = {
	Flag.North : Flag.West,
	Flag.West : Flag.South,
	Flag.South : Flag.East,
	Flag.East : Flag.North,
}
const FlagTurnRight :Dictionary[Flag,Flag] = {
	Flag.North : Flag.East,
	Flag.East : Flag.South,
	Flag.South : Flag.West,
	Flag.West : Flag.North,
}
const FlagToVt2 :Dictionary[Flag,Vector2i] = {
	Flag.North : Vector2i(0,-1),
	Flag.West : Vector2i(-1,0),
	Flag.South : Vector2i(0, 1),
	Flag.East : Vector2i(1,0),
}
const Vt2ToFlag :Dictionary[Vector2i,Flag] = {
	 Vector2i(0,-1) : Flag.North,
	 Vector2i(-1,0) : Flag.West,
	 Vector2i(0, 1) : Flag.South,
	 Vector2i(1,0) : Flag.East,
}

static var FlagPermutation :Array
static func _static_init() -> void:
	FlagPermutation = Permutation.HeapLoop(FlagList.duplicate())

# end enum ###########################


# opened dir NOT wall
var _cells : PackedByteArray
var width :int
var height :int
var rect2i :Rect2i

func _open_flag_at(x:int,y:int, d :Flag) -> void:
	_cells[y*width+x] |= d

func _init(msize :Vector2i) -> void:
	rect2i = Rect2i(Vector2i.ZERO, msize)
	width = msize.x
	height = msize.y
	_cells.resize(height*width)
	var visted_pos :Array[Vector2i] = []
	var pos := Vector2i( randi_range(0,width-1),randi_range(0,height-1),)
	visted_pos.append(pos)
	while visted_pos.size() > 0:
		var posidx := visted_pos.size()-1 if randi()%2==0 else randi_range(0,visted_pos.size()-1)
		pos = visted_pos[posidx]
		var delpos := true
		for flag in FlagPermutation.pick_random():
			var npos :Vector2i = pos + FlagToVt2[flag]
			if rect2i.has_point(npos) && get_cell(npos.x,npos.y)==0:
				_open_flag_at(pos.x, pos.y, flag)
				_open_flag_at(npos.x, npos.y, FlagOpppsite[flag])
				visted_pos.append(npos)
				delpos = false
				break
		if delpos:
			visted_pos.remove_at(posidx)

#func is_in(x :int,y :int) -> bool:
	#return x >=0 && y>=0 && x < width && y < height

func get_cell(x :int, y:int) -> int:
	return _cells[y*width+x]

func is_open_flag_at(x :int, y :int, flag :Flag) -> bool:
	return (_cells[y*width+x] & flag) != 0

func get_open_dir_at(x :int, y :int) -> Array[Dir]:
	var v := _cells[y*width+x]
	var rtn :Array[Dir] = []
	for flag in FlagList:
		if (v & flag) != 0:
			rtn.append( FlagToDir[flag])
	return rtn

func get_open_flag_at(x :int, y :int) -> Array[Flag]:
	var v := _cells[y*width+x]
	var rtn :Array[Flag] = []
	for d in FlagList:
		if (v & d) != 0:
			rtn.append(d)
	return rtn

func is_wall_flag_at(x :int, y :int, flag :Flag) -> bool:
	return (_cells[y*width+x] & flag) == 0

func get_wall_dir_at(x :int, y :int) -> Array[Dir]:
	var v := _cells[y*width+x]
	var rtn :Array[Dir] = []
	for flag in FlagList:
		if (v & flag) == 0:
			rtn.append( FlagToDir[flag])
	return rtn

func get_wall_flag_at(x :int, y :int) -> Array[Flag]:
	var v := _cells[y*width+x]
	var rtn :Array[Flag] = []
	for d in FlagList:
		if (v & d) == 0:
			rtn.append(d)
	return rtn

func open_flag_str(x :int , y :int) -> String:
	var rtn := ""
	for d in get_open_flag_at(x,y):
		rtn += "%s " %[FlagToStr[d]]
	return rtn

# from_pos -> [ {"pos" : to_pos, "dir" : dir} ]
func make_move_graph() -> Dictionary:
	var rtn := {}
	for y in height:
		for x in width:
			var val := []
			var srcpos := Vector2i(x,y)
			for fdir in get_open_flag_at(x,y):
				var topos :Vector2i = srcpos + FlagToVt2[fdir]
				val.append({"pos":topos, "dir": FlagToStr[fdir] })
			rtn[srcpos] = val
	return rtn

func make_posi_list_by_open_count(open_count :int) -> Array[Vector2i]:
	var rtn :Array[Vector2i] = []
	for y in height:
		for x in width:
			if get_open_flag_at(x,y).size() == open_count:
				rtn.append(Vector2i(x,y))
	return rtn

## func fn_at(x :int, y :int, dir_flag :Maze.Flag) -> void:
func iter_wall(fn_at :Callable) -> void:
	if not fn_at.is_valid():
		return
	for y in height:
		for x in width:
			if is_wall_flag_at(x,y,Maze.Flag.North):
				fn_at.call(x, y, Maze.Flag.North)
			if is_wall_flag_at(x,y,Maze.Flag.West):
				fn_at.call(x, y, Maze.Flag.West)
	for x in width :
		if is_wall_flag_at(x,height-1,Maze.Flag.South):
			fn_at.call(x, height, Maze.Flag.South)
	for y in height:
		if is_wall_flag_at(width-1,y,Maze.Flag.East):
			fn_at.call(width, y, Maze.Flag.East)

## func fn_at(x :int, y :int, dir_flag :Maze.Flag) -> void:
func iter_open(fn_at :Callable) -> void:
	if not fn_at.is_valid():
		return
	for y in height:
		for x in width:
			if is_open_flag_at(x,y,Maze.Flag.North):
				fn_at.call(x, y, Maze.Flag.North)
			if is_open_flag_at(x,y,Maze.Flag.West):
				fn_at.call(x, y, Maze.Flag.West)
	for x in width :
		if is_open_flag_at(x,height-1,Maze.Flag.South):
			fn_at.call(x, height, Maze.Flag.South)
	for y in height:
		if is_open_flag_at(width-1,y,Maze.Flag.East):
			fn_at.call(width, y, Maze.Flag.East)
