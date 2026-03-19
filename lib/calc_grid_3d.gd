class_name CalcGrid3D

var boundary :AABB
var grid_size :Vector3i
var unit_size :Vector3

func _to_string() -> String:
	return "boundary %s gridsize %s unitsize %s" % [boundary,grid_size,unit_size]

static func xy_Vector2iToVector3i(vt2i :Vector2i, z :int) -> Vector3i:
	return Vector3i(vt2i.x, vt2i.y, z)

static func xy_Vector3iToVector2i(vt3i :Vector3i) -> Vector2i:
	return Vector2i(vt3i.x, vt3i.y)

static func xz_Vector2iToVector3i(vt2i :Vector2i, y :int) -> Vector3i:
	return Vector3i(vt2i.x, y, vt2i.y)

static func xz_Vector3iToVector2i(vt3i :Vector3i) -> Vector2i:
	return Vector2i(vt3i.x, vt3i.z)


static func SizeToAABB(size :Vector3) -> AABB:
	return AABB(-size/2, size)

func _init(b_rect :AABB, g_size :Vector3i) -> void:
	boundary = b_rect
	grid_size = g_size
	unit_size = boundary.size / (grid_size as Vector3)

func get_grid_count() -> int:
	return grid_size.x * grid_size.y * grid_size.z

func has_point(pos :Vector3) -> bool:
	return boundary.has_point(pos)

func posi_to_linepos(posi :Vector3i) -> Vector3:
	return boundary.position + (posi as Vector3)* unit_size

func linepos_to_posi(pos :Vector3) -> Vector3i:
	return  ((pos - boundary.position) / unit_size).snappedf(1.0) as Vector3i

func posi_to_lanepos(posi :Vector3i) -> Vector3:
	return boundary.position + (posi as Vector3)* unit_size + unit_size/2

func lanepos_to_posi(pos :Vector3) -> Vector3i:
	return  ((pos - boundary.position - unit_size/2) / unit_size).snappedf(1.0) as Vector3i

func cell_aabb_by_posi(posi :Vector3i) -> AABB:
	return AABB(
		posi_to_linepos(posi),
		unit_size,
	)

## fn(index:int, xi:int, yi:int, zi:int) -> void [br]
## for z : for y : for x:
func iter_ixyz(fn :Callable) -> void:
	var index := 0
	for zi in grid_size.z:
		for yi in grid_size.y:
			for xi in grid_size.x:
				fn.call(index,xi,yi,zi)
				index += 1

func rate_posi(posi :Vector3i) -> Vector3:
	return (posi as Vector3) / (grid_size as Vector3 - Vector3.ONE)

func rate_xi(xi :int) -> float:
	return float(xi) / float(grid_size.x-1)

func rate_yi(yi :int) -> float:
	return float(yi) / float(grid_size.y-1)

func rate_zi(zi :int) -> float:
	return float(zi) / float(grid_size.z-1)


## inverse get_n_th_posi
func get_index_by_posi_xyz(x :int, y :int, z :int=0) -> int:
	return x + (y *grid_size.x) + (z * grid_size.x * grid_size.y)

## iter x -> y -> z order
func get_n_th_posi(n :int) -> Vector3i:
	var z :int = n / (grid_size.x * grid_size.y)
	var y :int = (n / grid_size.x) % grid_size.y
	var x :int = n % grid_size.x
	return Vector3i(x,y,z)

func get_n_th_lanepos(n :int) -> Vector3:
	return posi_to_lanepos(get_n_th_posi(n))

func get_n_th_linepos(n :int) -> Vector3:
	return posi_to_linepos(get_n_th_posi(n))

func rand_posi() -> Vector3i:
	return Vector3i(
		randi_range(0,grid_size.x-1),
		randi_range(0,grid_size.y-1),
		randi_range(0,grid_size.z-1),
		)
