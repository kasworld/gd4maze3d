class_name ClampedFloat

var _vmin :float
var _vmax :float
var _value :float
var _default :float
func _init(v :float, v1 :float, v2:float)->void:
	_vmin = v1
	_vmax = v2
	_value = clampf(v, _vmin, _vmax)
	_default = _value
func get_value()->float:
	return _value
func set_value(v :float)->float:
	_value = clampf(v, _vmin, _vmax)
	return _value
func set_up()->float:
	_value = clampf(_value *1.1, _vmin, _vmax)
	return _value
func set_max()->float:
	_value = _vmax
	return _value
func set_down()->float:
	_value = clampf(_value /1.1, _vmin, _vmax)
	return _value
func set_min()->float:
	_value = _vmin
	return _value
func set_randfn()->float:
	_value = clampf(randfn((_vmin+_vmax)/2,(_vmax-_vmin)/4) , _vmin, _vmax)
	return _value
func reset()->float:
	_value = _default
	return _value
func _to_string() -> String:
	return "%.2f(%.2f-%.2f)" % [_value, _vmin, _vmax]
