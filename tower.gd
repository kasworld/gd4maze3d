extends Node3D
class_name Tower

enum WallView {Reduced, Full, Off}
static func wallview2str(vd :WallView) -> String:
	return WallView.keys()[vd]
static func wallview_next(a :WallView) -> WallView:
	return (a +1) % WallView.keys().size() as WallView

var storey_scene = preload("res://storey.tscn")

var storey_list :Array[Storey]
var cur_storey_index :int = -1 # +1 on enter_new_storey
var view_floor_ceiling :bool = false
var view_walls :WallView = WallView.Reduced
var view_pillars :bool = true
var gap_ani_dir_open : bool = true # true:open, false:close
var animate_gap_start_time :float

func init() -> Tower:
	var mat_keys = Texmat.floor_mat_dict.keys()
	mat_keys.shuffle()
	$Floor.mesh.material = Texmat.floor_mat_dict[mat_keys[0]].duplicate()
	$Floor.mesh.size = Settings.MeshSize
	$Floor.mesh.material.uv1_scale = Vector3(Settings.MazeSize.x,(Settings.MazeSize.x+Settings.MazeSize.y)/2.0,Settings.MazeSize.y)

	mat_keys = Texmat.ceiling_mat_dict.keys()
	mat_keys.shuffle()
	$Ceiling.mesh.material = Texmat.ceiling_mat_dict[mat_keys[0]].duplicate()
	$Ceiling.mesh.size = Settings.MeshSize
	$Ceiling.mesh.material.uv1_scale = $Floor.mesh.material.uv1_scale
	
	set_wallview_mode(view_walls)
	set_pillars_visible(view_pillars)
	for i in Settings.VisibleStoreyUp:
		add_new_storey(i)
	#enter_new_storey()
	return self

func calc_floor_position() -> Vector3:
	return Vector3(Settings.MeshSize.x/2, Settings.calc_storey_base_y_pos(visible_down_index()) - Settings.calc_current_storey_gap()/2, Settings.MeshSize.y/2)

func calc_ceiling_position() -> Vector3:
	return Vector3(Settings.MeshSize.x/2, Settings.calc_storey_base_y_pos(storey_list.size()) - Settings.calc_current_storey_gap()/2, Settings.MeshSize.y/2)

func calc_center() -> Vector3:
	return (calc_floor_position() + calc_ceiling_position())/2

func calc_height() -> float:
	return (calc_ceiling_position() - calc_floor_position()).y

func enter_new_storey() -> void:
	cur_storey_index +=1
	del_old_storey()
	add_new_storey(storey_list.size())
	$Floor.position = calc_floor_position()
	$Ceiling.position = calc_ceiling_position()
	set_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)
	set_wallview_mode(view_walls)
	set_pillars_visible(view_pillars)

func apply_storey_gap_change() -> void:
	for st in storey_list:
		if st == null:
			continue
		var stnum = st.storey_num
		st.position.y = Settings.calc_storey_base_y_pos(stnum)
	$Floor.position = calc_floor_position()
	$Ceiling.position = calc_ceiling_position()

func get_cur_storey() -> Storey:
	return storey_list[cur_storey_index]

func add_new_storey(stnum :int) -> void:
	var gp = Settings.rand_pos_2i()
	var stp = Settings.rand_pos_2i()
	if stnum > 0 :
		stp = storey_list[-1].goal_pos
	var st = storey_scene.instantiate().init(stnum, stp, gp)
	st.position.y = Settings.calc_storey_base_y_pos(stnum)
	storey_list.append(st)
	$AddStoreyContainer.add_child(st)
	$AnimationPlayerAddStorey.play("new_animation")

func _on_animation_player_add_storey_animation_finished(_anim_name: StringName) -> void:
	for st in $AddStoreyContainer.get_children():
		$AddStoreyContainer.remove_child(st)
		add_child(st)

func del_old_storey() -> void:
	if visible_down_index()-1 >=0 :
		var todel = storey_list[visible_down_index()-1]
		storey_list[visible_down_index()-1] = null
		remove_child(todel)
		$DelStoreyContainer.add_child(todel)
		$AnimationPlayerDelStorey.play("new_animation")

func _on_animation_player_del_storey_animation_finished(_anim_name: StringName) -> void:
	for todel in $DelStoreyContainer.get_children():
		$DelStoreyContainer.remove_child(todel)
		todel.queue_free()

func visible_down_index() -> int:
	var rtn = cur_storey_index - Settings.VisibleStoreyDown
	if rtn < 0:
		return 0
	return rtn

func set_floor_ceiling_visible(f :bool,c :bool) -> void:
	var st = visible_down_index()
	for i in range(st,storey_list.size()):
		storey_list[i].view_floor_ceiling(f,c)
	storey_list[st].view_floor_ceiling(false,c)
	storey_list[-1].view_floor_ceiling(f,false)

func set_wallview_mode(w :WallView) -> void:
	var st = visible_down_index()
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
	var st = visible_down_index()
	for i in range(st,storey_list.size()):
		storey_list[i].view_pillars(w)

func _on_button_floor_ceiling_pressed() -> void:
	view_floor_ceiling = not view_floor_ceiling
	set_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)

func _on_button_walls_pressed() -> void:
	view_walls = wallview_next(view_walls)
	set_wallview_mode(view_walls)

func _on_button_pillars_pressed() -> void:
	view_pillars = not view_pillars
	set_pillars_visible(view_pillars)

func _on_button_storey_gap_pressed() -> void:
	animate_gap_start_time = Time.get_unix_time_from_system()
	gap_ani_dir_open = not gap_ani_dir_open
