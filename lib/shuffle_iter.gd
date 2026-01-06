class_name ShuffleIter

var iter_data :Array
var curser :int

func _init(list :Array) -> void:
	iter_data = list.duplicate()
	shuffle()

func shuffle() -> ShuffleIter:
	iter_data.shuffle()
	curser = 0
	return self

func is_new_start() -> bool:
	return curser == 0

func next() -> void:
	curser += 1
	curser %= iter_data.size()
	if is_new_start():
		shuffle()

func get_current() -> Variant:
	return iter_data[curser]

func get_next() -> Variant:
	var rtn = get_current()
	next()
	return rtn
