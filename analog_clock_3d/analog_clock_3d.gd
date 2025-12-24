extends Node3D
class_name AnalogClock3D

enum BarAlign {None, In,Mid,Out}
enum NumberType {None, Hour,Minute,Degree}

var font := preload("res://font/HakgyoansimBareondotumR.ttf")

# for calendar
var colors := {
	# analog clock
	hour = Color.ROYAL_BLUE,
	minute = Color.MEDIUM_SPRING_GREEN,
	second = Color.ORANGE_RED,
	center_circle1 = Color.PALE_GOLDENROD,
	center_circle2 = Color.LIGHT_GOLDENROD,
	dial_num = Color.LIGHT_GRAY,
	dial_1 = Color.WHEAT,
	clockbg = Color.BLACK.lightened(0.3),
}

var tz_shift :float

func init(r :float, d :float, fsize :float, tzs :float = 9.0, backplane:bool=true) -> AnalogClock3D:
	tz_shift = tzs

	$BackPlane.mesh.height = d*0.5
	$BackPlane.mesh.top_radius = r
	$BackPlane.mesh.bottom_radius = r
	$BackPlane.mesh.material.albedo_color = colors.clockbg
	$BackPlane.position.y = -d*0.25
	$Center.mesh.height = d*0.5
	$Center.mesh.top_radius = r/50
	$Center.mesh.bottom_radius = r/50
	$Center.mesh.material.albedo_color = colors.center_circle1
	$Center.position.y = d*0.5/2
	$Donut.mesh.outer_radius = r/20.0
	$Donut.mesh.inner_radius = r/40.0
	$Donut.mesh.material.albedo_color = colors.center_circle2
	$Donut.position.y = d*0.5/2

	if backplane:
		$BackPlane.visible = true

	make_hands(r, d)
	make_dial_bar_multi(r*0.88, d, BarAlign.Mid)
	make_dial_num(r*0.95, d, fsize*0.8, NumberType.Minute)
	make_dial_num(r*0.8, d, fsize, NumberType.Hour)

	return self

func make_hands(r :float, d:float)->void:
	$HourBase/HourHand.mesh.material.albedo_color = colors.hour
	$MinuteBase/MinuteHand.mesh.material.albedo_color = colors.minute
	$SecondBase/SecondHand.mesh.material.albedo_color = colors.second

	var hand_height := d*0.1
	$HourBase/HourHand.mesh.size = Vector3(r*0.75,hand_height,r/36)
	$MinuteBase/MinuteHand.mesh.size = Vector3(r*0.88,hand_height,r/54)
	$SecondBase/SecondHand.mesh.size = Vector3(r*1.0,hand_height,r/72)
	$HourBase/HourHand.position.x = r*0.75 /2
	$MinuteBase/MinuteHand.position.x = r*0.88 /2
	$SecondBase/SecondHand.position.x = r*1.0 /2

	$HourBase.position.y = hand_height*1
	$MinuteBase.position.y = hand_height*2
	$SecondBase.position.y = hand_height*3

#var multi_bar :MultiMeshShape
func make_dial_bar_multi(r :float, d:float, align :BarAlign):
	$DialBars.init_with_alpha(BoxMesh.new(), 360, 1.0)
	$DialBars.set_gradient_color_all(colors.dial_1,colors.dial_1)
	# Set the transform of the instances.
	var bar_height := d*0.2
	var bar_size :Vector3
	for i in $DialBars.get_visible_count():
		var rad := deg_to_rad(-i+90)
		var bar_center := Vector3(sin(rad)*r,bar_height/2, cos(rad)*r)
		var bar_rotation := Vector3.ZERO
		var bar_position := Vector3.ZERO
		if i % 30 == 0 :
			bar_size = Vector3(r/18,bar_height,r/180)
		elif i % 6 == 0 :
			bar_size = Vector3(r/24,bar_height,r/480)
		else :
			bar_size = Vector3(r/72,bar_height,r/720)
		var bar_rot := deg_to_rad(-i)
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
		var t := Transform3D(Basis(), bar_position)
		t = t.rotated_local(Vector3.UP, bar_rot)
		t = t.scaled_local( bar_size )
		$DialBars.multimesh.set_instance_transform(i,t)

func make_dial_num(r :float, d:float, fsize :float, nt :NumberType)->void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colors.dial_num
	var bar_height := d*0.2
	match nt:
		NumberType.Hour:
			for i in range(1,13):
				var rad := deg_to_rad( -i*(360.0/12.0) +90)
				var bar_center := Vector3(sin(rad)*r,bar_height/2, cos(rad)*r)
				var t := new_text(fsize, bar_height, mat, "%d" % [i])
				t.rotation = Vector3(-PI/2,0,-PI/2)
				t.position = bar_center
				add_child(t)
		NumberType.Minute:
			for i in range(0,60,5):
				var rad := deg_to_rad( -i*(360.0/60.0) +90)
				var bar_center := Vector3(sin(rad)*r,bar_height/2, cos(rad)*r)
				var t := new_text(fsize, bar_height, mat, "%d" % [i])
				t.rotation = Vector3(-PI/2,0,-PI/2)
				t.position = bar_center
				add_child(t)
		NumberType.Degree:
			for i in range(0,360,30):
				var rad := deg_to_rad( -i*(360.0/360.0) +90)
				var bar_center := Vector3(sin(rad)*r,bar_height/2, cos(rad)*r)
				var t := new_text(fsize, bar_height, mat, "%d" % [i])
				t.rotation = Vector3(-PI/2,0,-PI/2)
				t.position = bar_center
				add_child(t)

func new_text(fsize :float, fdepth :float, mat :Material, text :String) -> MeshInstance3D:
	var mesh := TextMesh.new()
	mesh.font = font
	mesh.depth = fdepth
	mesh.pixel_size = fsize / 16
	mesh.text = text
	mesh.material = mat
	var sp := MeshInstance3D.new()
	sp.mesh = mesh
	return sp


func _process(_delta: float) -> void:
	update_clock()

func update_clock():
	var ms := Time.get_unix_time_from_system()
	var second := ms - int(ms/60)*60
	ms = ms / 60
	var minute := ms - int(ms/60)*60
	ms = ms / 60
	var hour := ms - int(ms/24)*24 + tz_shift
	$SecondBase.rotation.y = -second2rad(second)
	$MinuteBase.rotation.y = -minute2rad(minute)
	$HourBase.rotation.y = -hour2rad(hour)

func second2rad(sec :float) -> float:
	return 2.0*PI/60.0*sec

func minute2rad(m :float) -> float:
	return 2.0*PI/60.0*m

func hour2rad(hour :float) -> float:
	return 2.0*PI/12.0*hour
