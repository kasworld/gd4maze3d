class_name Maze

# opened dir NOT wall
var _cells : Array[PackedInt32Array]
var _maze_size : Vector2i

func _select_visited(visted_pos :Array) -> int:
	if randi_range(0,1)==0:
		return visted_pos.size()-1
	else:
		return randi_range(0,visted_pos.size()-1)

func _open_dir_at(x:int,y:int, d :int) -> void:
	_cells[y][x] |= d

func _init(msize :Vector2i) -> void:
	_maze_size = msize
	_cells.resize(_maze_size.y)
	for cl in _cells:
		cl.resize(_maze_size.x)
	var visted_pos := []
	var pos := Vector2i( randi_range(0,_maze_size.x-1),randi_range(0,_maze_size.y-1),)
	visted_pos.append(pos)
	while visted_pos.size() > 0:
		var posidx := _select_visited(visted_pos)
		pos = visted_pos[posidx]
		var delpos := true
		var rnddir := EnumDir.FlagList.duplicate()
		rnddir.shuffle()
		for dir in rnddir:
			var npos :Vector2i = pos + EnumDir.FlagToVt2[dir]
			if is_in(npos.x,npos.y) && get_cell(npos.x,npos.y)==0:
				_open_dir_at(pos.x,pos.y, dir)
				_open_dir_at(npos.x,npos.y, EnumDir.FlagOpppsite[dir])
				visted_pos.append(npos)
				delpos = false
				break
		if delpos:
			visted_pos.remove_at(posidx)

func is_in(x:int,y:int) -> bool:
	return x >=0 && y>=0 && x < _maze_size.x && y < _maze_size.y

func get_cell(x :int, y:int) -> int:
	return _cells[y][x]

func is_open_dir_at(x :int, y :int, dir :EnumDir.Flag) -> bool:
	return (_cells[y][x] & dir) != 0

func get_open_dir_at(x :int, y :int) -> Array[EnumDir.Flag]:
	var rtn :Array[EnumDir.Flag] = []
	for d in EnumDir.FlagList:
		if is_open_dir_at(x,y,d):
			rtn.append(d)
	return rtn

func is_wall_dir_at(x :int, y :int, dir :EnumDir.Flag) -> bool:
	return (_cells[y][x] & dir) == 0

func get_wall_dir_at(x :int, y :int) -> Array[EnumDir.Flag]:
	var rtn :Array[EnumDir.Flag] = []
	for d in EnumDir.FlagList:
		if is_wall_dir_at(x,y,d):
			rtn.append(d)
	return rtn

func open_dir_str(x :int , y :int) -> String:
	var rtn := ""
	for d in get_open_dir_at(x,y):
		rtn += "%s " %[EnumDir.FlagToStr[d]]
	return rtn

# wall [axis:3][2]bool : [ [-x,+x], [-y,+y], [-z,+z] ]
func make_wallinfo_for_bounce(x:int, y:int) -> Array[Array]:
	return [
		[is_wall_dir_at(x,y, EnumDir.Flag.West), is_wall_dir_at(x,y, EnumDir.Flag.East)],
		[true,true],
		[is_wall_dir_at(x,y, EnumDir.Flag.North), is_wall_dir_at(x,y, EnumDir.Flag.South)],
	]

# from_pos -> [ {"pos" : to_pos, "dir" : dir} ]
func make_move_graph() -> Dictionary:
	var rtn := {}
	for y in _cells.size():
		for x in _cells[y].size():
			var val := []
			var srcpos := Vector2i(x,y)
			for fdir in get_open_dir_at(x,y):
				var topos :Vector2i = srcpos + EnumDir.FlagToVt2[fdir]
				val.append({"pos":topos, "dir": EnumDir.FlagToStr[fdir] })
			rtn[srcpos] = val
	return rtn
