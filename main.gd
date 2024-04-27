extends Node3D

var minimap_scene = preload("res://mini_map.tscn")
var storey_scene = preload("res://storey.tscn")
var character_scene = preload("res://character.tscn")

@onready var helplabel = $LabelContainer/Help
@onready var debuglabel = $LabelContainer/Debug
@onready var performancelabel = $LabelContainer/Performance
@onready var infolabel = $LabelContainer/Info
@onready var cameralight = $MovingCameraLight

const CharacterCount = 10
const VisibleStoreyUp :int = 3
const VisibleStoreyDown :int = 3
var maze_size = Vector2i(16*1,9*1)
var storey_h :float = 3.0
var lane_w :float = 4.0
var wall_thick :float = lane_w *0.05
var minimap :MiniMap
var storey_list :Array[Storey]
var cur_storey_index :int = -1 # +1 on enter_new_storey
var character_list :Array[Character]
var player_number = 0
var minimap_mode :int = 1
var vp_size :Vector2
var view_floor_ceiling :bool = true

func _ready() -> void:
	var meshx = maze_size.x*lane_w +wall_thick
	var meshy = maze_size.y*lane_w +wall_thick

	var mat_keys = Texmat.floor_mat_dict.keys()
	mat_keys.shuffle()
	$Floor.mesh.size = Vector2(meshx, meshy)
	$Floor.position = Vector3(meshx/2, 0, meshy/2)
	$Floor.mesh.material = Texmat.floor_mat_dict[mat_keys[0]].duplicate()
	$Floor.mesh.material.uv1_scale = Vector3(maze_size.x,(maze_size.x+maze_size.y)/2.0,maze_size.y)

	mat_keys = Texmat.ceiling_mat_dict.keys()
	mat_keys.shuffle()
	$Ceiling.mesh.size = Vector2(meshx, meshy)
	$Ceiling.position = Vector3(meshx/2, storey_h, meshy/2)
	$Ceiling.mesh.material = Texmat.ceiling_mat_dict[mat_keys[1]].duplicate()
	$Ceiling.mesh.material.uv1_scale = $Floor.mesh.material.uv1_scale

	for i in CharacterCount:
		var pl = character_scene.instantiate()
		character_list.append(pl)
		add_child(pl)
		pl.init(i, lane_w, true)

	for i in VisibleStoreyUp:
		add_new_storey(i,maze_size,storey_h,lane_w,wall_thick)

	get_viewport().size_changed.connect(_on_vpsize_changed)
	enter_new_storey()

func _on_vpsize_changed()->void:
	vp_size = get_viewport().get_visible_rect().size

	var cur_storey = get_cur_storey()
	var map_scale = min( vp_size.x / cur_storey.maze_size.x , vp_size.y / cur_storey.maze_size.y )
	minimap.change_scale(map_scale)

	minimap.position.y = (vp_size.y -minimap.get_height())/2
	minimap.position.x = (vp_size.x - minimap.get_width())/2

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

	for pl in character_list:
		pl.enter_storey(cur_storey, pl.serial == player_number)
	set_minimap_mode(minimap_mode)
	_on_vpsize_changed()

func _process(_delta: float) -> void:
	var cur_storey = get_cur_storey()
	move_character(cur_storey)
	update_info()

func move_character(cur_storey :Storey)->void:
	for pl in character_list:
		var ani_dur = pl.get_animation_progress()
		if pl.is_action_ended(ani_dur): # true on act end
			pl.end_action()
			if pl.serial == player_number  : # player
				if cur_storey.is_goal_pos(pl.pos_src):
					enter_new_storey()
					return
				if cur_storey.capsule_pos_dict.has(pl.pos_src) : # capsule encounter
					pl.enqueue_action(Character.Action.RollRight)
					cur_storey.pos_dict_remove_at(cur_storey.capsule_pos_dict,pl.pos_src)
				if cur_storey.donut_pos_dict.has(pl.pos_src) : # donut encounter
					pl.enqueue_action(Character.Action.RollLeft)
					cur_storey.pos_dict_remove_at(cur_storey.donut_pos_dict,pl.pos_src)
				minimap.move_player(pl.pos_src.x, pl.pos_src.y)
		pl.ai_action()
		if pl.start_new_action(): # new act start
			ani_dur = 0
			if pl.serial == player_number and pl.action_current != Character.Action.EnterStorey: # player
				minimap.update_walls_by_pos(pl.pos_src.x,pl.pos_src.y)
		if pl.action_current != Character.Action.None :
			animate_action(pl, ani_dur)

func _unhandled_input(event: InputEvent) -> void:
	var player = character_list[player_number]
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_1:
				helplabel.visible = !helplabel.visible
			KEY_2:
				set_minimap_mode(minimap_mode+1)
			KEY_3:
				view_floor_ceiling = !view_floor_ceiling
				change_floor_ceiling_visible(view_floor_ceiling,view_floor_ceiling)
			KEY_4:
				player.auto_move = !player.auto_move
			KEY_5:
				debuglabel.visible = !debuglabel.visible
			KEY_6:
				performancelabel.visible = !performancelabel.visible
			KEY_7:
				infolabel.visible = !infolabel.visible
			#KEY_8:
				#get_tree().root.use_occlusion_culling = not get_tree().root.use_occlusion_culling
			KEY_UP:
				player.enqueue_action(Character.Action.Forward)
			KEY_DOWN:
				player.enqueue_action(Character.Action.TurnLeft)
				player.enqueue_action(Character.Action.TurnLeft)
			KEY_LEFT:
				player.enqueue_action(Character.Action.TurnLeft)
			KEY_RIGHT:
				player.enqueue_action(Character.Action.TurnRight)

			KEY_SPACE:
				player.enqueue_action(Character.Action.RollRight)
			KEY_ENTER:
				enter_new_storey()
	elif event is InputEventMouseButton and event.is_pressed():
		pass

func update_info()->void:
	var player = character_list[player_number]
	helplabel.text = """gd4maze3d 14.0.0
Space:RollCamera, Enter:Next storey,
1:Toggle help, 2:Minimap, 3:ViewFloorCeiling, 4:Toggle automove, 5:Toggle debug info, 6:Toggle Perfomance info, 7:info
ArrowKey to move
"""
	debuglabel.text = player.debug_str()
	performancelabel.text = """%d FPS (%.2f mspf)
Currently rendering: occlusion culling:%s
%d objects
%dK primitive indices
%d draw calls
""" % [
	Engine.get_frames_per_second(),1000.0 / Engine.get_frames_per_second(),
	get_tree().root.use_occlusion_culling,
	RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
	RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) * 0.001,
	RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
]
	infolabel.text = """storey %d/%d, minimap mode:%s, single storey view:%s
storey %s
%s
""" % [
		cur_storey_index,storey_list.size(),
		minimap_mode, view_floor_ceiling,
		get_cur_storey().info_str(),
		player.info_str(),
		]

func animate_action(pl :Character, dur :float)->void:
	match pl.action_current:
		Character.Action.Forward:
			pl.animate_move_by_dur(dur)
		Character.Action.TurnLeft, Character.Action.TurnRight:
			pl.animate_turn_by_dur(dur)
		Character.Action.RollRight,Character.Action.RollLeft:
			pl.animate_roll_by_dur(dur)
		Character.Action.EnterStorey:
			pl.animate_move_storey_by_dur(dur, cur_storey_index -1)
	if pl.serial == player_number:
		cameralight.copy_position_rotation(pl)

func rand_pos()->Vector2i:
	return Vector2i(randi_range(0,maze_size.x-1),randi_range(0,maze_size.y-1) )

func get_cur_storey()->Storey:
	return storey_list[cur_storey_index]

# thread unsafe
func add_new_storey(stnum :int, msize :Vector2i, h :float, lw :float, wt :float)->void:
	var st = new_storey(stnum,msize,h,lw,wt)
	if stnum > 0 :
		st.set_start_pos(storey_list[-1].goal_pos)
	st.position.y = storey_h * stnum
	storey_list.append(st)
	add_child(st)

# thread safe
func new_storey(stnum :int, msize :Vector2i, h :float, lw :float, wt :float)->Storey:
	var gp = rand_pos()
	var stp = rand_pos()
	var st = storey_scene.instantiate()
	st.init(stnum, msize, h, lw, wt, stp, gp)
	return st

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
			minimap.show()
			minimap.view_full_map()
		1:
			minimap.show()
			minimap.view_known_map()
		2:
			minimap.hide()

func change_floor_ceiling_visible(f :bool,c :bool)->void:
	var st = visible_down_index()
	for i in range(st,storey_list.size()):
		storey_list[i].view_floor_ceiling(f,c)
	storey_list[st].view_floor_ceiling(false,c)
	storey_list[-1].view_floor_ceiling(f,false)
