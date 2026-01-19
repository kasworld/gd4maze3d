class_name PlacedThings

var data :Array[Array] # [y][x]node
var count :int

func _to_string() -> String:
	var rtn := ""
	for y in data:
		for x in y:
			rtn += "%s" % x
		rtn += "\n"
	return rtn

func _init( size :Vector2i) -> void:
	init(size)

func init(size :Vector2i) -> PlacedThings:
	data.clear()
	count = 0
	data.resize(size.y)
	for y in data:
		y.resize(size.x)
	return self

func get_width() -> int:
	return data[0].size()

func get_height() -> int:
	return data.size()

func get_at(pos :Vector2i) -> Variant:
	return data[pos.y][pos.x]

func set_at(pos :Vector2i, v :Variant) -> Variant:
	var old = data[pos.y][pos.x]
	data[pos.y][pos.x] = v
	if old == null:
		count +=1
	return old

func move(from :Vector2i, to :Vector2i) -> Variant:
	var from_data = del_at(from)
	assert(from_data != null, "empty move from %s -> %s" %[from, to] )
	var to_data = set_at(to, from_data)
	return to_data

func swap(pos1 :Vector2i, pos2 :Vector2i) -> void:
	var p1data = del_at(pos1)
	assert(p1data != null, "empty swap pos1 %s -> %s" %[pos1, pos2] )
	var p2data = set_at(pos2, p1data)
	assert(p2data != null, "empty swap pos2 %s -> %s" %[pos1, pos2] )
	set_at(pos1,p2data)
	# no return

func del_at(pos :Vector2i) -> Variant:
	var old = data[pos.y][pos.x]
	data[pos.y][pos.x] = null
	if old != null:
		count -=1
	return old

func rand_x(margin :int=1) -> int:
	return randi_range(margin,data[0].size()-1-margin)
func rand_y(margin :int=1) -> int:
	return randi_range(margin,data.size()-1-margin)
func rand2dpos(margin :int=1) -> Vector2i:
	return Vector2i( rand_x(margin), rand_y(margin) )
func find_empty_pos(trycount :int) -> Vector2i:
	for i in trycount:
		var pos := rand2dpos()
		if get_at(pos) == null:
			return pos
	return Vector2i(-1,-1)
