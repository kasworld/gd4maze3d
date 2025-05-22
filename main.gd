extends Node3D

var minimap_scene = preload("res://mini_map.tscn")
var character_scene = preload("res://character.tscn")
var tower_scene = preload("res://tower.tscn")

@onready var debuglabel = $ButtonContainer/LabelContainer/Debug
@onready var performancelabel = $ButtonContainer/LabelContainer/Performance
@onready var infolabel = $ButtonContainer/LabelContainer/Info
@onready var cameralight = $MovingCameraLight
@onready var char_container = $CharacterContainer

var minimap :MiniMap
var player_number := 0
var camera_move := false
var current_tower :Tower
var deco_tower :Tower

func _ready() -> void:
	cameralight.init()
	var vp_size = get_viewport().get_visible_rect().size
	var msgrect = Rect2( vp_size.x * 0.3 ,vp_size.y * 0.5 , vp_size.x * 0.4 , vp_size.y * 0.1 )
	$TimedMessage.init(80, msgrect, tr("gd4maze3d 21.0.0"))
	$TimedMessage.show_message("",3)
	get_viewport().size_changed.connect(_on_vpsize_changed)
	
	add_deco_tower(Vector3(80,0,80))
	add_deco_tower(Vector3(-80,0,80))
	add_deco_tower(Vector3(80,0,-80))
	add_deco_tower(Vector3(-80,0,-80))
	
	current_tower = tower_scene.instantiate().init(TowerSetting.new().make_default())
	add_child(current_tower)
	$DecoOrbit.init(current_tower.tower_setting.TotalDiagonal)
	for i in current_tower.tower_setting.CharacterCount:
		var pl = character_scene.instantiate()
		char_container.add_child(pl)
		pl.init_char(current_tower.tower_setting, [AILib.Walk.RightFirst,AILib.Walk.LeftFirst][i%2], 
			i, current_tower.tower_setting.LaneW, NamedColorList.color_list.pick_random()[0])
	update_button_text()
	enter_new_storey()

func add_deco_tower(p :Vector3) -> void:
	deco_tower = tower_scene.instantiate().init(TowerSetting.new().make_default())
	add_child(deco_tower)
	deco_tower.position = p
	deco_tower.enter_new_storey()
	deco_tower.start_demo()

func _process(delta: float) -> void:
	move_character(current_tower.get_cur_storey())
	update_info()
	if camera_move:
		move_camera(delta)

func _on_vpsize_changed() -> void:
	minimap.update_size()

func enter_new_storey() -> void:
	if minimap != null:
		minimap.queue_free()
	current_tower.enter_new_storey()

	minimap = minimap_scene.instantiate()
	add_child(minimap)
	minimap.init(current_tower.get_cur_storey())

	for ch in char_container.get_children():
		ch.action_queue.resize(0)
		var stpos = current_tower.tower_setting.rand_pos_2i()
		if ch.serial == player_number:
			stpos = current_tower.get_cur_storey().start_pos
			minimap.add_character(ch,stpos, 8)
		else:
			minimap.add_character(ch,stpos, 0)
		ch.enqueue_action(ActLib.Action.EnterStorey, [current_tower.get_cur_storey(), stpos])

	$DecoOrbit.position = current_tower.calc_center()
	minimap.set_minimap_mode(player_number)
	update_button_text()
	_on_vpsize_changed()

func apply_storey_gap_change() -> void:
	current_tower.apply_storey_gap_change()
	for ch in char_container.get_children():
		var y =  current_tower.tower_setting.calc_storey_mid_y_pos(current_tower.get_cur_storey().storey_num)
		ch.position.y = y
		if ch.serial == player_number:
			if not camera_move:
				cameralight.copy_position_rotation(ch)

func move_camera(_delta: float) -> void:
	var t = -Time.get_unix_time_from_system() /2.3
	var r = current_tower.tower_setting.TotalDiagonal *1.0
	cameralight.position = Vector3( sin(t)*r, sin(t*1.3)*current_tower.calc_height() *2, cos(t)*r ) + current_tower.calc_center()
	cameralight.look_at(current_tower.calc_center())

func move_character(cur_storey :Storey) -> void:
	for ch in char_container.get_children():
		var ani_dur = ch.get_animation_progress()
		if ch.is_action_ended(ani_dur): # true on act end
			ch.end_action()
			if ch.serial == player_number  : # player
				cameralight.snap_90()
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
				minimap.update_knonw_walls_by_pos(ch.pos_src.x,ch.pos_src.y)
		if ch.action_current[0] != ActLib.Action.None :
			animate_action(ch, ani_dur)

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
	infolabel.text = """%s\n%s\n%s\n%s""" % [current_tower, minimap, player, $MovingCameraLight ]

func update_button_text() -> void:
	$ButtonContainer/HBoxContainer/ButtonMinimap.text = "2:%s" % minimap
	var player = char_container.get_child(player_number)
	$ButtonContainer/HBoxContainer/ButtonAutoMove.text = "6:Automove %s" % AILib.walk2str(player.ai_walk_type)
	$ButtonContainer/HBoxContainer/ButtonWalls.text = "4:Wall %s" % Tower.wallview2str(current_tower.view_walls)

func animate_action(ch :MazeCrawl, dur :float) -> void:
	match ch.action_current[0]:
		ActLib.Action.Forward:
			ch.animate_move_by_dur(dur)
		ActLib.Action.TurnLeft, ActLib.Action.TurnRight:
			ch.animate_turn_by_dur(dur)
		ActLib.Action.RollRight,ActLib.Action.RollLeft:
			ch.animate_roll_by_dur(dur)
		ActLib.Action.EnterStorey:
			ch.animate_move_storey_by_dur(dur, current_tower.cur_storey_index -1, current_tower.cur_storey_index)
	if ch.serial == player_number:
		if not camera_move:
			cameralight.copy_position_rotation(ch)

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
	KEY_O: _on_button_storey_gap_pressed,
}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var fn = key2fn.get(event.keycode)
		if fn != null:
			fn.call()
	elif event is InputEventMouseButton and event.is_pressed():
		pass

func _on_button_esc_pressed() -> void:
	get_tree().quit()

func _on_button_help_pressed() -> void:
	$ButtonContainer.visible = not $ButtonContainer.visible

func _on_button_minimap_pressed() -> void:
	minimap.mode_next(player_number)
	update_button_text()

func _on_button_walls_pressed() -> void:
	current_tower.view_wall_next()
	update_button_text()

func _on_button_floor_ceiling_pressed() -> void:
	current_tower.toggle_visible_floor_ceiling()

func _on_button_pillars_pressed() -> void:
	current_tower.toggle_visible_pillars()
	
func _on_button_storey_gap_pressed() -> void:
	current_tower.start_storey_gap_animation()

func _on_button_auto_move_pressed() -> void:
	char_container.get_child(player_number).set_next_walk_type()
	update_button_text()

func _on_button_debug_pressed() -> void:
	debuglabel.visible = !debuglabel.visible

func _on_button_performance_pressed() -> void:
	performancelabel.visible = !performancelabel.visible

func _on_button_info_pressed() -> void:
	infolabel.visible = !infolabel.visible

func _on_button_forward_pressed() -> void:
	char_container.get_child(player_number).enqueue_action_with_speed(ActLib.Action.Forward, 10)

func _on_button_left_pressed() -> void:
	char_container.get_child(player_number).enqueue_action_with_speed(ActLib.Action.TurnLeft, 10)

func _on_button_backward_pressed() -> void:
	char_container.get_child(player_number).enqueue_action_with_speed(ActLib.Action.TurnLeft, 10).enqueue_action_with_speed(ActLib.Action.TurnLeft, 10)

func _on_button_right_pressed() -> void:
	char_container.get_child(player_number).enqueue_action_with_speed(ActLib.Action.TurnRight, 10)

func _on_button_roll_right_pressed() -> void:
	char_container.get_child(player_number).enqueue_action_with_speed(ActLib.Action.RollRight, 10)

func _on_button_roll_left_pressed() -> void:
	char_container.get_child(player_number).enqueue_action_with_speed(ActLib.Action.RollLeft, 10)

func _on_button_fov_up_pressed() -> void:
	cameralight.fov_inc()

func _on_button_fov_down_pressed() -> void:
	cameralight.fov_dec()

func _on_button_aps_max_pressed() -> void:
	char_container.get_child(player_number).action_per_second.set_max()

func _on_button_aps_up_pressed() -> void:
	char_container.get_child(player_number).action_per_second.set_up()

func _on_button_aps_min_pressed() -> void:
	char_container.get_child(player_number).action_per_second.set_min()

func _on_button_aps_down_pressed() -> void:
	char_container.get_child(player_number).action_per_second.set_down()

func _on_button_storey_up_pressed() -> void:
	enter_new_storey()

func _on_button_fire_pressed() -> void:
	pass # Replace with function body.

func _on_button_camera_pressed() -> void:
	camera_move = !camera_move
	if camera_move == false:
		cameralight.snap_90()
