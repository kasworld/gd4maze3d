class_name Clamped

class Float:
	var _vmin :float
	var _vmax :float
	var _value :float
	func _init(v :float, v1 :float, v2:float)->void:
		_vmin = v1
		_vmax = v2
		_value = clampf(v, _vmin, _vmax)
	func get_value()->float:
		return _value
	func set_value(v :float)->float:
		_value = clampf(v, _vmin, _vmax)
		return _value
	func set_up()->void:
		_value = clampf(_value *1.1, _vmin, _vmax)
	func set_max()->void:
		_value = _vmax
	func set_down()->void:
		_value = clampf(_value *0.9, _vmin, _vmax)
	func set_min()->void:
		_value = _vmin
	func set_randfn()->void:
		_value = clampf(randfn((_vmin+_vmax)/2,(_vmax-_vmin)/4) , _vmin, _vmax)
	func _to_string() -> String:
		return "%.1f(%f-%f)"
