extends Node3D

class_name AnalogClock3D

enum BarAlign {None, In,Mid,Out}
enum NumberType {None, Hour,Minute,Degree}

var tz_shift :float
var hour_hand_base :Node3D
var minute_hand_base :Node3D
var second_hand_base :Node3D

func init(r :float, d :float, fsize :float, tzs :float = 9.0, backplane:bool=true) -> void:
	tz_shift = tzs

	if backplane:
		var plane = Global3d.new_cylinder(d*0.5, r,r, Global3d.get_color_mat(Global3d.colors.clockbg ) )
		plane.position.y = -d*0.25
		add_child(plane)

	make_hands(r, d)
	make_dial_bar_multi(r*0.88, d, BarAlign.Mid)
	#make_dial_bar(r*0.88, d, BarAlign.Mid)
	make_dial_num(r*0.95, d, fsize*0.8, NumberType.Minute)
	make_dial_num(r*0.8, d, fsize, NumberType.Hour)

	var cc = Global3d.new_cylinder(d*0.5,r/50,r/50, Global3d.get_color_mat(Global3d.colors.center_circle1))
	cc.position.y = d*0.5/2
	add_child(cc)
	var cc2 = Global3d.new_torus(r/20, r/40, Global3d.get_color_mat(Global3d.colors.center_circle2))
	cc2.position.y = d*0.5/2
	add_child( cc2 )

func _process(_delta: float) -> void:
	update_clock()

func make_hands(r :float, d:float)->void:
	var hand_height = d*0.1
	hour_hand_base = make_hand(Global3d.colors.hour ,Vector3(r*0.75,hand_height,r/36))
	hour_hand_base.position.y = hand_height*1

	minute_hand_base = make_hand(Global3d.colors.minute, Vector3(r*0.88,hand_height,r/54))
	minute_hand_base.position.y = hand_height*2

	second_hand_base = make_hand(Global3d.colors.second, Vector3(r*1.0,hand_height,r/72))
	second_hand_base.position.y = hand_height*3

func make_hand(co :Color, hand_size: Vector3)->Node3D:
	var hand_base = Node3D.new()
	add_child(hand_base)
	var hand = Global3d.new_box(hand_size, Global3d.get_color_mat(co))
	hand.position.x = hand_size.x / 2
	hand_base.add_child(hand)
	return hand_base

func make_dial_bar(r :float, d:float, align :BarAlign):
	var mat = Global3d.get_color_mat(Global3d.colors.dial_1)
	var bar_height = d*0.2
	var bar_size :Vector3
	for i in 360 :
		var rad = deg_to_rad(-i+90)
		var bar_center = Vector3(sin(rad)*r,bar_height/2, cos(rad)*r)
		if i % 30 == 0 :
			bar_size = Vector3(r/18,bar_height,r/180)
		elif i % 6 == 0 :
			bar_size = Vector3(r/24,bar_height,r/480)
		else :
			bar_size = Vector3(r/72,bar_height,r/720)
		var bar_rot = deg_to_rad(-i)
		var bar = Global3d.new_box(bar_size, mat)
		bar.rotation.y = bar_rot
		match align:
			BarAlign.In :
				bar.position = bar_center*(1 - bar_size.x/r/2)
			BarAlign.Mid :
				bar.position = bar_center
			BarAlign.Out :
				bar.position = bar_center*(1 + bar_size.x/r/2)
		bar.position.y = bar_height/2
		add_child(bar)

var multi_bar :MultiMeshInstance3D
func make_dial_bar_multi(r :float, d:float, align :BarAlign):
	var mat = Global3d.get_color_mat(Global3d.colors.dial_1)
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1,1,1)
	mesh.material = mat

	# Create the multimesh.
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	# Set the format first.
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Then resize (otherwise, changing the format is not allowed).
	multimesh.instance_count = 360
	# Maybe not all of them should be visible at first.
	multimesh.visible_instance_count = 360

	# Set the transform of the instances.
	var bar_height = d*0.2
	var bar_size :Vector3
	for i in multimesh.visible_instance_count:
		var rad = deg_to_rad(-i+90)
		var bar_center = Vector3(sin(rad)*r,bar_height/2, cos(rad)*r)
		var bar_rotation = Vector3(0,0,0)
		var bar_position = Vector3(0,0,0)
		if i % 30 == 0 :
			bar_size = Vector3(r/18,bar_height,r/180)
		elif i % 6 == 0 :
			bar_size = Vector3(r/24,bar_height,r/480)
		else :
			bar_size = Vector3(r/72,bar_height,r/720)
		var bar_rot = deg_to_rad(-i)
		bar_rotation.y = bar_rot
		match align:
			BarAlign.In :
				bar_position = bar_center*(1 - bar_size.x/r/2)
			BarAlign.Mid :
				bar_position = bar_center
			BarAlign.Out :
				bar_position = bar_center*(1 + bar_size.x/r/2)
		bar_position.y = bar_height/2
		# make transform from bar_rotation, bar_position, bar_size
		var tr = Transform3D(Basis(), bar_position)
		tr = tr.rotated_local(Vector3(0,1,0), bar_rot)
		tr = tr.scaled_local( bar_size )
		multimesh.set_instance_transform(i,tr )

	multi_bar = MultiMeshInstance3D.new()
	multi_bar.multimesh = multimesh
	add_child(multi_bar)

func make_dial_num(r :float, d:float, fsize :float, nt :NumberType)->void:
	var mat = Global3d.get_color_mat(Global3d.colors.dial_num)
	var bar_height = d*0.2
	match nt:
		NumberType.Hour:
			for i in range(1,13):
				var rad = deg_to_rad( -i*(360.0/12.0) +90)
				var bar_center = Vector3(sin(rad)*r,bar_height/2, cos(rad)*r)
				var t = Global3d.new_text(fsize, bar_height, mat, "%d" % [i])
				t.rotation = Vector3(-PI/2,0,-PI/2)
				t.position = bar_center
				add_child(t)
		NumberType.Minute:
			for i in range(0,60,5):
				var rad = deg_to_rad( -i*(360.0/60.0) +90)
				var bar_center = Vector3(sin(rad)*r,bar_height/2, cos(rad)*r)
				var t = Global3d.new_text(fsize, bar_height, mat, "%d" % [i])
				t.rotation = Vector3(-PI/2,0,-PI/2)
				t.position = bar_center
				add_child(t)
		NumberType.Degree:
			for i in range(0,360,30):
				var rad = deg_to_rad( -i*(360.0/360.0) +90)
				var bar_center = Vector3(sin(rad)*r,bar_height/2, cos(rad)*r)
				var t = Global3d.new_text(fsize, bar_height, mat, "%d" % [i])
				t.rotation = Vector3(-PI/2,0,-PI/2)
				t.position = bar_center
				add_child(t)

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

