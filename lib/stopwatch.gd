class_name StopWatch

## array of [name, time]
var time_list :Array
var name :String

func _init(s :String = "") -> void:
	name = s
	time_list = [{ "name": "start", "time": Time.get_unix_time_from_system()}]

func split(s :String = "") -> StopWatch:
	if s == "":
		s = "%s" % time_list.size()
	time_list.append({ "name": s, "time": Time.get_unix_time_from_system()})
	return self

func _to_string() -> String:
	var pack_str := PackedStringArray([name])
	for i in time_list.size():
		if i == 0: # name , dur
			pack_str.append("%s:%s" % [ time_list[i].name, time_list[i].time - time_list[0].time ])
		else: # name, last dur, total dur
			pack_str.append("%s:%s:%s" % [ time_list[i].name, time_list[i].time - time_list[i-1].time, time_list[i].time - time_list[0].time ])
	return " ".join(pack_str)
