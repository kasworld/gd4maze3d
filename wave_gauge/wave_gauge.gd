extends Node3D
class_name WaveGauge

static var color_list := [
	Color.RED, Color.YELLOW,
	Color.GOLD, Color.PINK,
	Color.GREEN, Color.BLUE,
	Color.CYAN, Color.MAGENTA,
]

var gauge_list :Array
var box_size :Vector3
var count :Vector3i
func init(sz :Vector3, counta :Vector3i, co_list :Array = color_list, gaprate :float = 0.5, alpha :float = 0.5) -> WaveGauge:
	box_size = sz
	count = counta
	var block_size := sz/ Vector3(count)
	var blockrate := 1.0-gaprate
	for i in count.x:
		var irate := float(i) / count.x
		for j in count.z:
			var jrate := float(j) / count.z
			var bg = preload("res://bar_gauge/bar_gauge.tscn").instantiate().init_bar_gauge(
				count.y, Vector3( block_size.x * blockrate, box_size.y, block_size.z * blockrate ),
				lerp( lerp(co_list[0], co_list[1], irate) , lerp(co_list[2], co_list[3], irate), jrate),
				lerp( lerp(co_list[4], co_list[5], irate) , lerp(co_list[6], co_list[7], irate), jrate),
				alpha,
				gaprate
				)
			bg.position = -box_size/2 + Vector3( block_size.x * i + block_size.x/2 , block_size.y/2 , block_size.z * j + block_size.z/2)
			gauge_list.append(bg)
			add_child(bg)
	return self

# for debug
func set_all_rate(rate :float = 1.0) -> void:
	for bg in gauge_list:
		bg.set_current_rate(rate)

func animate_wave(speed1 :float =2, speed2:float=3, len1 :float = PI, len2 :float = PI) -> void:
	var now := Time.get_unix_time_from_system()
	var nowspeed1 := now*speed1
	var nowspeed2 := now*speed2
	var len1x := len1 / count.x
	var len2z := len2 / count.z
	for i in count.x:
		var irate := float(i) * len1x
		for j in count.z:
			var jrate := float(j) * len2z
			var bg = gauge_list[i*count.z+j]
			bg.set_current_rate(
				((sin( nowspeed1 + irate ) + 1.0) / 4.0) +
				((cos( nowspeed2 + jrate ) + 1.0) / 4.0)
				)
