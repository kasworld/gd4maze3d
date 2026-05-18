extends Node3D
class_name Tower

const StoreyUp := 3
const StoreyDown := 3

const StoreyAnimationDuration := 1.5

static func ref_tower_size() -> Vector3:
	return Vector3(Storey.GridSize.x, StoreyUp + StoreyDown +1 , Storey.GridSize.y) * Storey.CellSize

var visible_storey_up :int = StoreyUp
var visible_storey_down :int = StoreyDown
var storey_gap :float = Storey.CellSize.y
var gap_ani_dir_open : bool = true # true:open, false:close
var storey_list :Array[Storey]
var cur_storey :Storey

var view_floor_ceiling := Maze3D.FloorCeiling.Both
func next_visible_floor_ceiling() -> void:
	view_floor_ceiling = Maze3D.view_floor_ceiling_next(view_floor_ceiling)
	set_floor_ceiling_visible(view_floor_ceiling)
func set_floor_ceiling_visible(v :Maze3D.FloorCeiling) -> void:
	for i in storey_list.size():
		storey_list[i].get_maze3d().view_floor_ceiling(v)

var view_walls :Maze3D.WallPillarView = Maze3D.WallPillarView.ShortWithPillarBox
func view_wallpillar_next() -> void:
	view_walls = Maze3D.wallview_next(view_walls)
	set_wallpillar_view_mode(view_walls)
func set_wallpillar_view_mode(w :Maze3D.WallPillarView) -> void:
	for i in storey_list.size():
		storey_list[i].get_maze3d().set_wallpillar_view_mode(w)

func _to_string() -> String:
	return "Tower[total storey %s, view floor ceiling %s
	upper:%d lower:%d
	%s]" % [storey_list.size(), view_floor_ceiling,
	visible_storey_up,visible_storey_down, cur_storey ]

func init() -> Tower:
	for i in visible_storey_up:
		add_new_storey()
	cur_storey = storey_list[0]
	return self

func move_to_upper_storey() -> void:
	del_old_storey()
	add_new_storey()
	cur_storey = find_storey_by_num(cur_storey.storey_num +1)

func find_storey_by_num(num :int) -> Storey:
	for i in storey_list.size():
		if storey_list[i].storey_num == num:
			return storey_list[i]
	return null

func calc_storey_base_y_pos(storey_index :int) -> float:
	var rtn :float = storey_list[0].storey_height/2
	if gap_ani_dir_open:
		rtn += storey_gap * storey_index
	for i in storey_index:
		rtn += storey_list[i].storey_height/2 + storey_list[i+1].storey_height/2
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

func add_new_storey() -> void:
	var stnum := 0
	if storey_list.size() != 0:
		stnum = storey_list[-1].storey_num +1
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
	if cur_storey.storey_num > visible_storey_down:
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
