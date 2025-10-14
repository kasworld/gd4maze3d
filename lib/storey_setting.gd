class_name StoreySetting

var MazeSize :Vector2i
var StoryH :float
var LaneW :float
var WallThick :float

var MakeLine2DWallRate :float
var MakeSubWallRate :float
var MakeClockCalWallRate :float
var MeshTrailTypeList :Array
var MakeMeshTrailRate :float
var DonutCapsuleCount :int
var TreeCount :int

func duplicate(deep :bool = false) -> StoreySetting:
	var rtn := new()
	rtn.MazeSize = MazeSize
	rtn.StoryH = StoryH
	rtn.LaneW = LaneW
	rtn.WallThick = WallThick
	rtn.MakeLine2DWallRate = MakeLine2DWallRate
	rtn.MakeSubWallRate = MakeSubWallRate
	rtn.MakeClockCalWallRate = MakeClockCalWallRate
	if deep:
		rtn.MeshTrailTypeList = MeshTrailTypeList.duplicate()
	else:
		rtn.MeshTrailTypeList = MeshTrailTypeList
	rtn.MakeMeshTrailRate = MakeMeshTrailRate
	rtn.DonutCapsuleCount = DonutCapsuleCount
	rtn.TreeCount = TreeCount
	return rtn

func rand_pos_2i() -> Vector2i:
	return Vector2i(randi_range(0,MazeSize.x-1),randi_range(0,MazeSize.y-1) )

func CalcStoreySize() -> Vector2:
	return MazeSize*LaneW
func CalcDiagonalLength() -> float:
	return (MazeSize*LaneW).length()
func CalcMeshSize() -> Vector2:
	return MazeSize*LaneW + Vector2(WallThick, WallThick)
func CalcMeshCenter() -> Vector2:
	return MazeSize*LaneW/2
func CalcMeshCenterV3() -> Vector3:
	return Vector3(MazeSize.x*LaneW/2,0,MazeSize.y*LaneW/2)

func CalcWallSize_NS_Full() -> Vector3:
	return Vector3(LaneW, StoryH, WallThick)
func CalcWallSize_NS_Reduced() -> Vector3:
	return Vector3(LaneW-WallThick, StoryH, WallThick)
func CalcWallSize_EW_Full() -> Vector3:
	return Vector3(WallThick, StoryH, LaneW)
func CalcWallSize_EW_Reduced() -> Vector3:
	return Vector3(WallThick, StoryH, LaneW-WallThick)

func make_default() -> StoreySetting:
	MazeSize = Vector2i(4,4)
	StoryH = 3.0
	LaneW = 4.0
	WallThick = LaneW *0.05

	MakeLine2DWallRate = 1.0/(MazeSize.x*MazeSize.y)
	MakeSubWallRate = 1.0/(MazeSize.x*MazeSize.y)
	MakeClockCalWallRate = 1.0/(MazeSize.x*MazeSize.y)
	MeshTrailTypeList = ["♠","♣","♥","♦","★"]
	MakeMeshTrailRate = 2.0/(MazeSize.x*MazeSize.y)
	DonutCapsuleCount = max(2, MazeSize.x*MazeSize.y/20.0)
	TreeCount = max(1, MazeSize.x*MazeSize.y/50.0)
	return self 

func make_deco() -> StoreySetting:
	MazeSize = Vector2i(4,4)
	StoryH = 3.0
	LaneW = 4.0
	WallThick = LaneW *0.05

	MakeLine2DWallRate = 1.0/(MazeSize.x*MazeSize.y)
	MakeSubWallRate = 1.0/(MazeSize.x*MazeSize.y)
	MakeClockCalWallRate = 1.0/(MazeSize.x*MazeSize.y)
	MeshTrailTypeList = [ [0,1,2,3,4,5,"♠","♣","♥","♦","★","☆","♩","♪","♬"].pick_random() ]
	MakeMeshTrailRate = 0.5
	DonutCapsuleCount = 1
	TreeCount = 1
	return self 


func _to_string() -> String:
	return "StoreySetting[Maze size:%s height:%.1f lane width:%.1f wall thick:%.1f
	Count ball trail:%d donnut capsule:%d tree:%d]" % [
		MazeSize, StoryH, LaneW, WallThick,
		MeshTrailTypeList.size(), DonutCapsuleCount, TreeCount,
	]
