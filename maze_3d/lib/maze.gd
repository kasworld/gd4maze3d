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
	North = 1 << Dir.North,
	West = 1 << Dir.West,
	South = 1 << Dir.South,
	East = 1 << Dir.East,
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

# Main function to get all permutations as an array of arrays
static func generate_all_permutations(array :Array) -> Array:
	var output :Array = []
	_recursive_permutation_helper(array, 0, output)
	return output

# Recursive helper function
static func _recursive_permutation_helper(array :Array, start_index :int, output :Array) -> void:
	if start_index == array.size():
		# Base case: a complete permutation is found, add it to the output
		# Use .duplicate(true) to ensure a deep copy if elements are complex objects/arrays
		output.append(array.duplicate())
		return

	for i in range(start_index, array.size()):
		# Swap current element with the element at the start index
		#array.swap(start_index, i)
		var tmp = array[start_index]
		array[start_index] = array[i]
		array[i] = tmp

		# Recurse for the next index
		_recursive_permutation_helper(array, start_index + 1, output)

		# Backtrack: swap them back to restore the original array state for the next iteration
		#array.swap(start_index, i)
		tmp = array[start_index]
		array[start_index] = array[i]
		array[i] = tmp

static var FlagPermutation :Array
static var DirPermutation :Array
static func _static_init() -> void:
	FlagPermutation = generate_all_permutations(FlagList.duplicate())
	DirPermutation = generate_all_permutations(DirList.duplicate())
	#print_debug(FlagPermutation, DirPermutation)

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
	var visted_pos :Array[Vector2i] = []
	var pos := Vector2i( randi_range(0,width-1),randi_range(0,height-1),)
	visted_pos.append(pos)
	while visted_pos.size() > 0:
		var posidx := _select_visited(visted_pos)
		pos = visted_pos[posidx]
		var pos_x := pos.x
		var pos_y := pos.y
		var delpos := true
		for dir in FlagPermutation.pick_random():
			var npos :Vector2i = pos + Maze.FlagToVt2[dir]
			var npos_x := npos.x
			var npos_y := npos.y
			if is_in(npos_x,npos_y) && get_cell(npos_x,npos_y)==0:
				_open_dir_at(pos_x,pos_y, dir)
				_open_dir_at(npos_x,npos_y, Maze.FlagOpppsite[dir])
				visted_pos.append(npos)
				delpos = false
				break
		if delpos:
			visted_pos.remove_at(posidx)

func is_in(x :int,y :int) -> bool:
	return x >=0 && y>=0 && x < width && y < height

func get_cell(x :int, y:int) -> int:
	return _cells[y*width+x]

func is_open_dir_at(x :int, y :int, dir :Maze.Flag) -> bool:
	return (_cells[y*width+x] & dir) != 0

func get_open_dir_at(x :int, y :int) -> Array[Maze.Flag]:
	var v := _cells[y*width+x]
	var rtn :Array[Maze.Flag] = []
	for d in Maze.FlagList:
		if (v & d) != 0:
			rtn.append(d)
	return rtn

func is_wall_dir_at(x :int, y :int, dir :Maze.Flag) -> bool:
	return (_cells[y*width+x] & dir) == 0

func get_wall_dir_at(x :int, y :int) -> Array[Maze.Flag]:
	var v := _cells[y*width+x]
	var rtn :Array[Maze.Flag] = []
	for d in Maze.FlagList:
		if (v & d) == 0:
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
