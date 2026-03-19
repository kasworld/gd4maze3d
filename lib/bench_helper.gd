class_name BenchHelper

var count :int
var start_time :float
var dur_sec :float
var val_per_sec :float

func _init() -> void:
	start_time = Time.get_unix_time_from_system()

func end(count_a = 0) -> void:
	count = int(count_a)
	dur_sec = Time.get_unix_time_from_system() - start_time
	val_per_sec = count / dur_sec

func _to_string() -> String:
	return "count %d, %f sec, %f count/sec" % [count , dur_sec, val_per_sec ]
