extends Node3D
class_name Tower

signal storey_gap_changed(t :Tower)

var tower_setting :TowerSetting
var storey_setting :StoreySetting
var storey_list :Array[Storey]
var cur_storey :Storey 
var view_floor_ceiling :bool = true
var view_walls :Storey.WallView = Storey.WallView.Reduced
var view_pillars :bool = true
var gap_ani_dir_open : bool = true # true:open, false:close
var animate_gap_start_time :float

# used to animate
var StoreyGapRate := 1.0

func calc_current_storey_gap() -> float:
	return tower_setting.StoreyGap * StoreyGapRate

func calc_storey_base_y_pos(storey_index :int) -> float:
	var rtn := 0.0
	for i in storey_index:
		rtn += calc_current_storey_gap() + storey_list[i].storey_setting.StoryH
	return rtn

func calc_height() -> float:
	return calc_storey_base_y_pos(storey_list.size())

func _to_string() -> String:
	return "Tower[total storey %s, view floor ceiling %s
	%s
	%s]" % [storey_list.size(), view_floor_ceiling, 
	tower_setting, cur_storey ]

func init(ts :TowerSetting, ss :StoreySetting) -> Tower:
	tower_setting = ts
	storey_setting = ss
	for i in tower_setting.VisibleStoreyUp:
		add_new_storey(i)
	cur_storey = storey_list[0]
	return self

# return old storey
func enter_next_storey() -> void:
	del_old_storey()
	add_new_storey(storey_list[-1].storey_num +1)
	cur_storey = find_storey_by_num(cur_storey.storey_num +1)

func _process(_delta: float) -> void:
	var timenow := Time.get_unix_time_from_system()
	var rate :=  timenow - animate_gap_start_time
	if rate <= 1.0 :
		if gap_ani_dir_open:
			StoreyGapRate = lerp(0.0, 1.0, rate)
		else:
			StoreyGapRate = lerp(1.0, 0.0, rate)
		apply_storey_gap_change()

func find_storey_by_num(num :int) -> Storey:
	for i in storey_list.size():
		if storey_list[i].storey_num == num:
			return storey_list[i]
	return null

func apply_storey_gap_change() -> void:
	for i in storey_list.size():
		storey_list[i].position.y = calc_storey_base_y_pos(i)
	storey_gap_changed.emit(self)

func add_new_storey(stnum :int) -> void:
	var ss = storey_setting.duplicate()
	ss.MazeSize += Vector2i(randi_range(-1,1), randi_range(-1,1) )
	ss.StoryH *= pow(2, randf()*2 -1 )
	ss.LaneW *= pow(2, randf()*2 -1 )
	var st = preload("res://storey.tscn").instantiate().init(ss, stnum)
	st.position -= ss.CalcMeshCenterV3()
	#st.rotation.y = randf_range(0,2*PI)
	storey_list.append(st)
	apply_storey_gap_change()
	$AddStoreyContainer.add_child(st)
	$AnimationPlayerAddStorey.play("new_animation")
	st.view_floor_ceiling(view_floor_ceiling,view_floor_ceiling)
	st.view_pillars(view_pillars)
	st.set_wallview_mode(view_walls)

func _on_animation_player_add_storey_animation_finished(_anim_name: StringName) -> void:
	for st in $AddStoreyContainer.get_children():
		$AddStoreyContainer.remove_child(st)
		add_child(st)

func del_old_storey() -> void:
	if cur_storey.storey_num > tower_setting.VisibleStoreyDown :
		var todel = storey_list.pop_front()
		remove_child(todel)
		$DelStoreyContainer.add_child(todel)
		$AnimationPlayerDelStorey.play("new_animation")

func _on_animation_player_del_storey_animation_finished(_anim_name: StringName) -> void:
	for todel in $DelStoreyContainer.get_children():
		$DelStoreyContainer.remove_child(todel)
		todel.queue_free()

func set_floor_ceiling_visible(f :bool,c :bool) -> void:
	for i in storey_list.size():
		storey_list[i].view_floor_ceiling(f,c)

func set_wallview_mode(w :Storey.WallView) -> void:
	for i in storey_list.size():
		storey_list[i].set_wallview_mode(w)

func set_pillars_visible(w :bool) -> void:
	for i in storey_list.size():
		storey_list[i].view_pillars(w)

func toggle_visible_floor_ceiling() -> void:
	view_floor_ceiling = not view_floor_ceiling
	set_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)

func view_wall_next() -> void:
	view_walls = Storey.wallview_next(view_walls)
	set_wallview_mode(view_walls)

func toggle_visible_pillars() -> void:
	view_pillars = not view_pillars
	set_pillars_visible(view_pillars)

func start_storey_gap_animation() -> void:
	animate_gap_start_time = Time.get_unix_time_from_system()
	gap_ani_dir_open = not gap_ani_dir_open

var demo_random_list = [
	enter_next_storey,
	toggle_visible_floor_ceiling,
	view_wall_next,
	toggle_visible_pillars,
	start_storey_gap_animation,
]
func start_demo_random() -> void:
	$TimerDemoRandom.start()
func stop_demo_random() -> void:
	$TimerDemoRandom.stop()
func _on_timer_demo_random_timeout() -> void:
	demo_random_list.pick_random().call()
