class_name StoreySetting

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
var MeshTrailTypeList :Array
var MakeMeshTrailRate :float
var DonutCapsuleCount :int
var TreeCount :int

func make_default() -> StoreySetting:
	MazeSize = Vector2i(3,3)
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
	MeshTrailTypeList = ["♠","♣","♥","♦","★"]
	MakeMeshTrailRate = 2.0/(MazeSize.x*MazeSize.y)
	DonutCapsuleCount = max(1, MazeSize.x*MazeSize.y/20.0)
	TreeCount = max(1, MazeSize.x*MazeSize.y/50.0)
	return self 

func make_deco() -> StoreySetting:
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
	MeshTrailTypeList = [ [0,1,2,3,4,5,"♠","♣","♥","♦","★","☆","♩","♪","♬"].pick_random() ]
	DonutCapsuleCount = 1
	TreeCount = 1
	return self 

func rand_pos_2i() -> Vector2i:
	return Vector2i(randi_range(0,MazeSize.x-1),randi_range(0,MazeSize.y-1) )

func _to_string() -> String:
	return "StoreySetting
	Maze size:%s height:%.1f lane width:%.1f wall thick:%.1f
	Count ball trail:%d donnut capsule:%d tree:%d" % [
		MazeSize, StoryH, LaneW, WallThick,
		MeshTrailTypeList.size(), DonutCapsuleCount, TreeCount,
	]
