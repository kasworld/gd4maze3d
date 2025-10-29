class_name Animation3D

signal animation_ended(st :Node3D, ani :Dictionary)

var animation_list :Array[Dictionary]
# {Name,  Node3d, Field(position, rotation) , StartValue, EndValue , StartTick, DurSec } 

func start_move(name :String, node :Node3D, src_pos :Vector3, dst_pos: Vector3, dur_sec :float) -> Dictionary:
	var ani := {
		"Name" : name, # for end signal
		"Node3d" : node, 
		"Field" : "position",
		"StartValue" : src_pos, 
		"EndValue" : dst_pos, 
		"StartTick" : Time.get_unix_time_from_system(),
		"DurSec" : dur_sec,
	}
	animation_list.append(ani)
	return ani
	
func handle_animation() -> void:
	var timenow := Time.get_unix_time_from_system()
	var new_list :Array[Dictionary]
	for ani in animation_list:
		var rate :float = (timenow - ani.StartTick) / ani.DurSec
		if rate >= 1.0:
			animation_ended.emit(ani.Node3d, ani)
			continue
		new_list.append(ani)
		match ani.Field:
			"position":
				ani.Node3d.position = lerp(ani.StartValue, ani.EndValue, rate)
	animation_list = new_list
