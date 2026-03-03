class_name Maze

# opened dir NOT wall
var _cells : PackedByteArray
#var _maze_size : Vector2i
var _w :int
var _h :int

func _select_visited(visted_pos :Array) -> int:
	if randi_range(0,1)==0:
		return visted_pos.size()-1
	else:
		return randi_range(0,visted_pos.size()-1)

func _open_dir_at(x:int,y:int, d :int) -> void:
	_cells[y*_w+x] |= d

func _init(msize :Vector2i) -> void:
	#_maze_size = msize
	_w = msize.x
	_h = msize.y
	_cells.resize(_h*_w)
	var visted_pos := []
	var pos := Vector2i( randi_range(0,_w-1),randi_range(0,_h-1),)
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
	return x >=0 && y>=0 && x < _w && y < _h

func get_cell(x :int, y:int) -> int:
	return _cells[y*_w+x]

func is_open_dir_at(x :int, y :int, dir :EnumDir.Flag) -> bool:
	return (_cells[y*_w+x] & dir) != 0

func get_open_dir_at(x :int, y :int) -> Array[EnumDir.Flag]:
	var rtn :Array[EnumDir.Flag] = []
	for d in EnumDir.FlagList:
		if is_open_dir_at(x,y,d):
			rtn.append(d)
	return rtn

func is_wall_dir_at(x :int, y :int, dir :EnumDir.Flag) -> bool:
	return (_cells[y*_w+x] & dir) == 0

## enumdir order : North West South East
func get_wall_alldir_at(x :int, y :int) -> Array[bool]:
	var v := _cells[y*_w+x]
	return [
		(v & EnumDir.Flag.North) == 0,
		(v & EnumDir.Flag.West) == 0,
		(v & EnumDir.Flag.South) == 0,
		(v & EnumDir.Flag.East) == 0,
	]

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


# from_pos -> [ {"pos" : to_pos, "dir" : dir} ]
func make_move_graph() -> Dictionary:
	var rtn := {}
	for y in _h:
		for x in _w:
			var val := []
			var srcpos := Vector2i(x,y)
			for fdir in get_open_dir_at(x,y):
				var topos :Vector2i = srcpos + EnumDir.FlagToVt2[fdir]
				val.append({"pos":topos, "dir": EnumDir.FlagToStr[fdir] })
			rtn[srcpos] = val
	return rtn
