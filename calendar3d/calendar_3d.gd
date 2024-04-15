extends Node3D

class_name Calendar3D

# 1+7x7 : year+month, weekdayname, 6 weeek
var calendar_labels = []

func init(w :float, h:float, fsize :float, backplane:bool=true)->void:
	calendar_labels = []
	for o in $LabelConatiner.get_children():
		o.queue_free()

	if backplane:
		var plane = Global3d.new_box(Vector3(w, w/60, h), Global3d.get_color_mat(Global3d.colors.calbg ) )
		plane.position.y = -w/60
		$LabelConatiner.add_child(plane)

	init_calendar(w/Global3d.weekdaystring.size(), h/8, fsize)
	update_calendar()

func init_calendar(w :float, h :float, fsize :float)->void:
	# add year month
	var fdepth = fsize/200
	var time_now_dict = Time.get_datetime_dict_from_system()
	var mat = Global3d.get_color_mat(Global3d.colors.datelabel)
	var lb = Global3d.new_text(fsize,fdepth, mat, "%4d년 %2d월" % [
			time_now_dict["year"] , time_now_dict["month"]
			])
	lb.rotation.x = deg_to_rad(-90)
	lb.rotation.z = deg_to_rad(-90)
	lb.position = Vector3(3.5*h, 0, 0)
	calendar_labels.append(lb)
	$LabelConatiner.add_child(lb)

	# prepare calendar
	for i in range(1,8): # skip yearmonth, week title + 6 week
		var ln = []
		for wd in Global3d.weekdaystring.size():
			var co = Global3d.colors.weekday[wd]
			mat = Global3d.get_color_mat(co)
			lb = Global3d.new_text(fsize,fdepth, mat, Global3d.weekdaystring[wd])
			lb.rotation.x = deg_to_rad(-90)
			#t.rotation.y = deg2rad(90)
			lb.rotation.z = deg_to_rad(-90)
			lb.position = Vector3(3.5*h - i*h  , 0, wd*w - 3*w)
			ln.append(lb)
			$LabelConatiner.add_child(lb)
		calendar_labels.append(ln)

func set_mesh_color(sp:MeshInstance3D, co:Color)->void:
	sp.mesh.material = Global3d.get_color_mat(co)

func set_mesh_text(sp:MeshInstance3D, text :String)->void:
	sp.mesh.text = text

func update_calendar()->void:
	var tz = Time.get_time_zone_from_system()
	var today = int(Time.get_unix_time_from_system()) +tz["bias"]*60
	var today_dict = Time.get_date_dict_from_unix_time(today)
	var day_index = today - (7 + today_dict["weekday"] )*24*60*60 #datetime.timedelta(days=(-today.weekday() - 7))

	for wd in Global3d.weekdaystring.size():
		var curLabel = calendar_labels[1][wd]
		var co = Global3d.colors.weekday[wd]
		if wd == today_dict["weekday"] :
			co = Global3d.colors.today
		set_mesh_color(curLabel, co)

	for i in range(2,8): # skip week title , 6 week
		for wd in Global3d.weekdaystring.size():
			var day_index_dict = Time.get_date_dict_from_unix_time(day_index)
			var curLabel = calendar_labels[i][wd]
			set_mesh_text(curLabel, "%d" % day_index_dict["day"] )
			var co = Global3d.colors.weekday[wd]
			if day_index_dict["month"] != today_dict["month"]:
				co = co.darkened(0.5)
			elif day_index_dict["day"] == today_dict["day"]:
				co = Global3d.colors.today
			set_mesh_color(curLabel, co)
			day_index += 24*60*60

var old_time_dict = {"day":0} # datetime dict
func _on_timer_timeout() -> void:
	var time_now_dict = Time.get_datetime_dict_from_system()

	# date changed, update datelabel, calendar
	if old_time_dict["day"] != time_now_dict["day"]:
		old_time_dict = time_now_dict
		update_calendar()
		var curLabel = calendar_labels[0]
		set_mesh_text(curLabel, "%4d년 %2d월" % [
			time_now_dict["year"] , time_now_dict["month"]
			]
			)

