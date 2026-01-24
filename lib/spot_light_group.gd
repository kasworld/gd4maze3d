class_name SpotLightGroup

var light_list :Array[SpotLight3D]

## arg is Node or Array
func _init(arg ) -> void:
	light_list = []
	if arg is Node:
		for sl in arg.get_children():
			light_list.append(sl)
	elif arg is Array:
		for sl in arg:
			light_list.append(sl)
	else:
		assert(false)

## flag bit == 1 , set light_energy
func set_light_energy(v :float, flags :int) -> void:
	for i in light_list.size():
		if BitFlag.TestByPos(i, flags):
			light_list[i].light_energy = v


## flag bit == 1 , set visible to b
func set_light_on(b :bool, flags :int) -> void:
	for i in light_list.size():
		if BitFlag.TestByPos(i, flags):
			light_list[i].visible = b

func set_light_on_at(i :int, b :bool) -> void:
	light_list[i].visible = b

## all light on/off by flag
func set_light_on_all(flags :int) -> void:
	for i in light_list.size():
		light_list[i].visible = BitFlag.TestByPos(i, flags)

func get_light_on_all() -> int:
	var rtn := 0
	for i in light_list.size():
		BitFlag.SetByPos(i, light_list[i].visible)
	return rtn

## flag bit == 1 , set light shadow to b
func set_light_shadow(b :bool, flags :int) -> void:
	for i in light_list.size():
		if BitFlag.TestByPos(i, flags):
			light_list[i].shadow_enabled = b

func set_light_shadow_at(i :int, b :bool) -> void:
	light_list[i].shadow_enabled = b

## all light shadow on/off by flag
func set_light_shadow_all(flags :int) -> void:
	for i in light_list.size():
		light_list[i].shadow_enabled = BitFlag.TestByPos(i, flags)

func get_light_shadow_all() -> int:
	var rtn := 0
	for i in light_list.size():
		BitFlag.SetByPos(i, light_list[i].shadow_enabled)
	return rtn

func set_light_color(co :Color, flags :int) -> void:
	for i in light_list.size():
		if BitFlag.TestByPos(i, flags):
			light_list[i].light_color = co

func set_light_color_at(i :int, co :Color) -> void:
	light_list[i].light_color = co

func get_light_color_all() -> Array[Color]:
	var rtn :Array[Color] = []
	for lt in light_list:
		rtn.append(lt.light_color)
	return rtn

func make_pos_list() -> Array[int]:
	return BitFlag.MakeFilledPosList(light_list.size())

func get_size() -> int:
	return light_list.size()
