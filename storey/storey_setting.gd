class_name StoreySetting

static func new_default(maze_size :Vector2i) -> StoreySetting:
	var rtn := new()
	rtn.MeshTrailTypeList = ["♠","♣","♥","♦","★"]
	rtn.MakeMeshTrailRate = 2.0/(maze_size.x*maze_size.y)
	rtn.DonutCapsuleCount = max(2, maze_size.x*maze_size.y/20.0)
	rtn.TreeCount = max(1, maze_size.x*maze_size.y/50.0)
	rtn.MakeLine2DWallRate = 1.0/(maze_size.x*maze_size.y)
	rtn.MakeClockCalWallRate = 1.0/(maze_size.x*maze_size.y)
	return rtn

static func new_deco() -> StoreySetting:
	var rtn := new()
	rtn.MeshTrailTypeList = [ [0,1,2,3,4,5,"♠","♣","♥","♦","★","☆","♩","♪","♬"].pick_random() ]
	rtn.MakeMeshTrailRate = 0.5
	rtn.DonutCapsuleCount = 0
	rtn.TreeCount = 1
	rtn.MakeLine2DWallRate = 0
	rtn.MakeClockCalWallRate = 0
	return rtn

func _to_string() -> String:
	return "StoreySetting[ball trail:%d donnut capsule:%d tree:%d]" % [
		MeshTrailTypeList.size(), DonutCapsuleCount, TreeCount,
	]

var MeshTrailTypeList :Array
var MakeMeshTrailRate :float
var DonutCapsuleCount :int
var TreeCount :int
var MakeLine2DWallRate :float
var MakeClockCalWallRate :float

func duplicate(deep :bool = false) -> StoreySetting:
	var rtn := new()
	if deep:
		rtn.MeshTrailTypeList = MeshTrailTypeList.duplicate()
	else:
		rtn.MeshTrailTypeList = MeshTrailTypeList
	rtn.MakeMeshTrailRate = MakeMeshTrailRate
	rtn.DonutCapsuleCount = DonutCapsuleCount
	rtn.TreeCount = TreeCount
	rtn.MakeLine2DWallRate = MakeLine2DWallRate
	rtn.MakeClockCalWallRate = MakeClockCalWallRate
	return rtn
