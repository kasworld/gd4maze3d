class_name Maze3DSetting

static func new_default() -> Maze3DSetting:
	return new()

func _to_string() -> String:
	return "Maze3DSetting[size:%s height:%.1f lane width:%.1f wall thick:%.1f]" % [
		MazeSize, StoryH, LaneW, WallThick,
	]

var MazeSize :Vector2i
var StoryH :float
var LaneW :float
var WallThick :float
var MakeSubWallRate :float

func _init(
	size :Vector2i = Vector2i(4,4),
	height :float = 3.0,
	lane_width :float = 4.0,
	wall_thick :float = 4.0*0.05,
	subwall_rate :float = 1.0/(4*4)
	) -> void:
	MazeSize = size
	StoryH = height
	LaneW = lane_width
	WallThick = wall_thick
	MakeSubWallRate = subwall_rate

func duplicate() -> Maze3DSetting:
	return new(MazeSize,StoryH,LaneW,WallThick,MakeSubWallRate)

func rand_pos_2i() -> Vector2i:
	return Vector2i(randi_range(0,MazeSize.x-1),randi_range(0,MazeSize.y-1) )

func CalcCellCount() -> int:
	return MazeSize.x * MazeSize.y

func CellSize() -> Vector3:
	return Vector3(LaneW, LaneW, StoryH)

func PillarSize() -> Vector3:
	return Vector3(WallThick,WallThick,StoryH)

# without wall
func CalcSizeV2() -> Vector2:
	return MazeSize*LaneW
func CalcSizeV3() -> Vector3:
	var sz := CalcSizeV2()
	return Vector3(sz.x,sz.y,StoryH)

# with wall
func CalcSizeWithWallV2() -> Vector2:
	return CalcSizeV2() + Vector2(WallThick, WallThick)
func CalcSizeWithWallV3() -> Vector3:
	var sz := CalcSizeWithWallV2()
	return Vector3(sz.x,sz.y,StoryH)

func CalcWallSize_H_Long() -> Vector3:
	return Vector3(LaneW, WallThick, StoryH)
func CalcWallSize_H_Short() -> Vector3:
	return CalcWallSize_H_Long() - Vector3(WallThick, 0, 0)

func CalcWallSize_V_Long() -> Vector3:
	return swap_xy(CalcWallSize_H_Long())
func CalcWallSize_V_Short() -> Vector3:
	return swap_xy(CalcWallSize_H_Short())

static func swap_xy(src :Vector3) -> Vector3:
	return Vector3(src.y,src.x,src.z)

func mazepos2storeypos( mp :Vector2i, z :float) -> Vector3:
	return Vector3(LaneW/2+ mp.x*LaneW, LaneW/2+ mp.y*LaneW, z) -CalcSizeV3()/2

func storeypos2mazepos(pos :Vector3) -> Vector2i:
	pos += CalcSizeV3()/2
	var x = clampi(int(pos.x/LaneW),0, MazeSize.x-1)
	var y = clampi(int(pos.y/LaneW),0, MazeSize.y-1)
	return Vector2i(x,y)


func CalcCellBox(pos :Vector2i) -> AABB:
	return AABB(
		Vector3(LaneW*pos.x, LaneW*pos.y, 0) -CalcSizeV3()/2,
		CellSize(),
		)

func CalcCellBoxXY(x :int, y :int) -> AABB:
	return CalcCellBox(Vector2i(x,y))
