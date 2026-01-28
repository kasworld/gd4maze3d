class_name SimpleAnimation

signal animation_ended(st :Node, ani :Dictionary)

var animation_list :Array[Dictionary]
# {Name,  Node, Field(position, rotation, scale), SubField(0,1,2) , From, To , StartTick, DurSec }


func get_animation_count() -> int:
	return animation_list.size()

func is_empty() -> bool:
	return animation_list.is_empty()

func is_Name_exist(name :String) -> bool:
	for d in animation_list:
		if d.Name == name:
			return true
	return false

func find_by_Name(name :String) -> Array[Dictionary]:
	var rtn :Array[Dictionary]
	for d in animation_list:
		if d.Name == name:
			rtn.append(d)
	return rtn

func is_Field_exist(field :String) -> bool:
	for d in animation_list:
		if d.Field == field:
			return true
	return false

func find_by_Field(field :String) -> Array[Dictionary]:
	var rtn :Array[Dictionary]
	for d in animation_list:
		if d.Field == field:
			rtn.append(d)
	return rtn

func add_animation(ani :Dictionary) -> Dictionary:
	ani.StartTick = Time.get_unix_time_from_system()
	animation_list.append(ani)
	return ani

func start_move(name :String, aniNode :Node, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return add_animation(make_move(name,aniNode,from,to,dur_sec))

func make_move(name :String, aniNode :Node, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return {
		"Name" : name, # for end signal
		"AniNode" : aniNode,
		"Field" : "position",
		"From" : from,
		"To" : to,
		"DurSec" : dur_sec,
	}

func start_move_subfield(name :String, aniNode :Node, sub_index :int, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return add_animation( make_move_subfield(name,aniNode, sub_index, from,to, dur_sec) )

func make_move_subfield(name :String, aniNode :Node, sub_index :int, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return {
		"Name" : name, # for end signal
		"AniNode" : aniNode,
		"Field" : "position",
		"SubField" : sub_index,
		"From" : from,
		"To" : to,
		"DurSec" : dur_sec,
	}

func start_rotate(name :String, aniNode :Node, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return add_animation(make_rotate(name,aniNode,from,to,dur_sec))

func make_rotate(name :String, aniNode :Node, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return  {
		"Name" : name, # for end signal
		"AniNode" : aniNode,
		"Field" : "rotation",
		"From" : from,
		"To" : to,
		"DurSec" : dur_sec,
	}

func start_rotate_subfield(name :String, aniNode :Node, sub_index :int, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return add_animation( make_rotate_subfield(name,aniNode, sub_index, from,to, dur_sec) )

func make_rotate_subfield(name :String, aniNode :Node, sub_index :int, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return {
		"Name" : name, # for end signal
		"AniNode" : aniNode,
		"Field" : "rotation",
		"SubField" : sub_index,
		"From" : from,
		"To" : to,
		"DurSec" : dur_sec,
	}

func start_scale(name :String, aniNode :Node, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return add_animation(make_scale(name,aniNode,from,to,dur_sec))

func make_scale(name :String, aniNode :Node, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return {
		"Name" : name, # for end signal
		"AniNode" : aniNode,
		"Field" : "scale",
		"From" : from,
		"To" : to,
		"DurSec" : dur_sec,
	}

func start_scale_subfield(name :String, aniNode :Node, sub_index :int, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return add_animation( make_scale_subfield(name,aniNode, sub_index, from,to, dur_sec) )

func make_scale_subfield(name :String, aniNode :Node, sub_index :int, from :Variant, to: Variant, dur_sec :float) -> Dictionary:
	return {
		"Name" : name, # for end signal
		"AniNode" : aniNode,
		"Field" : "scale",
		"SubField" : sub_index,
		"From" : from,
		"To" : to,
		"DurSec" : dur_sec,
	}

func handle_animation() -> void:
	var timenow := Time.get_unix_time_from_system()
	for i in animation_list.size():
		var ani :Dictionary = animation_list.pop_front()
		if ani.AniNode == null || ani.From == null || ani.To == null:
			continue
		var rate :float = (timenow - ani.StartTick) / ani.DurSec
		if rate >= 1.0:
			rate = 1.0
		update_by_ani(ani, rate)
		if rate >= 1.0:
			animation_ended.emit(ani.AniNode, ani)
		else:
			animation_list.push_back(ani)

func update_by_ani(ani :Dictionary, rate :float) -> void:
	var fromValue = get_value_by_ani(ani, "From")
	var toValue = get_value_by_ani(ani, "To")
	if ani.has("SubField"):
		ani.AniNode[ani.Field][ani.SubField] = lerp(fromValue, toValue, rate)
	else:
		ani.AniNode[ani.Field] = lerp(fromValue, toValue, rate)

func get_value_by_ani(ani :Dictionary, name :String) -> Variant:
	var rtn = ani[name]
	if rtn is Node:
		if ani.has("SubField"):
			rtn = rtn[ani.Field][ani.SubField]
		else:
			rtn = rtn[ani.Field]
	return rtn

func force_end(emit_end :bool) -> void:
	for i in animation_list.size():
		var ani :Dictionary = animation_list.pop_front()
		if ani.AniNode == null || ani.From == null || ani.To == null:
			continue
		var rate :float = 1.0
		update_by_ani(ani, rate)
		if emit_end:
			animation_ended.emit(ani.AniNode, ani)
