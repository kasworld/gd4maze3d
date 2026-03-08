extends Node3D
class_name Tower

const AnimationDuration := 3.0
const StoreyAnimationDuration := 1.5

var tower_animation := SimpleAnimation.new()
func _process(_delta: float) -> void:
	tower_animation.handle_animation()

func tower_animation_ended(_node :Node3D, _ani :Dictionary) -> void:
	if tower_animation.is_empty():
		if randi_range(0,5) == 0:
			start_reset_all_animation()
		else:
			start_all_animation()

func animate_shift_in_storey(st :Storey, axis :int) -> void:
	tower_animation.start_move_subfield( "ani_shift_in", st, axis, st.position[axis], 0.0, AnimationDuration )

func start_reset_all_animation() -> void:
	shift_count = 0
	tower_animation.start_rotation("ani_rot", self, rotation, Vector3.ZERO, AnimationDuration)
	for st in storey_list:
		tower_animation.start_rotation("ani_rot", st, st.rotation, Vector3.ZERO, AnimationDuration)
		animate_shift_in_storey(st, Vector3.Axis.AXIS_X)
		animate_shift_in_storey(st, Vector3.Axis.AXIS_Z)

var shift_count := 0
func start_all_animation() -> void:
	shift_count += 1
	var diff :float = [PI/2,-PI/2].pick_random()
	var subfield :int = [Vector3.Axis.AXIS_X, Vector3.Axis.AXIS_Y, Vector3.Axis.AXIS_Z].pick_random()
	tower_animation.start_rotation_subfield("ani_rot", self, subfield , rotation[subfield], rotation[subfield] + diff, AnimationDuration)
	for st in storey_list:
		diff = [PI/2,-PI/2].pick_random()
		subfield = Vector3.Axis.AXIS_Y
		tower_animation.start_rotation_subfield("ani_rot", st, subfield, st.rotation[subfield], st.rotation[subfield] + diff, AnimationDuration)
		if shift_count % 2 == 0 :
			if not is_zero_approx(st.position.x):
				animate_shift_in_storey(st, Vector3.Axis.AXIS_X)
			if not is_zero_approx(st.position.y):
				animate_shift_in_storey(st, Vector3.Axis.AXIS_Z)
		else:
			diff = (Storey.GridSize*Storey.CellSize.x).length() /2
			subfield = [Vector3.Axis.AXIS_X, Vector3.Axis.AXIS_Z].pick_random()
			tower_animation.start_move_subfield("ani_shift_out", st, subfield, st.position[subfield], st.position[subfield] + diff, AnimationDuration)

func init_tower_animaion() -> void:
	tower_animation.animation_ended.connect(tower_animation_ended)
	start_all_animation()

var demo_random_list = [
	next_visible_floor_ceiling,
	view_wallpillar_next,
	start_storey_gap_animation,
]
func start_demo_random() -> void:
	$TimerDemoRandom.start()
func stop_demo_random() -> void:
	$TimerDemoRandom.stop()
func _on_timer_demo_random_timeout() -> void:
	demo_random_list.pick_random().call()
func next_visible_floor_ceiling() -> void:
	view_floor_ceiling += 1
	view_floor_ceiling %= Maze3D.FloorCeiling.size()
	set_floor_ceiling_visible(view_floor_ceiling)
func view_wallpillar_next() -> void:
	view_walls = Maze3D.wallview_next(view_walls)
	set_wallpillar_view_mode(view_walls)


var tower_num :int
var VisibleStoreyUp :int
var VisibleStoreyDown :int

var StoreyGap :float
var gap_ani_dir_open : bool = true # true:open, false:close
var storey_list :Array[Storey]
var cur_storey :Storey
var view_floor_ceiling := Maze3D.FloorCeiling.Both
var view_walls :Maze3D.WallPillarView = Maze3D.WallPillarView.ShortWithPillarBox

func calc_height() -> float:
	return (VisibleStoreyDown+1+VisibleStoreyUp) *( Storey.CellSize.y + StoreyGap )

func _to_string() -> String:
	return "Tower[total storey %s, view floor ceiling %s
	upper:%d lower:%d
	%s]" % [storey_list.size(), view_floor_ceiling,
	VisibleStoreyUp,VisibleStoreyDown, cur_storey ]

func init(num :int, StoreyUp :int, StoreyDown :int, Gap :float, deco_ani :bool=false) -> Tower:
	tower_num = num
	VisibleStoreyUp = StoreyUp
	VisibleStoreyDown = StoreyDown
	StoreyGap = Gap
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
	var rtn :float = storey_list[0].maze3d.calc_grid.unit_size.y/2
	if gap_ani_dir_open:
		rtn += StoreyGap * storey_index
	for i in storey_index:
		rtn += storey_list[i].maze3d.calc_grid.unit_size.y/2 + storey_list[i+1].maze3d.calc_grid.unit_size.y/2
	return rtn

func start_storey_gap_animation() -> void:
	gap_ani_dir_open = not gap_ani_dir_open
	for i in storey_list.size():
		var st := storey_list[i]
		var new_y = calc_storey_base_y_pos(i)
		st.storey_animation.start_move_subfield("ani_gap", st, Vector3.Axis.AXIS_Y, st.position.y, new_y, StoreyAnimationDuration)

func set_all_storey_position() -> void:
	for i in storey_list.size():
		var st := storey_list[i]
		var new_y := calc_storey_base_y_pos(i)
		st.storey_animation.start_move_subfield("ani_add_move", st, Vector3.Axis.AXIS_Y, st.position.y, new_y, StoreyAnimationDuration)

func add_new_storey(stnum :int) -> void:
	var st :Storey = preload("res://storey/storey.tscn").instantiate()
	st.setting_default().init(stnum)
	st.get_maze3d().view_floor_ceiling(view_floor_ceiling)
	st.get_maze3d().set_wallpillar_view_mode(view_walls)
	storey_list.append(st)
	add_child(st)
	st.position.y = calc_storey_base_y_pos(storey_list.size()-1)
	set_all_storey_position()
	st.storey_animation.animation_ended.connect(storey_animation_ended)
	st.storey_animation.start_scale("ani_add", st, Vector3(0.1,0.1,0.1), Vector3(1,1,1), StoreyAnimationDuration)

func del_old_storey() -> void:
	if cur_storey.storey_num > VisibleStoreyDown:
		var st :Storey = storey_list.pop_front()
		st.storey_animation.start_scale("ani_del", st, Vector3(1,1,1), Vector3(0.1,0.1,0.1), StoreyAnimationDuration)

func storey_animation_ended(st :Node3D, ani :Dictionary) -> void:
	match ani.Name:
		"ani_add":
			pass
		"ani_del":
			remove_child(st)
			st.queue_free()
		"ani_gap", "ani_add_move":
			pass

func set_floor_ceiling_visible(v :Maze3D.FloorCeiling) -> void:
	for i in storey_list.size():
		storey_list[i].get_maze3d().view_floor_ceiling(v)

func set_wallpillar_view_mode(w :Maze3D.WallPillarView) -> void:
	for i in storey_list.size():
		storey_list[i].get_maze3d().set_wallpillar_view_mode(w)
