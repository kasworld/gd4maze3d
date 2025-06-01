class_name TowerSetting

var VisibleStoreyUp :int
var VisibleStoreyDown :int
var MazeSize :Vector2i
var StoryH :float
var LaneW :float
var WallThick :float
var StoreySize :Vector2
var TotalDiagonal :float
var MeshSize :Vector2
var MeshCenter :Vector2
var WallSize_NS_Full :Vector3
var WallSize_NS_Reduced :Vector3
var WallSize_EW_Full :Vector3
var WallSize_EW_Reduced :Vector3
var MakeLine2DWallRate :float
var MakeSubWallRate :float
var MakeClockCalWallRate :float
var BallTrailMeshTypeList :Array
var DonutCapsuleCount :int
var TreeCount :int
var CharacterCount :int

func make_default() -> TowerSetting:
	VisibleStoreyUp = 3
	VisibleStoreyDown = 3
	MazeSize = Vector2i(16,9)
	StoryH = 3.0
	LaneW = 4.0
	WallThick = LaneW *0.05
	StoreySize = MazeSize*LaneW
	TotalDiagonal = (MazeSize*LaneW).length()
	MeshSize = MazeSize*LaneW + Vector2(WallThick, WallThick)
	MeshCenter = MazeSize*LaneW/2
	WallSize_NS_Full = Vector3(LaneW, StoryH, WallThick)
	WallSize_NS_Reduced = Vector3(LaneW-WallThick, StoryH, WallThick)
	WallSize_EW_Full = Vector3(WallThick, StoryH, LaneW)
	WallSize_EW_Reduced = Vector3(WallThick, StoryH, LaneW-WallThick)
	MakeLine2DWallRate = 2.0/(MazeSize.x*MazeSize.y)
	MakeSubWallRate = 2.0/(MazeSize.x*MazeSize.y)
	MakeClockCalWallRate = 2.0/(MazeSize.x*MazeSize.y)
	BallTrailMeshTypeList = [0,1,2,3,4,5,"♠","♣","♥","♦"]
	DonutCapsuleCount = max(1, MazeSize.x*MazeSize.y/20.0)
	TreeCount = max(1, MazeSize.x*MazeSize.y/30.0)
	CharacterCount = max(1, MazeSize.x*MazeSize.y/10.0)
	return self

func make_deco() -> TowerSetting:
	VisibleStoreyUp = 3
	VisibleStoreyDown = 3
	MazeSize = Vector2i(10,10)
	StoryH = 3.0
	LaneW = 4.0
	WallThick = LaneW *0.05
	StoreySize = MazeSize*LaneW
	TotalDiagonal = (MazeSize*LaneW).length()
	MeshSize = MazeSize*LaneW + Vector2(WallThick, WallThick)
	MeshCenter = MazeSize*LaneW/2
	WallSize_NS_Full = Vector3(LaneW, StoryH, WallThick)
	WallSize_NS_Reduced = Vector3(LaneW-WallThick, StoryH, WallThick)
	WallSize_EW_Full = Vector3(WallThick, StoryH, LaneW)
	WallSize_EW_Reduced = Vector3(WallThick, StoryH, LaneW-WallThick)
	MakeLine2DWallRate = 1.0/(MazeSize.x*MazeSize.y)
	MakeSubWallRate = 1.0/(MazeSize.x*MazeSize.y)
	MakeClockCalWallRate = 1.0/(MazeSize.x*MazeSize.y)
	BallTrailMeshTypeList = [ [0,1,2,3,4,5,"♠","♣","♥","♦"].pick_random() ]
	DonutCapsuleCount = 1
	TreeCount = 1
	CharacterCount = 1
	return self

# used to animate
var StoreyGapRate := 1.0
func calc_current_storey_gap() -> float:
	return StoryH * StoreyGapRate
func calc_storey_base_y_pos(storey_index :int) -> float:
	return storey_index * (StoryH + calc_current_storey_gap())
func calc_storey_mid_y_pos(storey_index :int) -> float:
	return storey_index * (StoryH + calc_current_storey_gap()) + StoryH /2

func rand_pos_2i() -> Vector2i:
	return Vector2i(randi_range(0,MazeSize.x-1),randi_range(0,MazeSize.y-1) )

func _to_string() -> String:
	return "TowerSetting upper:%d lower:%d
	Maze size:%s height:%.1f lane width:%.1f wall thick:%.1f
	Count ball trail:%d donnut capsule:%d tree:%d
	Character count:%d" % [
		VisibleStoreyUp, VisibleStoreyDown,
		MazeSize, StoryH, LaneW, WallThick,
		BallTrailMeshTypeList.size(), DonutCapsuleCount, TreeCount,
		CharacterCount,
	]
