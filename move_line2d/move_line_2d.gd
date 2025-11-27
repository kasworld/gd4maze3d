extends Node2D

class_name MoveLine2D

var rng :RandomNumberGenerator
var draw_area_size :Vector2
var line_cursor :int
var line_width :float
var point_count :int
var line_count :int
var color_list :PackedColorArray
var velocity_list :PackedVector2Array
var init_point_list :PackedVector2Array
var move_speed :float
var auto_move :bool

func init_with_random(ln_count :int, pt_count :int, w:float, dsize :Vector2, amovespd :float = 1.0/60.0 ) -> MoveLine2D:
	rng = RandomNumberGenerator.new()
	point_count = pt_count
	line_width = w
	line_count = ln_count
	draw_area_size = dsize
	move_speed = amovespd
	velocity_list = make_vel_list(point_count, draw_area_size)
	color_list = make_color_list(point_count)
	init_point_list = make_point_list(point_count, draw_area_size)
	for i in line_count:
		var ln := Line2D.new()
		ln.points = init_point_list
		ln.gradient = Gradient.new()
		ln.gradient.colors = color_list
		ln.width = line_width
		$LineContainer.add_child(ln)
	return self

func init_with_copy(other :MoveLine2D) -> MoveLine2D:
	rng = RandomNumberGenerator.new()
	rng.seed = other.rng.seed
	point_count = other.point_count
	line_width = other.line_width
	line_count = other.line_count
	draw_area_size = other.draw_area_size
	move_speed = other.move_speed
	velocity_list = other.velocity_list.duplicate()
	color_list = other.color_list.duplicate()
	init_point_list = other.init_point_list.duplicate()
	for i in line_count:
		var ln := Line2D.new()
		ln.points = init_point_list
		ln.gradient = Gradient.new()
		ln.gradient.colors = color_list
		ln.width = line_width
		$LineContainer.add_child(ln)
	return self

func start() -> void:
	auto_move = true

func stop() -> void:
	auto_move = false

func _process(_delta: float) -> void:
	if auto_move:
		move_1_step()

func move_1_step() -> void:
	var old_line_points = $LineContainer.get_child(line_cursor).points.duplicate()
	line_cursor +=1
	line_cursor %= $LineContainer.get_child_count()
	$LineContainer.get_child(line_cursor).points = old_line_points
	move_line(move_speed, $LineContainer.get_child(line_cursor))

func move_line(delta: float, ln :Line2D) -> void:
	var bounced := false
	var rt := Rect2(Vector2.ZERO, draw_area_size)
	for i in velocity_list.size():
		ln.points[i] += velocity_list[i] *delta
		var bn := bounce2d(rt,ln.points[i],ln.width/2)
		ln.points[i] = bn.pos
		# change vel on bounce
		for j in 2:
			if bn.bounced[j] != 0 :
				velocity_list[i][j] = -random_positive(draw_area_size[j]/2)*bn.bounced[j]
				bounced = true
	if bounced :
		color_list = make_color_list(point_count)

	ln.gradient.colors = color_list

# util functions

func bounce2d(rt :Rect2, pos :Vector2, radius :float) -> Dictionary:
	var bounced := Vector3i.ZERO
	for i in 2:
		if pos[i] < rt.position[i] + radius :
			pos[i] = rt.position[i] + radius
			bounced[i] = -1
		elif pos[i] > rt.end[i] - radius:
			pos[i] = rt.end[i] - radius
			bounced[i] = 1
	return {
		bounced = bounced,
		pos = pos,
	}

func make_point_list(count :int, rt :Vector2) -> PackedVector2Array:
	var rtn :PackedVector2Array = []
	for j in count:
		rtn.append(random_pos_vector2d(rt))
	return rtn

func random_pos_vector2d(rt :Vector2) -> Vector2:
	return Vector2( rng.randf_range(0,rt.x), rng.randf_range(0,rt.y) )

func make_vel_list(count :int, rt :Vector2) -> PackedVector2Array:
	var rtn :PackedVector2Array = []
	for i in  count:
		rtn.append(random_vel_vector2d(rt))
	return rtn

func random_vel_vector2d(rt :Vector2) -> Vector2:
	return Vector2(random_no_zero(rt.x),random_no_zero(rt.y))

func random_no_zero(w :float) -> float:
	var v := random_positive(w/2)
	match rng.randi_range(1,2):
		1:
			pass
		2:
			v = -v
	return v

func random_positive(w :float) -> float:
	return rng.randf_range(w/10,w)

func make_color_list(count :int) -> PackedColorArray:
	var rtn :PackedColorArray = []
	for j in count:
		rtn.append(random_color())
	return rtn

func random_color() -> Color:
	return Color(rng.randf(),rng.randf(),rng.randf())
