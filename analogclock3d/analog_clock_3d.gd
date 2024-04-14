extends Node3D

var tz_shift :float

var hour_hand_base :Node3D
var minute_hand_base :Node3D
var second_hand_base :Node3D

func init(r :float, tzs :float = 9.0) -> void:
	tz_shift = tzs
	var plane = Global3d.new_cylinder( r/60,  r,r, Global3d.get_color_mat(Global3d.colors.clockbg ) )
	plane.position.y = -r/60
	add_child(plane)

	make_hands(r)
	make_dial(r)

	var cc = Global3d.new_cylinder(r/30,r/50,r/50, Global3d.get_color_mat(Global3d.colors.center_circle1))
	cc.position.y = r/30/2
	add_child(cc)
	var cc2 = Global3d.new_torus(r/20, r/40, Global3d.get_color_mat(Global3d.colors.center_circle2))
	#cc2.position.y = r/20/2
	add_child( cc2 )

func _process(_delta: float) -> void:
	update_clock()

func make_hands(r :float)->void:
	var hand_height = r/180
	hour_hand_base = make_hand(Global3d.colors.hour ,Vector3(r*0.8,hand_height,r/36))
	hour_hand_base.position.y = hand_height*1

	minute_hand_base = make_hand(Global3d.colors.minute, Vector3(r*1.0,hand_height,r/54))
	minute_hand_base.position.y = hand_height*2

	second_hand_base = make_hand(Global3d.colors.second, Vector3(r*1.3,hand_height,r/72))
	second_hand_base.position.y = hand_height*3

func make_hand(co :Color, hand_size: Vector3)->Node3D:
	var hand_base = Node3D.new()
	add_child(hand_base)
	var hand = Global3d.new_box(hand_size, Global3d.get_color_mat(co))
	hand.position.x = hand_size.x / 4
	hand_base.add_child(hand)
	return hand_base

func make_dial(r :float):
	var mat = Global3d.get_color_mat(Global3d.colors.dial_1)
	var num_mat = Global3d.get_color_mat(Global3d.colors.dial_num)
	var bar_height = r/180
	var bar_size :Vector3
	for i in 360 :
		var bar_center = Vector3(sin(deg_to_rad(-i+90))*r,bar_height/2, cos(deg_to_rad(-i+90))*r)
		if i % 30 == 0 :
			bar_size = Vector3(r/18,bar_height,r/180)
			if i == 0 :
				add_child(new_dial_num(r,bar_center, num_mat,"12"))
			else:
				add_child(new_dial_num(r,bar_center, num_mat, "%d" % [i/30] ))
		elif i % 6 == 0 :
			bar_size = Vector3(r/24,bar_height,r/480)
		else :
			bar_size = Vector3(r/72,bar_height,r/720)
		var bar_rot = deg_to_rad(-i)
		var bar = Global3d.new_box(bar_size, mat)
		bar.rotation.y = bar_rot
		bar.position = bar_center - bar_center*(bar_size.length()/bar_center.length())/2
		bar.position.y = bar_height/2
		add_child(bar)

func new_dial_num(r :float, p :Vector3, mat :Material, text :String)->MeshInstance3D:
	var t = Global3d.new_text(r/4,r/20, mat, text)
	t.rotation.x = deg_to_rad(-90)
	#t.rotation.y = deg2rad(90)
	t.rotation.z = deg_to_rad(-90)
	t.position = p *0.85
	return t

func update_clock():
	var ms = Time.get_unix_time_from_system()
	var second = ms - int(ms/60)*60
	ms = ms / 60
	var minute = ms - int(ms/60)*60
	ms = ms / 60
	var hour = ms - int(ms/24)*24 + tz_shift
	second_hand_base.rotation.y = -second2rad(second)
	minute_hand_base.rotation.y = -minute2rad(minute)
	hour_hand_base.rotation.y = -hour2rad(hour)

func second2rad(sec :float) -> float:
	return 2.0*PI/60.0*sec

func minute2rad(m :float) -> float:
	return 2.0*PI/60.0*m

func hour2rad(hour :float) -> float:
	return 2.0*PI/12.0*hour

