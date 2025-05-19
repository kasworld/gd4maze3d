class_name TowerSetting

var MakeLine2DWallRate := 1.0/40.0
var MakeSubWallRate := 1.0/20.0
var MakeClockCalWallRate := 1.0/70.0

var VisibleStoreyUp :int = 3
var VisibleStoreyDown :int = 3
var MazeSize := Vector2i(16*1,9*1)
var StoryH :float = 3.0
var LaneW :float = 4.0

func WallThick() -> float:
	return LaneW *0.05
func StoreySize() -> Vector2:
	return MazeSize*LaneW
func TotalDiagonal() -> float:
	return (MazeSize*LaneW).length()
func MeshSize() -> Vector2:
	return MazeSize*LaneW + Vector2(WallThick(), WallThick())
func MeshCenter() ->Vector2:
	return MazeSize*LaneW/2
func WallSize_NS_Full() -> Vector3:
	return Vector3(LaneW, StoryH, WallThick())
func WallSize_NS_Reduced() -> Vector3:
	return Vector3(LaneW-WallThick(), StoryH, WallThick())
func WallSize_EW_Full() -> Vector3:
	return Vector3(WallThick(), StoryH, LaneW)
func WallSize_EW_Reduced() -> Vector3:
	return Vector3(WallThick(), StoryH, LaneW-WallThick())

var StoreyGapRate := 1.0
func calc_current_storey_gap() -> float:
	return StoryH * StoreyGapRate

func calc_storey_base_y_pos(storey_num :int) -> float:
	return storey_num * (StoryH + calc_current_storey_gap())

func calc_storey_mid_y_pos(storey_num :int) -> float:
	return storey_num * (StoryH + calc_current_storey_gap()) + StoryH /2

var BallTrailCount :int = 14
var DonutCapsuleCount :int = max(1, MazeSize.x*MazeSize.y/20.0)
var TreeCount :int = max(1, MazeSize.x*MazeSize.y/30.0)

var CharacterCount :int = max(1, MazeSize.x*MazeSize.y/10.0)

func rand_pos_2i() -> Vector2i:
	return Vector2i(randi_range(0,MazeSize.x-1),randi_range(0,MazeSize.y-1) )

func _to_string() -> String:
	return "Tower upper:%d lower:%d
	Maze size:%s height:%.1f lane width:%.1f wall thick:%.1f
	Count ball trail:%d donnut capsule:%d tree:%d
	Character count:%d" % [
		VisibleStoreyUp, VisibleStoreyDown,
		MazeSize, StoryH, LaneW, WallThick,
		BallTrailCount, DonutCapsuleCount, TreeCount,
		CharacterCount,
	]
