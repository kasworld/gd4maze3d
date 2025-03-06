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
const BallTrailCount :int = 14
const CharacterCount :int = max(1, MazeSize.x*MazeSize.y/10.0)
const DonutCapsuleCount :int = max(1, MazeSize.x*MazeSize.y/20.0)
const TreeCount :int = max(1, MazeSize.x*MazeSize.y/30.0)

func rand_pos_2i() -> Vector2i:
	return Vector2i(randi_range(0,MazeSize.x-1),randi_range(0,MazeSize.y-1) )
