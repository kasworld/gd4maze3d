extends Node3D
class_name Calendar3D

var font := preload("res://font/HakgyoansimBareondotumR.ttf")
const weekdaystring := ["일","월","화","수","목","금","토"]
var colors := {
	weekday = [
		Color.RED,  # sunday
		Color.WHITE,  # monday
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.BLUE,  # saturday
	],
	today = Color.GREEN,
	calbg = Color(0.5,0.5,0.5,0.5),
	datelabel = Color.WHITE,
}

# 1+7x7 : year+month, weekdayname, 6 weeek
var calendar_labels := []

func get_color_mat(co: Color)->Material:
	var mat := MultiMeshShape.MakeMultiMeshColorMaterial()
	mat.albedo_color = co
	#mat.metallic = 1
	#mat.clearcoat = true
	return mat

func new_text(fsize :float, fdepth :float, mat :Material, text :String)->MeshInstance3D:
	var mesh := TextMesh.new()
	mesh.font = font
	mesh.depth = fdepth
	mesh.pixel_size = fsize / 16
	mesh.text = text
	mesh.material = mat
	var sp := MeshInstance3D.new()
	sp.mesh = mesh
	return sp

func init(w :float, h:float,d:float, fsize :float, backplane:bool=true) -> Calendar3D:
	calendar_labels = []
	for o in $LabelConatiner.get_children():
		o.queue_free()
	$BackplaneBox.visible = backplane
	if backplane:
		$BackplaneBox.mesh.material.albedo_color = colors.calbg
		$BackplaneBox.mesh.size = Vector3(w, h, d*0.5)
	init_calendar(w, h,d, fsize)
	update_calendar(get_localtime_from_system())
	return self

func init_calendar(w :float, h :float, d:float, fsize :float) -> void:
	var calc_grid := CalcGrid3D.new( CalcGrid3D.SizeToAABB(Vector3(w,h,d)) , Vector3i(7,8,1))
	# add year month
	var fdepth := d * 0.2
	var mat := get_color_mat(colors.datelabel)
	var lb := new_text(fsize, fdepth, mat,"0000년 00월")
	lb.position = calc_grid.posi_to_lanepos(Vector3(3,7,0))
	calendar_labels.append(lb)
	$LabelConatiner.add_child(lb)
	# prepare calendar
	for i in range(1,8): # skip yearmonth, week title + 6 week
		var ln := []
		for wd in weekdaystring.size():
			var co :Color = colors.weekday[wd]
			mat = get_color_mat(co)
			lb = new_text(fsize,fdepth, mat, weekdaystring[wd])
			lb.position = calc_grid.posi_to_lanepos(Vector3(wd,7-i,0))
			ln.append(lb)
			$LabelConatiner.add_child(lb)
		calendar_labels.append(ln)

func set_mesh_color(sp:MeshInstance3D, co:Color) -> void:
	sp.mesh.material = get_color_mat(co)

func set_mesh_text(sp:MeshInstance3D, text :String) -> void:
	sp.mesh.text = text

## with time zone applied
static func get_localtime_from_system() -> int:
	var tz := Time.get_time_zone_from_system()
	var today :int = int(Time.get_unix_time_from_system()) +tz["bias"]*60
	return today

static func make_unix_time(year :int, month :int, day :int) -> int:
	return Time.get_unix_time_from_datetime_dict({
		"year" : year,
		"month" : month,
		"day" : day,
	})

func update_calendar(unix_time :int) -> void:
	var datetime_dict := Time.get_date_dict_from_unix_time(unix_time)
	set_mesh_text(calendar_labels[0], "%4d년 %2d월" % [
		datetime_dict["year"] , datetime_dict["month"]
		])
	var day_index :int = unix_time - (7 + datetime_dict["weekday"] )*24*60*60
	for wd in weekdaystring.size():
		var curLabel :MeshInstance3D = calendar_labels[1][wd]
		var co :Color = colors.weekday[wd]
		var lb_scale := Vector3(1,1,1)
		if wd == datetime_dict["weekday"] :
			co = colors.today
			lb_scale = Vector3(1.3,1.3,1)
		curLabel.scale = lb_scale
		set_mesh_color(curLabel, co)

	for i in range(2,8): # skip week title , 6 week
		for wd in weekdaystring.size():
			var day_index_dict := Time.get_date_dict_from_unix_time(day_index)
			var curLabel :MeshInstance3D = calendar_labels[i][wd]
			set_mesh_text(curLabel, "%d" % day_index_dict["day"] )
			var co :Color = colors.weekday[wd]
			var lb_scale := Vector3(1,1,1)
			if day_index_dict["month"] != datetime_dict["month"]:
				co = co.darkened(0.5)
			elif day_index_dict["day"] == datetime_dict["day"]:
				co = colors.today
				lb_scale = Vector3(1.3,1.3,1)
			curLabel.scale = lb_scale
			set_mesh_color(curLabel, co)
			day_index += 24*60*60

var old_time_dict = {"day":0} # datetime dict
func update_calender_if_day_changed() -> void:
	var today := get_localtime_from_system()
	var time_now_dict := Time.get_date_dict_from_unix_time(today)
	# date changed, update datelabel, calendar
	if old_time_dict["day"] != time_now_dict["day"]:
		old_time_dict = time_now_dict
		update_calendar(today)
