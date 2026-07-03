extends Node3D

const PlayerNumber :int = 0
const CharacterCount :int = 2

var player :Crawler
var main_tower :Tower

func on_viewport_size_changed() -> void:
	var rt := get_viewport().get_visible_rect()
	var vp_size := rt.size
	var 짧은길이 :float = min(vp_size.x, vp_size.y)
	var panel_size := Vector2(vp_size.x/2 - 짧은길이/2, vp_size.y)
	$"왼쪽패널".size = panel_size
	$"왼쪽패널".custom_minimum_size = panel_size
	$오른쪽패널.size = panel_size
	$"오른쪽패널".custom_minimum_size = panel_size
	$오른쪽패널.position = Vector2(vp_size.x/2 + 짧은길이/2, 0)
	var msgrect := Rect2( vp_size.x * 0.1 ,vp_size.y * 0.4 , vp_size.x * 0.8 , vp_size.y * 0.25 )
	$TimedMessage.init(vp_size.y*0.05 , msgrect, "%s %s" % [
			ProjectSettings.get_setting("application/config/name"),
			ProjectSettings.get_setting("application/config/version") ] )
	if main_tower:
		update_minimap()
func timed_message_hidden(_s :String) -> void:
	pass

func update_minimap() -> void:
	var rt := get_viewport().get_visible_rect()
	var minimap := main_tower.cur_storey.get_mini_map()
	minimap.update_size(rt.size)
	minimap.position = rt.get_center() - minimap.get_size()/2

func update_camera() -> void:
	var cur_storey_pos := main_tower.cur_storey.position
	var ref_len := main_tower.cur_storey.maze3d.calc_grid.aabb.size.length()
	$AxisArrow3D.set_size(ref_len/3).set_colors()
	var center := cur_storey_pos
	$FixedCameraLight.set_center_pos_far(center, Vector3(0, cur_storey_pos.y, ref_len), ref_len*4)
	$MovingCameraLightHober.set_center_pos_far( center, Vector3(0, cur_storey_pos.y, ref_len), ref_len*4)
	$MovingCameraLightAround.set_center_pos_far( center, Vector3(0, cur_storey_pos.y, ref_len), ref_len*4)


func _ready() -> void:
	on_viewport_size_changed()
	get_viewport().size_changed.connect(on_viewport_size_changed)
	$TimedMessage.panel_hidden.connect(timed_message_hidden)
	$TimedMessage.show_message("",0)

	main_tower = preload("res://tower/tower.tscn").instantiate().init()
	add_child(main_tower)

	for i in CharacterCount:
		add_crawler(i)
	player = $CharacterContainer.get_child(PlayerNumber)
	$MovingCameraLightAround.make_current()

	enter_next_storey(null)

func _process(_delta: float) -> void:
	update_info()
	var t := Time.get_unix_time_from_system() /2.3
	var r := main_tower.tower_size().length()
	var h := main_tower.tower_size().y *2
	var pos_center := main_tower.cur_storey.global_position
	if $MovingCameraLightHober.is_current_camera():
		$MovingCameraLightHober.move_hober_around_z(t, pos_center, r, h )
	elif $MovingCameraLightAround.is_current_camera():
		$MovingCameraLightAround.move_wave_around_y(t, pos_center, r, h )

func enter_next_storey(old_storey :Storey) -> void:
	if player.current_action.get("Action") == ActionQueue.Action.EnterStorey:
		print_debug("already in Action.EnterStorey")
		return
	var chars_tomove :Array
	if old_storey == null:
		chars_tomove = $CharacterContainer.get_children()
	else:
		main_tower.move_to_upper_storey()
		chars_tomove = old_storey.get_char_list()
	main_tower.cur_storey.chars_enter_storey(old_storey, chars_tomove , player.crawler_num)
	for ch in chars_tomove:
		ch.reset_scale()
	update_button_text()
	update_minimap()
	update_camera()

func add_crawler(i :int) -> Crawler:
	var cr :Crawler = preload("res://crawler/crawler.tscn").instantiate()
	$CharacterContainer.add_child(cr)
	cr.init(
		[Crawler.Walk.RightFirst,Crawler.Walk.LeftFirst][i%2],
		i, Storey.CellSize.x, NamedColors.random_color())
	if cr.crawler_num == PlayerNumber:
		cr.crawler_goal_reached.connect(crawler_goal_reached)
	return cr

func crawler_goal_reached(st :Storey, _cr :Crawler) -> void:
	enter_next_storey.call_deferred(st)

var key2fn :Dictionary[Key, Callable]= {
	KEY_ESCAPE:_on_button_esc_pressed,
	KEY_1:_on_button_help_pressed,
	KEY_2:_on_button_minimap_pressed,
	KEY_3:_on_button_floor_ceiling_pressed,
	KEY_4:_on_button_walls_pressed,
	KEY_6:_on_button_walk_type_pressed,
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
	KEY_C: _on_button_camera_pressed,
	KEY_O: _on_button_axis_arrow_pressed,
}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if $FixedCameraLight.is_current_camera():
			var fi = FlyNode3D.Key2Info.get(event.keycode)
			if fi != null:
				FlyNode3D.fly_node3d($FixedCameraLight, fi)

		var fn = key2fn.get(event.keycode)
		if fn != null:
			fn.call()
	elif event is InputEventMouseButton and event.is_pressed():
		pass

func _on_button_esc_pressed() -> void:
	get_tree().quit()

func _on_button_help_pressed() -> void:
	$"오른쪽패널".visible = not $"오른쪽패널".visible

func _on_button_minimap_pressed() -> void:
	main_tower.cur_storey.get_mini_map().mode_next()
	update_button_text()

func _on_button_walls_pressed() -> void:
	main_tower.view_wallpillardoor_next()
	update_button_text()

func _on_button_floor_ceiling_pressed() -> void:
	main_tower.next_visible_floor_ceiling()

func _on_button_axis_arrow_pressed() -> void:
	$AxisArrow3D.visible = not $AxisArrow3D.visible

func _on_button_walk_type_pressed() -> void:
	player.set_next_walk_mode()
	update_button_text()
	player.act_character()

func _on_button_forward_pressed() -> void:
	player.action_queue.enqueue_with_speed(ActionQueue.Action.Forward, 10)
	player.act_character()

func _on_button_left_pressed() -> void:
	player.action_queue.enqueue_with_speed(ActionQueue.Action.TurnLeft, 10)
	player.act_character()

func _on_button_backward_pressed() -> void:
	player.action_queue.enqueue_with_speed(ActionQueue.Action.TurnLeft, 10).enqueue_with_speed(ActionQueue.Action.TurnLeft, 10)
	player.act_character()

func _on_button_right_pressed() -> void:
	player.action_queue.enqueue_with_speed(ActionQueue.Action.TurnRight, 10)
	player.act_character()

func _on_button_roll_right_pressed() -> void:
	player.action_queue.enqueue_with_speed(ActionQueue.Action.RollRight, 10)
	player.act_character()

func _on_button_roll_left_pressed() -> void:
	player.action_queue.enqueue_with_speed(ActionQueue.Action.RollLeft, 10)
	player.act_character()

func _on_button_aps_max_pressed() -> void:
	player.action_queue.action_second.set_max()

func _on_button_aps_up_pressed() -> void:
	player.action_queue.action_second.set_up()

func _on_button_aps_min_pressed() -> void:
	player.action_queue.action_second.set_min()

func _on_button_aps_down_pressed() -> void:
	player.action_queue.action_second.set_down()

func _on_button_storey_up_pressed() -> void:
	enter_next_storey(main_tower.cur_storey)

func _on_button_camera_pressed() -> void:
	MovingCameraLight.NextCamera()

func _on_button_fov_up_pressed() -> void:
	MovingCameraLight.GetCurrentCamera().fov_inc()

func _on_button_fov_down_pressed() -> void:
	MovingCameraLight.GetCurrentCamera().fov_dec()

func _on_button_debug_pressed() -> void:
	$"오른쪽패널"/Debug.visible = !$"오른쪽패널"/Debug.visible

func _on_button_performance_pressed() -> void:
	$"오른쪽패널"/Performance.visible = !$"오른쪽패널"/Performance.visible

func _on_button_info_pressed() -> void:
	$"오른쪽패널"/Info.visible = !$"오른쪽패널"/Info.visible

func update_info() -> void:
	if $"오른쪽패널"/Debug.visible:
		$"오른쪽패널"/Debug.text = player.debug_str()
	if $"오른쪽패널"/Performance.visible:
		$"오른쪽패널"/Performance.text = """%d FPS (%.2f mspf)
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
	if $"오른쪽패널"/Info.visible:
		$"오른쪽패널"/Info.text = """%s\n%s\n%s\n%s""" % [
			main_tower,
			main_tower.cur_storey.get_mini_map(),
			player,
			MovingCameraLight.GetCurrentCamera() ]

func update_button_text() -> void:
	$"왼쪽패널"/ButtonMinimap.text = "2:%s" % main_tower.cur_storey.get_mini_map()
	$"왼쪽패널"/ButtonWalkType.text = "6:walk mode %s" % Crawler.walk2str(player.walk_mode)
	$"왼쪽패널"/ButtonWalls.text = "4:Wall %s" % Maze3D.wallpillardoorview2str(main_tower.view_wallpillardoor)
