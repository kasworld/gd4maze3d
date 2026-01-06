class_name AnimateGradient

static func random_color() -> Color:
	return NamedColorList.color_list.pick_random()[0]

var color_fn :Callable

func _init(color_fn_a :Callable = random_color) -> void:
	set_color_fn(color_fn_a)
	color_list = [color_fn.call(),color_fn.call()]

func set_color_fn(color_fn_a :Callable) -> AnimateGradient:
	color_fn = color_fn_a
	return self

var color_list :Array
var color_rate :float

func inc_rate(v :float = 1.0/60.0) -> void:
	color_rate += v
	if color_rate >= 1:
		start_new()

func start_new() -> void:
	color_rate = 0
	color_list = [color_list[1], color_fn.call()]

func is_new_started() -> bool:
	return color_rate == 0

func get_color() -> Color:
		return lerp(color_list[0], color_list[1], color_rate)
