class_name TowerSetting

var VisibleStoreyUp :int
var VisibleStoreyDown :int
var CharacterCount :int
var StoreyGap :float

func duplicate() -> TowerSetting:
	var rtn := new()
	rtn.VisibleStoreyUp = VisibleStoreyUp
	rtn.VisibleStoreyDown = VisibleStoreyDown
	rtn.StoreyGap = StoreyGap
	rtn.CharacterCount = CharacterCount
	return rtn

func make_default() -> TowerSetting:
	VisibleStoreyUp = 3
	VisibleStoreyDown = 3
	StoreyGap = 1
	CharacterCount = 2 
	return self

func make_deco() -> TowerSetting:
	VisibleStoreyUp = 3
	VisibleStoreyDown = 3
	StoreyGap = 3
	CharacterCount = 1
	return self

func _to_string() -> String:
	return "TowerSetting upper:%d lower:%d
	Character count:%d" % [
		VisibleStoreyUp, VisibleStoreyDown,
		CharacterCount,
	]
