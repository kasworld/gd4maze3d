class_name TowerSetting

var VisibleStoreyUp :int
var VisibleStoreyDown :int
var CharacterCount :int
var StoreyGap :float
var storey_setting :StoreySetting

func make_default() -> TowerSetting:
	storey_setting = StoreySetting.new().make_default()
	VisibleStoreyUp = 3
	VisibleStoreyDown = 3
	StoreyGap = 3
	CharacterCount = max(1, storey_setting.MazeSize.x*storey_setting.MazeSize.y/10.0)
	return self

func make_deco() -> TowerSetting:
	storey_setting = StoreySetting.new().make_deco()
	VisibleStoreyUp = 3
	VisibleStoreyDown = 3
	StoreyGap = 3
	CharacterCount = 1
	return self

func _to_string() -> String:
	return "TowerSetting upper:%d lower:%d
	Character count:%d
	Storey %s" % [
		VisibleStoreyUp, VisibleStoreyDown,
		CharacterCount,
		storey_setting,
	]
