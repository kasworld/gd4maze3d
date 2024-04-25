extends Node2D

var draw_area_size :Vector2

var line_cursor :int
var line_width :float

var point_count :int
var color_list :PackedColorArray
var velocity_list :PackedVector2Array
var auto_move :float

func init(ln_count :int, pt_count :int, w:float, dsize :Vector2, amove :float = 1.0/60.0 ):
	point_count = pt_count
	line_width = w
	draw_area_size = dsize
	auto_move = amove

	velocity_list = make_vel_list(point_count, draw_area_size)
	color_list = make_color_list(point_count)
	var point_list = make_point_list(point_count, draw_area_size)
	for i in ln_count:
		var ln = Line2D.new()
		ln.points = point_list
		ln.gradient = Gradient.new()
		ln.gradient.colors = color_list
		ln.width = line_width
		$LineContainer.add_child(ln)

func _process(_delta: float) -> void:
	if auto_move != 0.0:
		move(auto_move)

func move(delta :float)->void:
	var old_line_points = $LineContainer.get_child(line_cursor).points.duplicate()
	line_cursor +=1
	line_cursor %= $LineContainer.get_child_count()
	$LineContainer.get_child(line_cursor).points = old_line_points
	move_line(delta, $LineContainer.get_child(line_cursor))

func move_line(delta: float, ln :Line2D) -> void:
	var bounced = false
	var rt = Rect2(Vector2.ZERO, draw_area_size)
	for i in velocity_list.size():
		ln.points[i] += velocity_list[i] *delta
		var bn = bounce2d(rt,ln.points[i],ln.width/2)
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

func bounce2d(rt :Rect2, pos :Vector2, radius :float)->Dictionary:
	var bounced = Vector3i.ZERO
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

func make_point_list(count :int, rt :Vector2)->PackedVector2Array:
	var rtn = []
	for j in count:
		rtn.append(random_pos_vector2d(rt))
	return rtn

func random_pos_vector2d(rt :Vector2)->Vector2:
	return Vector2( randf_range(0,rt.x), randf_range(0,rt.y) )

func make_vel_list(count :int, rt :Vector2)->PackedVector2Array:
	var rtn = []
	for i in  count:
		rtn.append(random_vel_vector2d(rt))
	return rtn

func random_vel_vector2d(rt :Vector2)->Vector2:
	return Vector2(random_no_zero(rt.x),random_no_zero(rt.y))

func random_no_zero(w :float)->float:
	var v = random_positive(w/2)
	match randi_range(1,2):
		1:
			pass
		2:
			v = -v
	return v

func random_positive(w :float)->float:
	return randf_range(w/10,w)

func make_color_list(count :int)->PackedColorArray:
	var rtn = []
	for j in count:
		rtn.append(random_color())
	return rtn

func random_color()->Color:
	return Color(randf(),randf(),randf())
