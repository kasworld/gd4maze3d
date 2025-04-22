extends Node

const MakeLine2DWallRate := 1.0/40.0
const MakeSubWallRate := 1.0/20.0
const MakeClockCalWallRate := 1.0/70.0

const VisibleStoreyUp :int = 3
const VisibleStoreyDown :int = 3
const MazeSize := Vector2i(16*1,9*1)
const StoryH :float = 3.0
const LaneW :float = 4.0
const WallThick :float = LaneW *0.05

const TotalX :float = MazeSize.x * LaneW
const TotalY :float = MazeSize.y * LaneW
var TotalDiagonal :float = (MazeSize*LaneW).length()
const MeshSize :Vector2 = MazeSize*LaneW +Vector2(WallThick, WallThick)

const WallSize_NS_Full = Vector3(LaneW,StoryH,WallThick)
const WallSize_NS_Reduced = Vector3(LaneW-WallThick,StoryH,WallThick)
const WallSize_EW_Full = Vector3(WallThick,StoryH,LaneW)
const WallSize_EW_Reduced = Vector3(WallThick,StoryH,LaneW-WallThick)

var StoreyGapRate := 1.0
func calc_current_storey_gap() -> float:
	return StoryH * StoreyGapRate

func calc_storey_base_y_pos(storey_num :int) -> float:
	return storey_num * (StoryH + calc_current_storey_gap())

func calc_storey_mid_y_pos(storey_num :int) -> float:
	return storey_num * (StoryH + calc_current_storey_gap()) + StoryH /2

const BallTrailCount :int = 14
const CharacterCount :int = max(1, MazeSize.x*MazeSize.y/10.0)
const DonutCapsuleCount :int = max(1, MazeSize.x*MazeSize.y/20.0)
const TreeCount :int = max(1, MazeSize.x*MazeSize.y/30.0)
const ActionQueueLimit = 10

func rand_pos_2i() -> Vector2i:
	return Vector2i(randi_range(0,MazeSize.x-1),randi_range(0,MazeSize.y-1) )

func _to_string() -> String:
	return "Storey upper:%d lower:%d
	Maze size:%s height:%.1f lane width:%.1f wall thick:%.1f
	Count ball trail:%d donnut capsule:%d tree:%d
	Character count:%d action queue size:%d" % [
		VisibleStoreyUp, VisibleStoreyDown,
		MazeSize, StoryH, LaneW, WallThick,
		BallTrailCount, DonutCapsuleCount, TreeCount,
		CharacterCount, ActionQueueLimit,
	]
