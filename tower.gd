extends Node3D
class_name Tower

const AnimationDuration := 2.0

var tower_animation := Animation3D.new()
func _process(_delta: float) -> void:
	tower_animation.handle_animation()

func start_rotate_animation(nd :Node3D, subfield :int, ani_dur :float) -> void:
	var diff :float = [PI/2,-PI/2].pick_random()
	tower_animation.start_rotate_subfield("ani_rot", nd, subfield , nd.rotation[subfield], nd.rotation[subfield] + diff, ani_dur)

func start_reset_rotate_animation(nd :Node3D, ani_dur :float) -> void:
	tower_animation.start_rotate("ani_rot", nd, nd.rotation, Vector3.ZERO, ani_dur)

func start_shift_out_animation(st :Node3D, subfield :int, ani_dur :float) -> void:
	var diff := maze3d_setting.CalcDiagonalLengthV2() /2
	tower_animation.start_move_subfield("ani_shift_out", st, subfield, st.position[subfield], st.position[subfield] + diff, ani_dur)

func start_shift_in_animation(st :Node3D, subfield :int, ani_dur :float) -> void:
	tower_animation.start_move_subfield( "ani_shift_in", st, subfield, st.position[subfield], 0, ani_dur )

func start_reset_position_animation(st :Node3D, ani_dur :float) -> void:
	start_shift_in_animation(st, Vector3.Axis.AXIS_X, ani_dur)
	start_shift_in_animation(st, Vector3.Axis.AXIS_Z, ani_dur)

func tower_animation_ended(_node :Node3D, _ani :Dictionary) -> void:
	if tower_animation.is_empty():
		if randi_range(0,5) == 0:
			start_reset_all_animation()
		else:
			start_all_animation()

func start_reset_all_animation() -> void:
	shift_count = 0
	start_reset_rotate_animation(self, AnimationDuration)
	for st in storey_list:
		start_reset_rotate_animation(st, AnimationDuration)
		start_reset_position_animation(st, AnimationDuration)

var shift_count := 0
func start_all_animation() -> void:
	shift_count += 1
	start_rotate_animation(self, [Vector3.Axis.AXIS_X, Vector3.Axis.AXIS_Y, Vector3.Axis.AXIS_Z].pick_random(), AnimationDuration)
	for st in storey_list:
		start_rotate_animation(st, Vector3.Axis.AXIS_Y, AnimationDuration)
		if shift_count % 2 == 0 :
			if not is_zero_approx(st.position.x):
				start_shift_in_animation(st, Vector3.Axis.AXIS_X, AnimationDuration)
			if not is_zero_approx(st.position.z):
				start_shift_in_animation(st, Vector3.Axis.AXIS_Z, AnimationDuration)
		else:
			start_shift_out_animation(st, [Vector3.Axis.AXIS_X, Vector3.Axis.AXIS_Z].pick_random(), AnimationDuration)

func init_tower_animaion() -> void:
	tower_animation.animation_ended.connect(tower_animation_ended)
	start_all_animation()

var tower_num :int
var deco_ani :bool
var VisibleStoreyUp :int
var VisibleStoreyDown :int

var StoreyGap :float
var gap_ani_dir_open : bool = true # true:open, false:close
var maze3d_setting :Maze3DSetting
var storey_setting :StoreySetting
var storey_list :Array[Storey]
var cur_storey :Storey
var view_floor_ceiling :bool = true
var view_walls :Maze3D.WallView = Maze3D.WallView.Reduced
var view_pillars :bool = true

func calc_height() -> float:
	return storey_list[-1].position.y - storey_list[0].position.y + storey_list[-1].maze3d_setting.StoryH

func _to_string() -> String:
	return "Tower[total storey %s, view floor ceiling %s
	upper:%d lower:%d
	%s]" % [storey_list.size(), view_floor_ceiling,
	VisibleStoreyUp,VisibleStoreyDown, cur_storey ]

func init(num :int, StoreyUp :int, StoreyDown :int, Gap :float, ss :StoreySetting ,ms :Maze3DSetting, deco_ania :bool=false) -> Tower:
	tower_num = num
	VisibleStoreyUp = StoreyUp
	VisibleStoreyDown = StoreyDown
	StoreyGap = Gap
	storey_setting = ss
	maze3d_setting = ms
	deco_ani = deco_ania
	for i in VisibleStoreyUp:
		add_new_storey(i)
	cur_storey = storey_list[0]
	if deco_ani:
		init_tower_animaion()
	return self

func move_to_upper_storey() -> void:
	del_old_storey()
	add_new_storey(storey_list[-1].storey_num +1)
	cur_storey = find_storey_by_num(cur_storey.storey_num +1)

func find_storey_by_num(num :int) -> Storey:
	for i in storey_list.size():
		if storey_list[i].storey_num == num:
			return storey_list[i]
	return null

func calc_storey_base_y_pos(storey_index :int) -> float:
	var rtn := storey_list[0].maze3d_setting.StoryH/2
	if gap_ani_dir_open:
		rtn += StoreyGap * storey_index
	for i in storey_index:
		rtn += storey_list[i].maze3d_setting.StoryH/2 + storey_list[i+1].maze3d_setting.StoryH/2
	return rtn

func start_storey_gap_animation() -> void:
	gap_ani_dir_open = not gap_ani_dir_open
	for i in storey_list.size():
		var st := storey_list[i]
		var new_pos := st.position
		new_pos.y = calc_storey_base_y_pos(i)
		st.storey_animation.start_move("ani_gap", st, st.position, new_pos, 1)

func set_all_storey_position() -> void:
	for i in storey_list.size():
		storey_list[i].position.y = calc_storey_base_y_pos(i)

func add_new_storey(stnum :int) -> void:
	var ms := maze3d_setting.duplicate()
	ms.MazeSize += Vector2i(randi_range(-1,1), randi_range(-1,1) )
	ms.StoryH *= pow(2, randf()*2 -1 )
	ms.LaneW *= pow(2, randf()*2 -1 )
	var st :Storey = preload("res://storey/storey.tscn").instantiate().init(stnum, storey_setting, ms)
	st.view_floor_ceiling(view_floor_ceiling,view_floor_ceiling)
	st.view_pillars(view_pillars)
	st.set_wallview_mode(view_walls)
	storey_list.append(st)
	add_child(st)
	set_all_storey_position()
	st.storey_animation.animation_ended.connect(storey_animation_ended)
	st.storey_animation.start_scale("ani_add", st, Vector3(0.1,0.1,0.1), Vector3(1,1,1), 1)

func del_old_storey() -> void:
	if cur_storey.storey_num > VisibleStoreyDown:
		var st :Storey = storey_list.pop_front()
		st.storey_animation.start_scale("ani_del", st, Vector3(1,1,1), Vector3(0.1,0.1,0.1), 1)

func storey_animation_ended(st :Node3D, ani :Dictionary) -> void:
	match ani.Name:
		"ani_add":
			pass
		"ani_del":
			remove_child(st)
			st.queue_free()
		"ani_gap":
			pass

func set_floor_ceiling_visible(f :bool,c :bool) -> void:
	for i in storey_list.size():
		storey_list[i].view_floor_ceiling(f,c)

func set_wallview_mode(w :Maze3D.WallView) -> void:
	for i in storey_list.size():
		storey_list[i].set_wallview_mode(w)

func set_pillars_visible(w :bool) -> void:
	for i in storey_list.size():
		storey_list[i].view_pillars(w)

func toggle_visible_floor_ceiling() -> void:
	view_floor_ceiling = not view_floor_ceiling
	set_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)

func view_wall_next() -> void:
	view_walls = Maze3D.wallview_next(view_walls)
	set_wallview_mode(view_walls)

func toggle_visible_pillars() -> void:
	view_pillars = not view_pillars
	set_pillars_visible(view_pillars)

var demo_random_list = [
	move_to_upper_storey,
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
