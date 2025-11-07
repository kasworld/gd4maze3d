class_name Maze3DSetting

static func new_default() -> Maze3DSetting:
	var rtn := new()
	rtn.MazeSize = Vector2i(4,4)
	rtn.StoryH = 3.0
	rtn.LaneW = 4.0
	rtn.WallThick = rtn.LaneW *0.05
	rtn.MakeSubWallRate = 1.0/rtn.CalcCellCount()
	return rtn

func _to_string() -> String:
	return "Maze3DSetting[size:%s height:%.1f lane width:%.1f wall thick:%.1f]" % [
		MazeSize, StoryH, LaneW, WallThick,
	]

var MazeSize :Vector2i
var StoryH :float
var LaneW :float
var WallThick :float
var MakeSubWallRate :float

func duplicate() -> Maze3DSetting:
	var rtn := new()
	rtn.MazeSize = MazeSize
	rtn.StoryH = StoryH
	rtn.LaneW = LaneW
	rtn.WallThick = WallThick
	rtn.MakeSubWallRate = MakeSubWallRate
	return rtn

func rand_pos_2i() -> Vector2i:
	return Vector2i(randi_range(0,MazeSize.x-1),randi_range(0,MazeSize.y-1) )

func CalcCellCount() -> int:
	return MazeSize.x * MazeSize.y

# without wall
func CalcSizeV2() -> Vector2:
	return MazeSize*LaneW
func CalcDiagonalLengthV2() -> float:
	return CalcSizeV2().length()
func CalcSizeV3() -> Vector3:
	var sz := CalcSizeV2()
	return Vector3(sz.x,StoryH,sz.y)
func CalcDiagonalLengthV3() -> float:
	return CalcSizeV3().length()

# with wall
func CalcSizeWithWallV2() -> Vector2:
	return MazeSize*LaneW + Vector2(WallThick, WallThick)
func CalcDiagonalLengthWithWallV2() -> float:
	return CalcSizeWithWallV2().length()
func CalcSizeWithWallV3() -> Vector3:
	var sz := CalcSizeWithWallV2()
	return Vector3(sz.x,StoryH,sz.y)
func CalcDiagonalLengthWithWallV3() -> float:
	return CalcSizeWithWallV3().length()

func CalcWallSize_NS_Full() -> Vector3:
	return Vector3(LaneW, StoryH, WallThick)
func CalcWallSize_NS_Reduced() -> Vector3:
	return Vector3(LaneW-WallThick, StoryH, WallThick)
func CalcWallSize_EW_Full() -> Vector3:
	return Vector3(WallThick, StoryH, LaneW)
func CalcWallSize_EW_Reduced() -> Vector3:
	return Vector3(WallThick, StoryH, LaneW-WallThick)

func mazepos2storeypos( mp :Vector2i, y :float) -> Vector3:
	return Vector3(LaneW/2+ mp.x*LaneW, y, LaneW/2+ mp.y*LaneW) -CalcSizeV3()/2

func storeypos2mazepos(pos :Vector3) -> Vector2i:
	pos += CalcSizeV3()/2
	var x = clampi(int(pos.x/LaneW),0, MazeSize.x-1)
	var y = clampi(int(pos.z/LaneW),0, MazeSize.y-1)
	return Vector2i(x,y)

func CalcCellBox(pos :Vector2i) -> AABB:
	var rtn = AABB(
		Vector3(LaneW*pos.x +WallThick/2, 0, LaneW*pos.y +WallThick/2) -CalcSizeV3()/2,
		Vector3(LaneW -WallThick, StoryH, LaneW -WallThick)
		)
	return rtn
