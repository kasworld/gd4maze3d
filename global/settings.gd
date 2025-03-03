extends Node

const MakeLine2DWallRate = 1.0/40.0
const MakeSubWallRate = 1.0/20.0
const MakeClockCalWallRate = 1.0/70.0
const MakeDonutCapsuleRate = 1.0/2.0
const MakeTreeRate = 1.0/40.0

const VisibleStoreyUp :int = 3
const VisibleStoreyDown :int = 3
const MazeSize = Vector2i(16*1,9*1)
const StoryH :float = 3.0
const LaneW :float = 4.0
const WallThick :float = LaneW *0.05
const BallTrailCount = 14
const CharacterCount = MazeSize.x*MazeSize.y/10
