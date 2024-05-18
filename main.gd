extends Node3D

var minimap_scene = preload("res://mini_map.tscn")
var storey_scene = preload("res://storey.tscn")
var character_scene = preload("res://character.tscn")

@onready var debuglabel = $LabelContainer/Debug
@onready var performancelabel = $LabelContainer/Performance
@onready var infolabel = $LabelContainer/Info
@onready var cameralight = $MovingCameraLight
@onready var char_container = $CharacterContainer

const VisibleStoreyUp :int = 3
const VisibleStoreyDown :int = 3
const maze_size = Vector2i(16*1,9*1)
const storey_h :float = 3.0
const lane_w :float = 4.0
const wall_thick :float = lane_w *0.05

var minimap :MiniMap
var storey_list :Array[Storey]
var cur_storey_index :int = -1 # +1 on enter_new_storey
var player_number = 0
var vp_size :Vector2
var minimap_mode :int = 0
var view_floor_ceiling :bool = false

func _ready() -> void:
	var msh = maze_size*lane_w +Vector2(wall_thick, wall_thick)

	var mat_keys = Texmat.floor_mat_dict.keys()
	mat_keys.shuffle()
	$Floor.mesh.material = Texmat.floor_mat_dict[mat_keys[0]].duplicate()
	$Floor.mesh.size = msh
	$Floor.position = Vector3(msh.x/2, 0, msh.y/2)
	$Floor.mesh.material.uv1_scale = Vector3(maze_size.x,(maze_size.x+maze_size.y)/2.0,maze_size.y)

	mat_keys = Texmat.ceiling_mat_dict.keys()
	mat_keys.shuffle()
	$Ceiling.mesh.material = Texmat.ceiling_mat_dict[mat_keys[0]].duplicate()
	$Ceiling.mesh.size = $Floor.mesh.size
	$Ceiling.position = $Floor.position
	$Ceiling.mesh.material.uv1_scale = $Floor.mesh.material.uv1_scale

	for i in maze_size.x*maze_size.y/10:
		var pl = character_scene.instantiate()
		char_container.add_child(pl)
		pl.init(i, lane_w, true)

	for i in VisibleStoreyUp:
		add_new_storey(i,maze_size,storey_h,lane_w,wall_thick)

	$MovingCameraLight.init()
	vp_size = get_viewport().get_visible_rect().size
	var msgrect = Rect2( vp_size.x * 0.3 ,vp_size.y * 0.5 , vp_size.x * 0.4 , vp_size.y * 0.1 )
	$TimedMessage.init(80, msgrect, tr("gd4maze3d 15.0.0"))
	$TimedMessage.show_message("",3)

	get_viewport().size_changed.connect(_on_vpsize_changed)
	enter_new_storey()

func _on_vpsize_changed()->void:
	vp_size = get_viewport().get_visible_rect().size

	var cur_storey = get_cur_storey()
	var map_scale = min( vp_size.x / cur_storey.maze_size.x , vp_size.y / cur_storey.maze_size.y )
	minimap.change_scale(map_scale)

	minimap.position.y = (vp_size.y -minimap.get_height())/2
	minimap.position.x = (vp_size.x - minimap.get_width())/2

	#var bc_size = $ButtonContainer.size
	$ButtonContainer.position = vp_size  - $ButtonContainer.size

func enter_new_storey()->void:
	cur_storey_index +=1
	del_old_storey()
	add_new_storey(storey_list.size(), maze_size,storey_h,lane_w,wall_thick)
	$Floor.position.y = visible_down_index()*storey_h
	$Ceiling.position.y = storey_list.size()*storey_h
	change_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)

	vp_size = get_viewport().get_visible_rect().size
	var cur_storey = get_cur_storey()
	var map_scale = min( vp_size.x / cur_storey.maze_size.x , vp_size.y / cur_storey.maze_size.y )
	if minimap != null:
		minimap.queue_free()
	minimap = minimap_scene.instantiate()
	add_child(minimap)
	minimap.init(cur_storey,map_scale)

	for ch in char_container.get_children():
		ch.action_queue.resize(0)
		ch.enqueue_action(Character.Action.EnterStorey, [cur_storey, ch.serial == player_number])

	set_minimap_mode(minimap_mode)
	_on_vpsize_changed()

func _process(_delta: float) -> void:
	var cur_storey = get_cur_storey()
	move_character(cur_storey)
	update_info()

func move_character(cur_storey :Storey)->void:
	for ch in char_container.get_children():
		var ani_dur = ch.get_animation_progress()
		if ch.is_action_ended(ani_dur): # true on act end
			ch.end_action()
			if ch.serial == player_number  : # player
				$MovingCameraLight.snap_90()
				if cur_storey.is_goal_pos(ch.pos_src):
					enter_new_storey()
					return
				if cur_storey.capsule_pos_dict.has(ch.pos_src) : # capsule encounter
					ch.enqueue_action(Character.Action.RollRight)
					cur_storey.pos_dict_remove_at(cur_storey.capsule_pos_dict,ch.pos_src)
				if cur_storey.donut_pos_dict.has(ch.pos_src) : # donut encounter
					ch.enqueue_action(Character.Action.RollLeft)
					cur_storey.pos_dict_remove_at(cur_storey.donut_pos_dict,ch.pos_src)
				minimap.move_player(ch.pos_src.x, ch.pos_src.y)
		ch.ai_action()
		if ch.start_new_action(): # new act start
			ani_dur = 0
			if ch.serial == player_number and ch.action_current[0] != Character.Action.EnterStorey: # player
				minimap.update_walls_by_pos(ch.pos_src.x,ch.pos_src.y)
		if ch.action_current[0] != Character.Action.None :
			animate_action(ch, ani_dur)

var key2fn = {
	KEY_ESCAPE:_on_button_esc_pressed,
	KEY_1:_on_button_help_pressed,
	KEY_2:_on_button_minimap_pressed,
	KEY_3:_on_button_floor_ceiling_pressed,
	KEY_4:_on_button_auto_move_pressed,
	KEY_5:_on_button_debug_pressed,
	KEY_6:_on_button_performance_pressed,
	KEY_7:_on_button_info_pressed,
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
}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var fn = key2fn.get(event.keycode)
		if fn != null:
			fn.call()
	elif event is InputEventMouseButton and event.is_pressed():
		pass

func update_info()->void:
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
storey %s
%s
%s""" % [
	cur_storey_index,storey_list.size(),
	minimap_mode, view_floor_ceiling,
	get_cur_storey().info_str(),
	player.info_str(),
	$MovingCameraLight.info_str(),
	]

func animate_action(ch :Character, dur :float)->void:
	match ch.action_current[0]:
		Character.Action.Forward:
			ch.animate_move_by_dur(dur)
		Character.Action.TurnLeft, Character.Action.TurnRight:
			ch.animate_turn_by_dur(dur)
		Character.Action.RollRight,Character.Action.RollLeft:
			ch.animate_roll_by_dur(dur)
		Character.Action.EnterStorey:
			ch.animate_move_storey_by_dur(dur, cur_storey_index -1, cur_storey_index)
	if ch.serial == player_number:
		cameralight.copy_position_rotation(ch)

func rand_pos()->Vector2i:
	return Vector2i(randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1) )

func get_cur_storey()->Storey:
	return storey_list[cur_storey_index]

func add_new_storey(stnum :int, msize :Vector2i, h :float, lw :float, wt :float)->void:
	var gp = rand_pos()
	var stp = rand_pos()
	if stnum > 0 :
		stp = storey_list[-1].goal_pos
	var st = storey_scene.instantiate()
	st.init(stnum, msize, h, lw, wt, stp, gp)
	st.position.y = storey_h * stnum
	storey_list.append(st)
	add_child(st)

func del_old_storey()->void:
	if visible_down_index()-1 >=0 :
		var todel = storey_list[visible_down_index()-1]
		storey_list[visible_down_index()-1] = null
		remove_child(todel)
		todel.queue_free()

func visible_down_index()->int:
	var rtn = cur_storey_index - VisibleStoreyDown
	if rtn < 0:
		return 0
	return rtn

func set_minimap_mode(v :int)->void:
	minimap_mode = v%3
	match minimap_mode:
		0:
			minimap.hide()
		1:
			minimap.show()
			minimap.view_known_map()
		2:
			minimap.show()
			minimap.view_full_map()

func change_floor_ceiling_visible(f :bool,c :bool)->void:
	var st = visible_down_index()
	for i in range(st,storey_list.size()):
		storey_list[i].view_floor_ceiling(f,c)
	storey_list[st].view_floor_ceiling(false,c)
	storey_list[-1].view_floor_ceiling(f,false)

func _on_button_esc_pressed() -> void:
	get_tree().quit()

func _on_button_help_pressed() -> void:
	$ButtonContainer.visible = !$ButtonContainer.visible

func _on_button_minimap_pressed() -> void:
	set_minimap_mode(minimap_mode+1)

func _on_button_floor_ceiling_pressed() -> void:
	view_floor_ceiling = !view_floor_ceiling
	change_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)

func _on_button_auto_move_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.auto_move = !player.auto_move

func _on_button_debug_pressed() -> void:
	debuglabel.visible = !debuglabel.visible

func _on_button_performance_pressed() -> void:
	performancelabel.visible = !performancelabel.visible

func _on_button_info_pressed() -> void:
	infolabel.visible = !infolabel.visible

func _on_button_forward_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(Character.Action.Forward, 10)

func _on_button_left_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(Character.Action.TurnLeft, 10)

func _on_button_backward_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(Character.Action.TurnLeft, 10)
	player.enqueue_action_with_speed(Character.Action.TurnLeft, 10)

func _on_button_right_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(Character.Action.TurnRight, 10)

func _on_button_roll_right_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(Character.Action.RollRight, 10)

func _on_button_roll_left_pressed() -> void:
	var player = char_container.get_child(player_number)
	player.enqueue_action_with_speed(Character.Action.RollLeft, 10)

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
