class_name PlacedThings

var data :Array[Array] # [y][x]node

func init(w :int, h :int) -> PlacedThings:
	data.clear()
	data.resize(h)
	for y in data:
		y.resize(w)
	return self

func get_at(x :int, y:int) :
	return data[y][x]

func set_at(x :int, y:int, v):
	var old = data[y][x]
	data[y][x] = v
	return old
