extends Node3D
class_name Tower

enum WallView {Reduced, Full, Off}
static func wallview2str(vd :WallView) -> String:
	return WallView.keys()[vd]
static func wallview_next(a :WallView) -> WallView:
	return (a +1) % WallView.keys().size() as WallView

var storey_scene = preload("res://storey.tscn")

var tower_setting :TowerSetting
var storey_list :Array[Storey]
var cur_storey :Storey 
var view_floor_ceiling :bool = false
var view_walls :WallView = WallView.Reduced
var view_pillars :bool = true
var gap_ani_dir_open : bool = true # true:open, false:close
var animate_gap_start_time :float

func _to_string() -> String:
	return "Tower %s, floor,ceiling %s\n%s" % [
	storey_list.size(), view_floor_ceiling, cur_storey ]

func init(ts :TowerSetting) -> Tower:
	tower_setting = ts
	var mat_keys = Texmat.floor_mat_dict.keys()
	mat_keys.shuffle()
	$Floor.mesh.material = Texmat.floor_mat_dict[mat_keys[0]].duplicate()
	$Floor.mesh.size = tower_setting.MeshSize
	$Floor.mesh.material.uv1_scale = Vector3(tower_setting.MazeSize.x,(tower_setting.MazeSize.x+tower_setting.MazeSize.y)/2.0,tower_setting.MazeSize.y)

	mat_keys = Texmat.ceiling_mat_dict.keys()
	mat_keys.shuffle()
	$Ceiling.mesh.material = Texmat.ceiling_mat_dict[mat_keys[0]].duplicate()
	$Ceiling.mesh.size = tower_setting.MeshSize
	$Ceiling.mesh.material.uv1_scale = $Floor.mesh.material.uv1_scale
	
	set_wallview_mode(view_walls)
	set_pillars_visible(view_pillars)
	for i in tower_setting.VisibleStoreyUp:
		add_new_storey(i)
	cur_storey = storey_list[0]
	
	set_floor_ceiling_pos()
	set_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)
	set_wallview_mode(view_walls)
	set_pillars_visible(view_pillars)
	return self

func set_floor_ceiling_pos() -> void:
	$Floor.position = calc_floor_position()
	$Ceiling.position = calc_ceiling_position()

func enter_next_storey() -> void:
	del_old_storey()
	add_new_storey(storey_list[-1].storey_num +1)
	var new_cur_storey_num = cur_storey.storey_num +1
	cur_storey = storey_list[find_storey_num_to_index(new_cur_storey_num)]

	set_floor_ceiling_pos()
	set_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)
	set_wallview_mode(view_walls)
	set_pillars_visible(view_pillars)

func _process(_delta: float) -> void:
	var rate :=  Time.get_unix_time_from_system() - animate_gap_start_time
	if rate <= 1.0 :
		if gap_ani_dir_open:
			tower_setting.StoreyGapRate = lerp(0.0, 1.0, rate)
		else:
			tower_setting.StoreyGapRate = lerp(1.0, 0.0, rate)
		apply_storey_gap_change()

func calc_floor_position() -> Vector3:
	return Vector3(tower_setting.MeshCenter.x, 
		-tower_setting.calc_current_storey_gap()/2, 
		tower_setting.MeshCenter.y)

func calc_ceiling_position() -> Vector3:
	return Vector3(tower_setting.MeshCenter.x, 
		tower_setting.calc_storey_base_y_pos(storey_list.size()) - tower_setting.calc_current_storey_gap()/2, 
		tower_setting.MeshCenter.y)

func calc_center() -> Vector3:
	return Vector3(tower_setting.MeshCenter.x, 
		calc_height()/2, 
		tower_setting.MeshCenter.y)

func calc_height() -> float:
	return tower_setting.calc_storey_base_y_pos(storey_list.size())

func cell_pos_to_vec3(p2 :Vector2i, storeynum :int) -> Vector3:
	var st_index = find_storey_num_to_index(storeynum)
	var y = tower_setting.calc_storey_mid_y_pos(st_index) 
	return storey_list[st_index].mazepos2storeypos(p2, y)	

func find_storey_num_to_index(num :int) -> int:
	for i in storey_list.size():
		if storey_list[i].storey_num == num:
			return i
	assert(false)
	return -1

func apply_storey_gap_change() -> void:
	for i in storey_list.size():
		storey_list[i].position.y = tower_setting.calc_storey_base_y_pos(i)
	$Floor.position = calc_floor_position()
	$Ceiling.position = calc_ceiling_position()

func add_new_storey(stnum :int) -> void:
	var gp = tower_setting.rand_pos_2i()
	var stp = tower_setting.rand_pos_2i()
	if stnum > 0 :
		stp = storey_list[-1].goal_pos
	var st = storey_scene.instantiate().init(tower_setting, stnum, stp, gp)
	storey_list.append(st)
	apply_storey_gap_change()
	$AddStoreyContainer.add_child(st)
	$AnimationPlayerAddStorey.play("new_animation")

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
	var st = 0
	for i in range(st,storey_list.size()):
		storey_list[i].view_floor_ceiling(f,c)
	storey_list[st].view_floor_ceiling(false,c)
	storey_list[-1].view_floor_ceiling(f,false)

func set_wallview_mode(w :WallView) -> void:
	var st = 0
	for i in range(st,storey_list.size()):
		match w:
			WallView.Full:
				storey_list[i].view_walls(true)
				storey_list[i].set_wall_size(true)
			WallView.Reduced:
				storey_list[i].view_walls(true)
				storey_list[i].set_wall_size(false)
			WallView.Off:
				storey_list[i].view_walls(false)

func set_pillars_visible(w :bool) -> void:
	var st = 0
	for i in range(st,storey_list.size()):
		storey_list[i].view_pillars(w)

func toggle_visible_floor_ceiling() -> void:
	view_floor_ceiling = not view_floor_ceiling
	set_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)

func view_wall_next() -> void:
	view_walls = wallview_next(view_walls)
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
