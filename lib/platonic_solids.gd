class_name PlatonicSolids

const GoldenRatio :float = (1+sqrt(5))/2

## key : face count , value : point list , edge count per vertex
const PointEdge = {
	4 : [TetrahedronPoints, 3, 3, 3],
	6 : [CubePoints, 3, 6, 7],
	8 : [OctahedronPoints, 4, 5, 5],
	12 : [DodecahedronPoints, 3, 9, 18, 19], # ??
	20 : [IcosahedronPoints, 5, 10, 11],
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

# 모든 점에 대해서 거리순으로 정렬한 목록을 만든다.
static func sort_point_by_len(point_list:Array) -> Array:
	var sorted_point_list_list := []
	# 각 배열의 첫 원소와 가장 가까운 순으로 점들을 정렬한다.
	for p :Vector3 in point_list:
		var plist := point_list.duplicate()
		plist.sort_custom(func(a , b): return p.distance_to(a) < p.distance_to(b))
		sorted_point_list_list.append(plist)
	return sorted_point_list_list

## cut_count : edge count per vertex
static func PointListToLineList(point_list:Array, cut_count :int) -> Array:
	return PointListToLineList2(point_list,0,cut_count)

static func PointListToLineList2(point_list:Array, begin :int, end :int) -> Array:
	var line_list := []
	for v in sort_point_by_len(point_list):
		line_list.append_array(make_lines_from_1st_point(v).slice(begin,end))
	return sort_and_del_duplicate_line(line_list)


static func make_lines_from_1st_point(point_list:Array) -> Array:
	var lines := []
	var p0 :Vector3 = point_list[0]
	for v in  point_list.slice(1):
		# prepare del duplicated line
		if p0 < v:
			lines.append([p0, v])
		else:
			lines.append([v, p0])
	return lines

static func sort_and_del_duplicate_line(line_list :Array) -> Array:
	line_list.sort_custom(func(a,b): return a < b)
	var rtn := [line_list[0]]
	# del duplicated line
	for i in line_list.size():
		if line_list[i] == rtn[-1]:
			continue
		rtn.append(line_list[i])
	return rtn
