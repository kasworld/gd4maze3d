class_name PlatonicSolids

const GoldenRatio :float = (1+sqrt(5))/2

## key : face count , value : point list , edge count per vertex
const PointEdge = {
	4 : [TetrahedronPoints, 3],
	6 : [CubePoints, 3],
	8 : [OctahedronPoints, 4],
	12 : [DodecahedronPoints, 3],
	20 : [IcosahedronPoints, 5],
}

## face 4
const TetrahedronPoints := [
	Vector3(1,1,1),
	Vector3(1,-1,-1),
	Vector3(-1,1,-1),
	Vector3(-1,-1,1),
]

## face 6
const CubePoints := [
	Vector3(1,1,1),
	Vector3(-1,1,1),
	Vector3(1,-1,1),
	Vector3(-1,-1,1),
	Vector3(1,1,-1),
	Vector3(-1,1,-1),
	Vector3(1,-1,-1),
	Vector3(-1,-1,-1),
]

## face 8
const OctahedronPoints := [
	Vector3(1,0,0),
	Vector3(0,1,0),
	Vector3(0,0,1),
	Vector3(-1,0,0),
	Vector3(0,-1,0),
	Vector3(0,0,-1),
]

## face 12
const DodecahedronPoints := [
	Vector3(1,1,1),
	Vector3(-1,1,1),
	Vector3(1,-1,1),
	Vector3(-1,-1,1),
	Vector3(1,1,-1),
	Vector3(-1,1,-1),
	Vector3(1,-1,-1),
	Vector3(-1,-1,-1),
	Vector3(0, 1/GoldenRatio, GoldenRatio),
	Vector3(0, -1/GoldenRatio, GoldenRatio),
	Vector3(0, 1/GoldenRatio, -GoldenRatio),
	Vector3(0, -1/GoldenRatio, -GoldenRatio),
	Vector3(1/GoldenRatio, GoldenRatio, 0),
	Vector3(-1/GoldenRatio, GoldenRatio, 0),
	Vector3(1/GoldenRatio, -GoldenRatio, 0),
	Vector3(-1/GoldenRatio, -GoldenRatio, 0),
	Vector3(GoldenRatio, 0, 1/GoldenRatio),
	Vector3(GoldenRatio, 0, -1/GoldenRatio),
	Vector3(-GoldenRatio, 0, 1/GoldenRatio),
	Vector3(-GoldenRatio, 0, -1/GoldenRatio),
]

## face 20
const IcosahedronPoints :Array = [
	Vector3(0,1,GoldenRatio),
	Vector3(0,-1,GoldenRatio),
	Vector3(0,1,-GoldenRatio),
	Vector3(0,-1,-GoldenRatio),
	Vector3(1,GoldenRatio,0),
	Vector3(-1,GoldenRatio,0),
	Vector3(1,-GoldenRatio,0),
	Vector3(-1,-GoldenRatio,0),
	Vector3(GoldenRatio,0,1),
	Vector3(GoldenRatio,0,-1),
	Vector3(-GoldenRatio,0,1),
	Vector3(-GoldenRatio,0,-1),
]

## nomalize and multiply,  m can float, Vector3
static func ScalePointList(point_list :Array, m ) -> Array:
	var rtn := []
	for l :Vector3 in point_list:
		rtn.append(l.normalized()*m)
	return rtn

static func NormalizePointList(point_list :Array) -> Array:
	var rtn := []
	for l :Vector3 in point_list:
		rtn.append(l.normalized())
	return rtn

## m can float, Vector3
static func MultiplyPointList(point_list :Array, m ) -> Array:
	var rtn := []
	for l in point_list:
		rtn.append(l*m)
	return rtn

## cut_count : edge count per vertex
static func PointListToLineList(point_list:Array, cut_count :int) -> Array:
	var sorted_point_list_list := []
	# 각 배열의 첫 원소와 가장 가까운 순으로 점들을 정렬한다.
	for p :Vector3 in point_list:
		var plist := point_list.duplicate()
		plist.sort_custom(func(a , b): return p.distance_to(a) < p.distance_to(b))
		sorted_point_list_list.append(plist)
	# make_line_from_sorted_point_list_list
	var line_list := []
	for v in sorted_point_list_list:
		for i in min(cut_count, v.size()-1):
			# prepare del duplicated line
			if v[0] < v[1+i]:
				line_list.append([v[0], v[1+i]])
			else:
				line_list.append([v[1+i], v[0]])
	line_list.sort_custom(func(a,b): return a < b)
	var rtn := []
	# del duplicated line
	for i in range(0,line_list.size(),2):
		rtn.append(line_list[i])
	return rtn
