extends Node2D

var draw_area_size :Vector2

var line_cursor :int
var line_width = 1

var point_count :int
var color_list :PackedColorArray
var velocity_list :PackedVector2Array
var auto_move :float

func init(ln_count :int, pt_count :int, dsize :Vector2, amove :float = 1.0/60.0 ):
	point_count = pt_count
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

func _process(delta: float) -> void:
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
	for i in velocity_list.size():
		ln.points[i] += velocity_list[i] *delta
		var bn = bounce(ln.points[i],velocity_list[i],draw_area_size,ln.width/2)
		ln.points[i] = bn.position
		velocity_list[i] = bn.velocity

		# change vel on bounce
		if bn.xbounce != 0 :
			velocity_list[i].x = -random_positive(draw_area_size.x/2)*bn.xbounce
			bounced = true
		if bn.ybounce != 0 :
			velocity_list[i].y = -random_positive(draw_area_size.y/2)*bn.ybounce
			bounced = true
	if bounced :
		color_list = make_color_list(point_count)

	ln.gradient.colors = color_list

# util functions

func bounce(pos :Vector2,vel :Vector2, bound :Vector2, radius :float)->Dictionary:
	var xbounce = 0
	var ybounce = 0
	if pos.x <  radius :
		pos.x =  radius
		vel.x = abs(vel.x)
		xbounce = -1
	elif pos.x > bound.x - radius:
		pos.x = bound.x - radius
		vel.x = -abs(vel.x)
		xbounce = 1
	if pos.y < radius :
		pos.y = radius
		vel.y = abs(vel.y)
		ybounce = -1
	elif pos.y > bound.y - radius:
		pos.y = bound.y - radius
		vel.y = -abs(vel.y)
		ybounce = 1
	return {
		position = pos,
		velocity = vel,
		xbounce = xbounce,
		ybounce = ybounce,
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
