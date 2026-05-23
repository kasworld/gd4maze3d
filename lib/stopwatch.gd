class_name StopWatch

## array of [name, time]
var time_list :Array

func _init() -> void:
	time_list = ["start", Time.get_unix_time_from_system()]

func split(name :String = "") -> void:
	if name == "":
		name = "%s" % time_list.size()
	time_list.append([name, Time.get_unix_time_from_system()])

func _to_string() -> String:
	return "%s" % time_list
