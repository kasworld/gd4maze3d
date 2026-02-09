class_name ListIter

var shuffle_flag :bool
var iter_data :Array
var curser :int

func _init(list :Array, shuffle_flag_a :bool = true) -> void:
	shuffle_flag = shuffle_flag_a
	iter_data = list.duplicate()
	shuffle()

func get_data(index :int) -> Variant:
	return iter_data[index % iter_data.size()]

func append_data(list :Array) -> void:
	iter_data.append_array(list.duplicate())
	shuffle()

func shuffle() -> ListIter:
	if shuffle_flag:
		iter_data.shuffle()
	reset_cursor()
	return self

func is_new_start() -> bool:
	return curser == 0

func reset_cursor() -> void:
	curser = 0

func get_progress_rate() -> float:
	return float(curser)/float(iter_data.size()-1)

func get_data_array() -> Array:
	return iter_data

func next() -> void:
	curser += 1
	curser %= iter_data.size()
	if is_new_start():
		shuffle()

func get_current() -> Variant:
	return iter_data[curser]

func get_current_and_step_next() -> Variant:
	var rtn = get_current()
	next()
	return rtn

func get_size() -> int:
	return iter_data.size()

func get_itered_slice() -> Array:
	return iter_data.slice(0,curser)

func get_unitered_slice() -> Array:
	return iter_data.slice(curser)
