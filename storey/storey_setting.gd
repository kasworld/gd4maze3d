class_name StoreySetting

var MeshTrailTypeList :Array
var MakeMeshTrailRate :float
var DonutCapsuleCount :int
var TreeCount :int

func duplicate(deep :bool = false) -> StoreySetting:
	var rtn := new()
	if deep:
		rtn.MeshTrailTypeList = MeshTrailTypeList.duplicate()
	else:
		rtn.MeshTrailTypeList = MeshTrailTypeList
	rtn.MakeMeshTrailRate = MakeMeshTrailRate
	rtn.DonutCapsuleCount = DonutCapsuleCount
	rtn.TreeCount = TreeCount
	return rtn

func make_default(maze_size :Vector2i) -> StoreySetting:
	MeshTrailTypeList = ["♠","♣","♥","♦","★"]
	MakeMeshTrailRate = 2.0/(maze_size.x*maze_size.y)
	DonutCapsuleCount = max(2, maze_size.x*maze_size.y/20.0)
	TreeCount = max(1, maze_size.x*maze_size.y/50.0)
	return self 

func make_deco() -> StoreySetting:
	MeshTrailTypeList = [ [0,1,2,3,4,5,"♠","♣","♥","♦","★","☆","♩","♪","♬"].pick_random() ]
	MakeMeshTrailRate = 0.5
	DonutCapsuleCount = 1
	TreeCount = 1
	return self 

func _to_string() -> String:
	return "StoreySetting[ball trail:%d donnut capsule:%d tree:%d]" % [
		MeshTrailTypeList.size(), DonutCapsuleCount, TreeCount,
	]
