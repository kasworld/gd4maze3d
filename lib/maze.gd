class_name Maze


const N = 1
const S = 2
const E = 4
const W = 8

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
	for y in maze_size.x:
		for x in maze_size.y :
			cells[x][y] = randi_range(0,8)

func get_cell(x :int, y :int)->int:
	return cells[x][y]

func get_cell_dirs(c :int)->Array:
	var rtn = []
	for k in Dir2Vt.keys():
		if c & k != 0 :
			rtn.append(k)
	return rtn

func set_cell_dir(dir :int)->void:
	pass
