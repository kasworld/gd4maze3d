extends Node3D

var tower_scene = preload("res://tower.tscn")

@onready var debuglabel = $ButtonContainer/LabelContainer/Debug
@onready var performancelabel = $ButtonContainer/LabelContainer/Performance
@onready var infolabel = $ButtonContainer/LabelContainer/Info
@onready var cameralight = $MovingCameraLight
@onready var char_container = $CharacterContainer

var player :Crawler
var camera_move := false
var current_tower :Tower
var default_storey_setting :StoreySetting

func _ready() -> void:
	cameralight.init()
	var vp_size = get_viewport().get_visible_rect().size
	var msgrect = Rect2( vp_size.x * 0.3 ,vp_size.y * 0.5 , vp_size.x * 0.4 , vp_size.y * 0.1 )
	$TimedMessage.init(80, msgrect, tr("gd4maze3d 23.0.0"))
	$TimedMessage.show_message("",3)
	get_viewport().size_changed.connect(_on_vpsize_changed)
	
	default_storey_setting = StoreySetting.new().make_default()
	current_tower = tower_scene.instantiate().init(
		TowerSetting.new().make_default(),default_storey_setting,
		)
	add_child(current_tower)
	current_tower.storey_gap_changed.connect(storey_gap_changed)
	
	for i in current_tower.tower_setting.CharacterCount:
		var pl = preload("res://crawler/crawler.tscn").instantiate()
		char_container.add_child(pl)
		pl.init(
			[Crawler.Walk.RightFirst,Crawler.Walk.LeftFirst][i%2], 
			i, default_storey_setting.LaneW, NamedColorList.color_list.pick_random()[0])
	player = char_container.get_child(0)

	var orbitr := default_storey_setting.CalcDiagonalLength() * 2
	var n = 3
	for i in n:
		var rd = 2*PI/n *i
		add_deco_tower(Vector3(sin(rd)*orbitr,0,cos(rd)*orbitr))
	if n != 0:
		orbitr *= 2
	$DecoOrbit.init(orbitr)

	enter_storey(null)
	update_button_text()

func add_deco_tower(p :Vector3) -> void:
	var deco_tower = tower_scene.instantiate().init(
		TowerSetting.new().make_deco(),StoreySetting.new().make_deco(),
		)
	add_child(deco_tower)
	deco_tower.position = p
	deco_tower.start_demo_random()

func _process(delta: float) -> void:
	act_character(current_tower.cur_storey)
	update_info()
	if camera_move:
		move_camera(delta)

func _on_vpsize_changed() -> void:
	current_tower.cur_storey.get_mini_map().update_size()

func storey_gap_changed(tw :Tower) -> void:
	for ch in char_container.get_children():
		ch.position.y = tw.cur_storey.get_center_pos().y
		if ch == player:
			if not camera_move:
				cameralight.copy_position_rotation(ch)

func move_camera(_delta: float) -> void:
	var t = -Time.get_unix_time_from_system() /2.3
	var r = default_storey_setting.CalcDiagonalLength() *1.0
	var to_pos := current_tower.cur_storey.get_center_pos()
	cameralight.position = Vector3( sin(t)*r, sin(t*1.3)*current_tower.calc_height() *2, cos(t)*r ) + to_pos
	cameralight.look_at(to_pos)

func enter_next_storey() -> void:
	if player.current_action.get("Action") == Crawler.Action.EnterStorey:
		print_debug("already in Action.EnterStorey")
		return
	var old_storey = current_tower.enter_next_storey()
	enter_storey(old_storey)

func enter_storey(old_storey :Storey) -> void:
	$DecoOrbit.position = current_tower.cur_storey.get_center_pos()
	current_tower.cur_storey.chars_enter_storey(old_storey, char_container.get_children(),player.serial)
	update_button_text()

func act_character(cur_storey :Storey) -> void:
	for ch in char_container.get_children():
		if ch.is_current_action_ended(): # true on act end
			ch.end_action()
			if ch == player  : # player
				cameralight.snap_90()
				if cur_storey.is_goal_pos(ch.pos_src):
					enter_next_storey()
					return
				cur_storey.놓인것들줍기(ch)
			cur_storey.get_mini_map().update_char_pos(ch)
		ch.try_auto_walk()
		if ch.start_new_action(): # new act start
			pass
		if not ch.current_action.is_empty():
			ch.animate_action()
			if ch == player and not camera_move:
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
	current_tower.cur_storey.get_mini_map().mode_next()
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
	player.set_next_walk_type()
	update_button_text()

func _on_button_debug_pressed() -> void:
	debuglabel.visible = !debuglabel.visible

func _on_button_performance_pressed() -> void:
	performancelabel.visible = !performancelabel.visible

func _on_button_info_pressed() -> void:
	infolabel.visible = !infolabel.visible

func _on_button_forward_pressed() -> void:
	player.enqueue_action_with_speed(Crawler.Action.Forward, 10)

func _on_button_left_pressed() -> void:
	player.enqueue_action_with_speed(Crawler.Action.TurnLeft, 10)

func _on_button_backward_pressed() -> void:
	player.enqueue_action_with_speed(Crawler.Action.TurnLeft, 10).enqueue_action_with_speed(Crawler.Action.TurnLeft, 10)

func _on_button_right_pressed() -> void:
	player.enqueue_action_with_speed(Crawler.Action.TurnRight, 10)

func _on_button_roll_right_pressed() -> void:
	player.enqueue_action_with_speed(Crawler.Action.RollRight, 10)

func _on_button_roll_left_pressed() -> void:
	player.enqueue_action_with_speed(Crawler.Action.RollLeft, 10)

func _on_button_fov_up_pressed() -> void:
	cameralight.fov_inc()

func _on_button_fov_down_pressed() -> void:
	cameralight.fov_dec()

func _on_button_aps_max_pressed() -> void:
	player.action_per_second.set_max()

func _on_button_aps_up_pressed() -> void:
	player.action_per_second.set_up()

func _on_button_aps_min_pressed() -> void:
	player.action_per_second.set_min()

func _on_button_aps_down_pressed() -> void:
	player.action_per_second.set_down()

func _on_button_storey_up_pressed() -> void:
	enter_next_storey()
	
func _on_button_fire_pressed() -> void:
	pass # Replace with function body.

func _on_button_camera_pressed() -> void:
	camera_move = !camera_move
	if camera_move == false:
		cameralight.snap_90()

func update_info() -> void:
	if debuglabel.visible:
		debuglabel.text = player.debug_str()
	if performancelabel.visible:
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
	if infolabel.visible:
		infolabel.text = """%s\n%s\n%s\n%s""" % [current_tower, current_tower.cur_storey.get_mini_map(), player, $MovingCameraLight ]

func update_button_text() -> void:
	$ButtonContainer/HBoxContainer/ButtonMinimap.text = "2:%s" % current_tower.cur_storey.get_mini_map()
	$ButtonContainer/HBoxContainer/ButtonAutoMove.text = "6:Automove %s" % Crawler.walk2str(player.auto_walk_type)
	$ButtonContainer/HBoxContainer/ButtonWalls.text = "4:Wall %s" % Storey.wallview2str(current_tower.view_walls)
