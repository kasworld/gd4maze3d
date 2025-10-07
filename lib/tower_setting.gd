class_name TowerSetting

var VisibleStoreyUp :int
var VisibleStoreyDown :int
var CharacterCount :int
var storey_setting :StoreySetting

func make_default() -> TowerSetting:
	storey_setting = StoreySetting.new()
	storey_setting.MazeSize = Vector2i(3,3)
	storey_setting.StoryH = 3.0
	storey_setting.LaneW = 4.0
	storey_setting.WallThick = storey_setting.LaneW *0.05
	storey_setting.StoreySize = storey_setting.MazeSize*storey_setting.LaneW
	storey_setting.TotalDiagonal = (storey_setting.MazeSize*storey_setting.LaneW).length()
	storey_setting.MeshSize = storey_setting.MazeSize*storey_setting.LaneW + Vector2(storey_setting.WallThick, storey_setting.WallThick)
	storey_setting.MeshCenter = storey_setting.MazeSize*storey_setting.LaneW/2
	storey_setting.WallSize_NS_Full = Vector3(storey_setting.LaneW, storey_setting.StoryH, storey_setting.WallThick)
	storey_setting.WallSize_NS_Reduced = Vector3(storey_setting.LaneW-storey_setting.WallThick, storey_setting.StoryH, storey_setting.WallThick)
	storey_setting.WallSize_EW_Full = Vector3(storey_setting.WallThick, storey_setting.StoryH, storey_setting.LaneW)
	storey_setting.WallSize_EW_Reduced = Vector3(storey_setting.WallThick, storey_setting.StoryH, storey_setting.LaneW-storey_setting.WallThick)
	storey_setting.MakeLine2DWallRate = 2.0/(storey_setting.MazeSize.x*storey_setting.MazeSize.y)
	storey_setting.MakeSubWallRate = 2.0/(storey_setting.MazeSize.x*storey_setting.MazeSize.y)
	storey_setting.MakeClockCalWallRate = 2.0/(storey_setting.MazeSize.x*storey_setting.MazeSize.y)
	storey_setting.MeshTrailTypeList = ["♠","♣","♥","♦","★"]
	storey_setting.DonutCapsuleCount = max(1, storey_setting.MazeSize.x*storey_setting.MazeSize.y/20.0)
	storey_setting.TreeCount = max(1, storey_setting.MazeSize.x*storey_setting.MazeSize.y/50.0)

	VisibleStoreyUp = 3
	VisibleStoreyDown = 3
	CharacterCount = max(1, storey_setting.MazeSize.x*storey_setting.MazeSize.y/10.0)
	return self

func make_deco() -> TowerSetting:
	storey_setting = StoreySetting.new()
	storey_setting.MazeSize = Vector2i(10,10)
	storey_setting.StoryH = 3.0
	storey_setting.LaneW = 4.0
	storey_setting.WallThick = storey_setting.LaneW *0.05
	storey_setting.StoreySize = storey_setting.MazeSize*storey_setting.LaneW
	storey_setting.TotalDiagonal = (storey_setting.MazeSize*storey_setting.LaneW).length()
	storey_setting.MeshSize = storey_setting.MazeSize*storey_setting.LaneW + Vector2(storey_setting.WallThick, storey_setting.WallThick)
	storey_setting.MeshCenter = storey_setting.MazeSize*storey_setting.LaneW/2
	storey_setting.WallSize_NS_Full = Vector3(storey_setting.LaneW, storey_setting.StoryH, storey_setting.WallThick)
	storey_setting.WallSize_NS_Reduced = Vector3(storey_setting.LaneW-storey_setting.WallThick, storey_setting.StoryH, storey_setting.WallThick)
	storey_setting.WallSize_EW_Full = Vector3(storey_setting.WallThick, storey_setting.StoryH, storey_setting.LaneW)
	storey_setting.WallSize_EW_Reduced = Vector3(storey_setting.WallThick, storey_setting.StoryH, storey_setting.LaneW-storey_setting.WallThick)
	storey_setting.MakeLine2DWallRate = 1.0/(storey_setting.MazeSize.x*storey_setting.MazeSize.y)
	storey_setting.MakeSubWallRate = 1.0/(storey_setting.MazeSize.x*storey_setting.MazeSize.y)
	storey_setting.MakeClockCalWallRate = 1.0/(storey_setting.MazeSize.x*storey_setting.MazeSize.y)
	storey_setting.MeshTrailTypeList = [ [0,1,2,3,4,5,"♠","♣","♥","♦","★","☆","♩","♪","♬"].pick_random() ]
	storey_setting.DonutCapsuleCount = 1
	storey_setting.TreeCount = 1

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
