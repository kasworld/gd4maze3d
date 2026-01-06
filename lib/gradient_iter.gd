class_name GradientIter

var color_from :Color
var color_to :Color
var count :int
var cursor :int

func _init(co1 :Color, co2 :Color, count_a :int) -> void:
	color_from = co1
	color_to = co2
	count = count_a

func calc_progress() -> float:
	return float(cursor)/float(count-1)

func get_cursor() -> int:
	return cursor

func get_current_color() -> Color:
	return color_from.lerp(color_to, calc_progress())

func move_next() -> void:
	cursor +=1

func end_reached() -> bool:
	return cursor >= count
