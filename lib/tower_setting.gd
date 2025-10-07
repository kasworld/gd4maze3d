class_name TowerSetting

var VisibleStoreyUp :int
var VisibleStoreyDown :int
var CharacterCount :int
var storey_setting :StoreySetting

func make_default() -> TowerSetting:
	storey_setting = StoreySetting.new().make_default()
	VisibleStoreyUp = 3
	VisibleStoreyDown = 3
	CharacterCount = max(1, storey_setting.MazeSize.x*storey_setting.MazeSize.y/10.0)
	return self

func make_deco() -> TowerSetting:
	storey_setting = StoreySetting.new().make_deco()
	VisibleStoreyUp = 3
	VisibleStoreyDown = 3
	CharacterCount = 1
	return self

# used to animate
var StoreyGapRate := 1.0
func calc_current_storey_gap() -> float:
	return storey_setting.StoryH * StoreyGapRate
func calc_storey_base_y_pos(storey_index :int) -> float:
	return storey_index * (storey_setting.StoryH + calc_current_storey_gap())
func calc_storey_mid_y_pos(storey_index :int) -> float:
	return storey_index * (storey_setting.StoryH + calc_current_storey_gap()) + storey_setting.StoryH /2

func _to_string() -> String:
	return "TowerSetting upper:%d lower:%d
	Character count:%d
	Storey %s" % [
		VisibleStoreyUp, VisibleStoreyDown,
		CharacterCount,
		storey_setting,
	]
