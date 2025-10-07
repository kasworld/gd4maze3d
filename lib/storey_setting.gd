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
var DonutCapsuleCount :int
var TreeCount :int

func rand_pos_2i() -> Vector2i:
	return Vector2i(randi_range(0,MazeSize.x-1),randi_range(0,MazeSize.y-1) )

func _to_string() -> String:
	return "StoreySetting
	Maze size:%s height:%.1f lane width:%.1f wall thick:%.1f
	Count ball trail:%d donnut capsule:%d tree:%d" % [
		MazeSize, StoryH, LaneW, WallThick,
		MeshTrailTypeList.size(), DonutCapsuleCount, TreeCount,
	]
