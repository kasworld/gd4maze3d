extends Node3D

enum WallView {Reduced, Full, Off}
static func wallview2str(vd :WallView) -> String:
	return WallView.keys()[vd]
static func wallview_next(a :WallView) -> WallView:
	return (a +1) % WallView.keys().size() as WallView

enum MiniMapView {Off, Known, Full}
static func minimapview2str(vd :MiniMapView) -> String:
	return MiniMapView.keys()[vd]
static func minimapview_next(a :MiniMapView) -> MiniMapView:
	return (a +1) % MiniMapView.keys().size() as MiniMapView

var minimap_scene = preload("res://mini_map.tscn")
var storey_scene = preload("res://storey.tscn")
var character_scene = preload("res://character.tscn")

@onready var debuglabel = $ButtonContainer/LabelContainer/Debug
@onready var performancelabel = $ButtonContainer/LabelContainer/Performance
@onready var infolabel = $ButtonContainer/LabelContainer/Info
@onready var cameralight = $MovingCameraLight
@onready var char_container = $CharacterContainer

var minimap :MiniMap
var storey_list :Array[Storey]
var cur_storey_index :int = -1 # +1 on enter_new_storey
var player_number := 0
var vp_size :Vector2
var minimap_mode :MiniMapView = MiniMapView.Off
var view_floor_ceiling :bool = false
var view_walls :WallView = WallView.Reduced
var view_pillars :bool = true
var camera_move := false

func _ready() -> void:
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

	for i in Settings.CharacterCount:
		var pl = character_scene.instantiate()
		char_container.add_child(pl)
		if i % 2 == 0:
			pl.init_char(AILib.Walk.RightFirst, i, Settings.LaneW, NamedColorList.color_list.pick_random()[0])
		else:
			pl.init_char(AILib.Walk.LeftFirst, i, Settings.LaneW, NamedColorList.color_list.pick_random()[0])
	for i in Settings.VisibleStoreyUp:
		add_new_storey(i)

	$MovingCameraLight.init()
	vp_size = get_viewport().get_visible_rect().size
	var msgrect = Rect2( vp_size.x * 0.3 ,vp_size.y * 0.5 , vp_size.x * 0.4 , vp_size.y * 0.1 )
	$TimedMessage.init(80, msgrect, tr("gd4maze3d 19.1.0"))
	$TimedMessage.show_message("",3)

	get_viewport().size_changed.connect(_on_vpsize_changed)
	update_button_text()
	set_wallview_mode(view_walls)
	set_pillars_visible(view_pillars)
	init_orbit()
	enter_new_storey()

func _on_vpsize_changed() -> void:
	vp_size = get_viewport().get_visible_rect().size
	var map_scale = min( vp_size.x / Settings.MazeSize.x , vp_size.y / Settings.MazeSize.y )
	minimap.change_scale(map_scale)
	minimap.position.y = (vp_size.y -minimap.get_height())/2
	minimap.position.x = (vp_size.x - minimap.get_width())/2

func enter_new_storey() -> void:
	cur_storey_index +=1
	del_old_storey()
	add_new_storey(storey_list.size())
	$Floor.position = calc_floor_position()
	$Ceiling.position = calc_ceiling_position()
	set_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)
	set_wallview_mode(view_walls)
	set_pillars_visible(view_pillars)
	orbit_pos()

	vp_size = get_viewport().get_visible_rect().size
	var cur_storey = get_cur_storey()
	var map_scale = min( vp_size.x / Settings.MazeSize.x , vp_size.y / Settings.MazeSize.y )
	if minimap != null:
		minimap.queue_free()
	minimap = minimap_scene.instantiate()
	add_child(minimap)
	minimap.init(cur_storey,map_scale)

	for ch in char_container.get_children():
		ch.action_queue.resize(0)
		var stpos = Settings.rand_pos_2i()
		if ch.serial == player_number:
			stpos = cur_storey.start_pos
			minimap.add_character(ch,stpos, 8)
		else:
			minimap.add_character(ch,stpos, 0)
		ch.enqueue_action(ActLib.Action.EnterStorey, [cur_storey, stpos])

	set_minimap_mode(minimap_mode)
	_on_vpsize_changed()

func _process(delta: float) -> void:
	var cur_storey = get_cur_storey()
	move_character(cur_storey)
	update_info()
	if camera_move:
		move_camera(delta)

func calc_floor_position() -> Vector3:
	return Vector3(Settings.MeshSize.x/2, Settings.calc_storey_base_y_pos(visible_down_index()) - Settings.InterStoreyH/2, Settings.MeshSize.y/2)

func calc_ceiling_position() -> Vector3:
	return Vector3(Settings.MeshSize.x/2, Settings.calc_storey_base_y_pos(storey_list.size()) - Settings.InterStoreyH/2, Settings.MeshSize.y/2)

func calc_center() -> Vector3:
	return (calc_floor_position() + calc_ceiling_position())/2

func calc_height() -> float:
	return (calc_ceiling_position() - calc_floor_position()).y

func move_camera(_delta: float) -> void:
	var t = -Time.get_unix_time_from_system() /2.3
	var r = Settings.TotalDiagonal *1.0
	$MovingCameraLight.position = Vector3( sin(t)*r, sin(t*1.3)*calc_height() *2, cos(t)*r ) + calc_center()
	$MovingCameraLight.look_at(calc_center())

func init_orbit() -> void:
	var a120 = PI*2/3
	var a30 = PI/6
	var axis1 = Vector3.UP.rotated(Vector3.RIGHT, a30)
	var axis2 = Vector3.UP.rotated(Vector3.RIGHT.rotated(Vector3.UP,a120), a30)
	var axis3 = Vector3.UP.rotated(Vector3.RIGHT.rotated(Vector3.UP,a120*2), a30)
	$Earth.궤도설정(Settings.TotalDiagonal, 1.0/2, axis1, 0).구설정(4, 1, Vector3.UP).구재질설정(preload("res://earth_mat.tres")).궤도재질설정(Global3d.get_color_mat(Color.RED))
	$Moon.궤도설정(Settings.TotalDiagonal*0.9, 1.0/1, axis2, a120).구설정(3, 1, Vector3.UP).구재질설정(preload("res://moon_mat.tres")).궤도재질설정(Global3d.get_color_mat(Color.YELLOW))
	$Sun.궤도설정(Settings.TotalDiagonal*1.1, 1.0/3, axis3, a120*2).구설정(5, 1, Vector3.UP).구재질설정(preload("res://sun_mat.tres")).궤도재질설정(Global3d.get_color_mat(Color.GREEN))

func orbit_pos() -> void:
	$Moon.position = calc_center()
	$Earth.position = calc_center()
	$Sun.position = calc_center()

func move_character(cur_storey :Storey) -> void:
	for ch in char_container.get_children():
		var ani_dur = ch.get_animation_progress()
		if ch.is_action_ended(ani_dur): # true on act end
			ch.end_action()
			if ch.serial == player_number  : # player
				$MovingCameraLight.snap_90()
				if cur_storey.is_goal_pos(ch.pos_src):
					enter_new_storey()
					return
				var ft = cur_storey.놓인것들.get_at(ch.pos_src)
				if ft is Donut:
					ch.enqueue_action(ActLib.Action.RollLeft)
					cur_storey.놓인것들.del_at(ch.pos_src)
					ft.queue_free()
				elif ft is Capsule:
					ch.enqueue_action(ActLib.Action.RollRight)
					cur_storey.놓인것들.del_at(ch.pos_src)
					ft.queue_free()
			minimap.move_character(ch.serial, ch.pos_src)
		ch.ai_action()
		if ch.start_new_action(): # new act start
			ani_dur = 0
			if ch.serial == player_number and ch.action_current[0] != ActLib.Action.EnterStorey: # player
				minimap.update_walls_by_pos(ch.pos_src.x,ch.pos_src.y)
		if ch.action_current[0] != ActLib.Action.None :
			animate_action(ch, ani_dur)

var key2fn = {
	KEY_ESCAPE:_on_button_esc_pressed,
	KEY_1:_on_button_help_pressed,
	KEY_2:_on_button_minimap_pressed,
	KEY_3:_on_button_floor_ceiling_pressed,
	KEY_4:_on_button_walls_pressed,
	KEY_5:_on_button_pillars_pressed,
	KEY_6:_on_button_auto_move_pressed,
	KEY_7:_on_button_debug_pressed,
	KEY_8:_on_button_performance_pressed,
	KEY_9:_on_button_info_pressed,
	KEY_UP:_on_button_forward_pressed,
	KEY_DOWN:_on_button_backward_pressed,
	KEY_LEFT:_on_button_left_pressed,
	KEY_RIGHT:_on_button_right_pressed,
	KEY_A:_on_button_roll_left_pressed,
	KEY_D:_on_button_roll_right_pressed,
	KEY_PAGEUP:_on_button_aps_up_pressed,
	KEY_PAGEDOWN:_on_button_aps_down_pressed,
	KEY_HOME:_on_button_aps_max_pressed,
	KEY_END:_on_button_aps_min_pressed,
	KEY_INSERT:_on_button_fov_up_pressed,
	KEY_DELETE:_on_button_fov_down_pressed,
	KEY_ENTER:_on_button_storey_up_pressed,
	KEY_SPACE:_on_button_fire_pressed,
	KEY_C: _on_button_camera_pressed,
}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var fn = key2fn.get(event.keycode)
		if fn != null:
			fn.call()
	elif event is InputEventMouseButton and event.is_pressed():
		pass

func update_info() -> void:
	var player = char_container.get_child(player_number)
	debuglabel.text = player.debug_str()
	performancelabel.text = """%d FPS (%.2f mspf)
Currently rendering: occlusion culling:%s
%d objects
%dK primitive indices
%d draw calls""" % [
	Engine.get_frames_per_second(),1000.0 / Engine.get_frames_per_second(),
	get_tree().root.use_occlusion_culling,
	RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
	RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) * 0.001,
	RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
	]
	infolabel.text = """storey %d/%d, minimap mode:%s, single storey view:%s
%s
%s
%s
%s""" % [
	cur_storey_index,storey_list.size(),
	minimap_mode, view_floor_ceiling,
	Settings,
	get_cur_storey(),
	player,
	$MovingCameraLight,
	]

func animate_action(ch :MazeCrawl, dur :float) -> void:
	match ch.action_current[0]:
		ActLib.Action.Forward:
			ch.animate_move_by_dur(dur)
		ActLib.Action.TurnLeft, ActLib.Action.TurnRight:
			ch.animate_turn_by_dur(dur)
		ActLib.Action.RollRight,ActLib.Action.RollLeft:
			ch.animate_roll_by_dur(dur)
		ActLib.Action.EnterStorey:
			ch.animate_move_storey_by_dur(dur, cur_storey_index -1, cur_storey_index)
	if ch.serial == player_number:
		if not camera_move:
			cameralight.copy_position_rotation(ch)

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

func set_minimap_mode(v :MiniMapView) -> void:
	match v:
		MiniMapView.Off:
			minimap.hide()
		MiniMapView.Known:
			minimap.show()
			minimap.view_known_map(player_number)
		MiniMapView.Full:
			minimap.show()
			minimap.view_full_map()

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

func _on_button_esc_pressed() -> void:
	get_tree().quit()

func _on_button_help_pressed() -> void:
	$ButtonContainer.visible = not $ButtonContainer.visible

func _on_button_minimap_pressed() -> void:
	minimap_mode = minimapview_next(minimap_mode)
	set_minimap_mode(minimap_mode)
	update_button_text()

func _on_button_floor_ceiling_pressed() -> void:
	view_floor_ceiling = not view_floor_ceiling
	set_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)

func _on_button_walls_pressed() -> void:
	view_walls = wallview_next(view_walls)
	set_wallview_mode(view_walls)
	update_button_text()

func _on_button_pillars_pressed() -> void:
	view_pillars = not view_pillars
	set_pillars_visible(view_pillars)

func _on_button_auto_move_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.ai_walk_type = AILib.next(player.ai_walk_type)
	update_button_text()

func update_button_text() -> void:
	$ButtonContainer/HBoxContainer/ButtonMinimap.text = "2:Minimap %s" % minimapview2str(minimap_mode)
	var player = char_container.get_child(player_number)
	$ButtonContainer/HBoxContainer/ButtonAutoMove.text = "6:Automove %s" % AILib.walk2str(player.ai_walk_type)
	$ButtonContainer/HBoxContainer/ButtonWalls.text = "4:Wall %s" % wallview2str(view_walls)

func _on_button_debug_pressed() -> void:
	debuglabel.visible = !debuglabel.visible

func _on_button_performance_pressed() -> void:
	performancelabel.visible = !performancelabel.visible

func _on_button_info_pressed() -> void:
	infolabel.visible = !infolabel.visible

func _on_button_forward_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(ActLib.Action.Forward, 10)

func _on_button_left_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(ActLib.Action.TurnLeft, 10)

func _on_button_backward_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(ActLib.Action.TurnLeft, 10)
	player.enqueue_action_with_speed(ActLib.Action.TurnLeft, 10)

func _on_button_right_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(ActLib.Action.TurnRight, 10)

func _on_button_roll_right_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(ActLib.Action.RollRight, 10)

func _on_button_roll_left_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(ActLib.Action.RollLeft, 10)

func _on_button_fov_up_pressed() -> void:
	$MovingCameraLight.fov_inc()

func _on_button_fov_down_pressed() -> void:
	$MovingCameraLight.fov_dec()

func _on_button_aps_max_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.action_per_second.set_max()

func _on_button_aps_up_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.action_per_second.set_up()

func _on_button_aps_min_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.action_per_second.set_min()

func _on_button_aps_down_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.action_per_second.set_down()

func _on_button_storey_up_pressed() -> void:
	enter_new_storey()

func _on_button_fire_pressed() -> void:
	pass # Replace with function body.

func _on_button_camera_pressed() -> void:
	camera_move = !camera_move
	if camera_move == false:
		$MovingCameraLight.snap_90()
